import { RiderModel } from '../models/rider.model';
import { OrderModel } from '../models/order.model';
import { BusinessModel } from '../models/business.model';
import { AppError } from '../utils/AppError';
import { emitToOrder, emitToRider, emitToBusiness } from '../utils/socket';
import { OrderStatus } from '../types';

// A rider can only work on orders that are still in progress.
function assertInProgress(order: { status: OrderStatus }) {
  if (order.status === 'delivered' || order.status === 'cancelled') {
    throw new AppError(`Order is already ${order.status}`, 400);
  }
}

export const DeliveryService = {
  // Called automatically when a delivery order starts cooking, and can also be triggered manually by a dispatcher.
  async autoAssignRider(orderId: number) {
    const order = await OrderModel.findById(orderId);
    if (!order) throw new AppError('Order not found', 404);
    if (order.order_type !== 'delivery') return null;
    if (order.rider_id) return order; // already assigned

    const business = await BusinessModel.findById(order.business_id);
    if (!business?.latitude || !business?.longitude) return null;

    const candidates = await RiderModel.findNearestAvailable(Number(business.latitude), Number(business.longitude), 5);
    if (!candidates.length) return null; // no rider available yet - dispatcher can retry / notify pool

    const chosen = candidates[0];
    await OrderModel.assignRider(orderId, chosen.id);
    await RiderModel.setStatus(chosen.id, 'busy');

    emitToRider(chosen.id, 'delivery:assigned', { orderId, businessId: order.business_id });
    emitToOrder(orderId, 'order:status', { orderId, status: order.status, riderId: chosen.id });

    return OrderModel.findById(orderId);
  },

  async manualAssign(orderId: number, riderId: number) {
    const order = await OrderModel.findById(orderId);
    if (!order) throw new AppError('Order not found', 404);
    assertInProgress(order);
    if (order.order_type !== 'delivery') throw new AppError('Only delivery orders need a rider', 400);
    if (order.rider_id) throw new AppError('This order already has a rider', 400);

    const rider = await RiderModel.findById(riderId);
    if (!rider) throw new AppError('Rider not found', 404);
    if (rider.status !== 'available') throw new AppError('Rider is not available', 400);

    await OrderModel.assignRider(orderId, riderId);
    await RiderModel.setStatus(riderId, 'busy');
    emitToRider(riderId, 'delivery:assigned', { orderId });
    emitToOrder(orderId, 'order:status', { orderId, status: order.status, riderId });
    return OrderModel.findById(orderId);
  },

  // Rider picked the food up -> the order is now on the way.
  async markPickedUp(orderId: number, riderId: number) {
    const order = await OrderModel.findById(orderId);
    if (!order || order.rider_id !== riderId) throw new AppError('Order not assigned to this rider', 403);
    assertInProgress(order);
    if (order.status !== 'on_the_way') {
      await OrderModel.updateStatus(orderId, 'on_the_way', 'Rider picked up the order');
      emitToOrder(orderId, 'order:status', { orderId, status: 'on_the_way' });
      emitToBusiness(order.business_id, 'order:status', { orderId, status: 'on_the_way' });
    }
    return OrderModel.findById(orderId);
  },

  // Kept for older rider apps - same result as markPickedUp.
  async markOnTheWay(orderId: number, riderId: number) {
    return DeliveryService.markPickedUp(orderId, riderId);
  },

  async markDelivered(orderId: number, riderId: number) {
    const order = await OrderModel.findById(orderId);
    if (!order || order.rider_id !== riderId) throw new AppError('Order not assigned to this rider', 403);
    if (order.status === 'delivered') return order; // already done - don't count it twice
    assertInProgress(order);
    await OrderModel.updateStatus(orderId, 'delivered', 'Order delivered to customer');
    await RiderModel.setStatus(riderId, 'available');
    await RiderModel.incrementDeliveries(riderId);
    if (order.payment_method === 'cod') {
      await OrderModel.setPaymentStatus(orderId, 'paid');
    }
    emitToOrder(orderId, 'order:status', { orderId, status: 'delivered' });
    emitToBusiness(order.business_id, 'order:status', { orderId, status: 'delivered' });
    return OrderModel.findById(orderId);
  },

  async pingLocation(riderId: number, lat: number, lng: number, orderId?: number) {
    await RiderModel.updateLocation(riderId, lat, lng, orderId);
    if (orderId) {
      emitToOrder(orderId, 'rider:location', { riderId, lat, lng, at: new Date().toISOString() });
    }
  },

  async goOnline(riderId: number) {
    await RiderModel.setStatus(riderId, 'available');
  },

  async goOffline(riderId: number) {
    await RiderModel.setStatus(riderId, 'offline');
  },

  async activeDeliveries(riderId: number) {
    return OrderModel.listActiveForRider(riderId);
  },

  async unassignedReadyOrders(businessId?: number) {
    return OrderModel.listUnassignedReady(businessId);
  },

  async allOrders(businessId?: number, status?: OrderStatus) {
    return OrderModel.listAllDeliveryOrders(businessId, status);
  },
};
