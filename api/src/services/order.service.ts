import { v4 as uuidv4 } from 'uuid';
import { OrderModel, OrderItemInput } from '../models/order.model';
import { MenuModel } from '../models/menu.model';
import { BusinessModel } from '../models/business.model';
import { AddressModel } from '../models/address.model';
import { AppError } from '../utils/AppError';
import { orderNumber } from '../utils/response.util';
import { OrderStatus, PaymentMethod } from '../types';
import { emitToBusiness, emitToOrder } from '../utils/socket';
import { DeliveryService } from './delivery.service';
import { RiderModel } from '../models/rider.model';

const TAX_RATE = 0.13; // Nepal VAT 13% - adjust per business/locale as needed

// Order lifecycle: placed -> accepted -> cooking -> on_the_way -> delivered, and cancelled if there is a problem.
// New orders start as "placed" (waiting for kitchen). Kitchen moves placed -> accepted (or straight to cooking).
// Pickup / dine-in orders skip on_the_way: cooking -> delivered.
const ALLOWED_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  placed: ['accepted', 'cooking', 'cancelled'],
  accepted: ['cooking', 'cancelled'],
  cooking: ['on_the_way', 'delivered', 'cancelled'],
  on_the_way: ['delivered', 'cancelled'],
  delivered: [],
  cancelled: [],
};

// A rider marked "busy" goes back to "available" once they have no more active orders.
async function releaseRider(riderId: number) {
  const rider = await RiderModel.findById(riderId);
  if (!rider || rider.status !== 'busy') return;
  const active = await OrderModel.listActiveForRider(riderId);
  if (!active.length) await RiderModel.setStatus(riderId, 'available');
}

export const OrderService = {
  async placeOrder(userId: number, data: {
    business_id: number;
    order_type: 'delivery' | 'pickup' | 'dine_in';
    items: { menu_item_id: number; quantity: number; addons?: { name: string; price: number }[]; notes?: string }[];
    payment_method: PaymentMethod;
    delivery_address_id?: number;
    table_id?: number;
    special_instructions?: string;
  }) {
    const business = await BusinessModel.findById(data.business_id);
    if (!business) throw new AppError('Business not found', 404);
    if (!business.has_food_ordering) throw new AppError('This business does not accept food orders', 400);
    if (!business.is_open) throw new AppError('This business is currently closed', 400);
    if (!data.items?.length) throw new AppError('Order must contain at least one item', 422);

    let subtotal = 0;
    const orderItems: OrderItemInput[] = [];

    for (const line of data.items) {
      const menuItem = await MenuModel.findById(line.menu_item_id);
      if (!menuItem || menuItem.business_id !== data.business_id) {
        throw new AppError(`Menu item ${line.menu_item_id} not found for this business`, 400);
      }
      if (!menuItem.is_available) throw new AppError(`"${menuItem.name}" is currently unavailable`, 400);

      const unitPrice = menuItem.discount_percent
        ? Number((menuItem.price * (1 - menuItem.discount_percent / 100)).toFixed(2))
        : menuItem.price;
      const addonsTotal = (line.addons || []).reduce((s, a) => s + a.price, 0);
      const lineSubtotal = (unitPrice + addonsTotal) * line.quantity;
      subtotal += lineSubtotal;

      orderItems.push({
        menu_item_id: menuItem.id,
        item_name: menuItem.name,
        unit_price: unitPrice,
        quantity: line.quantity,
        addons_json: line.addons || null,
        item_subtotal: Number(lineSubtotal.toFixed(2)),
        notes: line.notes,
      });
    }

    if (business.min_order_amount && subtotal < business.min_order_amount) {
      throw new AppError(`Minimum order amount is ${business.min_order_amount}`, 400);
    }

    let deliveryFee = 0;
    let deliveryAddress = null;
    if (data.order_type === 'delivery') {
      if (!data.delivery_address_id) throw new AppError('Delivery address is required', 422);
      deliveryAddress = await AddressModel.findById(data.delivery_address_id);
      if (!deliveryAddress || deliveryAddress.user_id !== userId) throw new AppError('Invalid delivery address', 422);
      deliveryFee = Number(business.base_delivery_fee || 0);
    }

    if (data.order_type === 'dine_in' && !data.table_id) {
      throw new AppError('table_id is required for dine-in orders', 422);
    }

    const taxAmount = Number((subtotal * TAX_RATE).toFixed(2));
    const totalAmount = Number((subtotal + deliveryFee + taxAmount).toFixed(2));

    const orderId = await OrderModel.createWithItems({
      uuid: uuidv4(),
      order_number: orderNumber(),
      business_id: data.business_id,
      user_id: userId,
      order_type: data.order_type,
      subtotal: Number(subtotal.toFixed(2)),
      delivery_fee: deliveryFee,
      tax_amount: taxAmount,
      discount_amount: 0,
      total_amount: totalAmount,
      payment_method: data.payment_method,
      delivery_address_id: data.delivery_address_id,
      delivery_latitude: deliveryAddress?.latitude,
      delivery_longitude: deliveryAddress?.longitude,
      table_id: data.table_id,
      special_instructions: data.special_instructions,
    }, orderItems);

    const order = await OrderModel.findById(orderId);
    emitToBusiness(data.business_id, 'order:new', order);
    return { order, items: orderItems };
  },

  async getFullOrder(orderId: number) {
    const order = await OrderModel.findById(orderId);
    if (!order) throw new AppError('Order not found', 404);
    const [items, statusLog] = await Promise.all([
      OrderModel.getItems(orderId),
      OrderModel.getStatusLog(orderId),
    ]);
    return { order, items, statusLog };
  },

  async myOrders(userId: number, limit?: number, offset?: number) {
    return OrderModel.listByUser(userId, limit, offset);
  },

  async businessOrders(businessId: number, status?: OrderStatus) {
    return OrderModel.listByBusiness(businessId, status);
  },

  // ---- super_admin ----------------------------------------------------------------
  async adminList(filters: Parameters<typeof OrderModel.listAdmin>[0]) {
    return OrderModel.listAdmin(filters);
  },

  async adminGetDetail(orderId: number) {
    const order = await OrderModel.findAdminDetail(orderId);
    if (!order) throw new AppError('Order not found', 404);
    const [items, statusLog, payments] = await Promise.all([
      OrderModel.getItems(orderId),
      OrderModel.getStatusLog(orderId),
      OrderModel.getPayments(orderId),
    ]);
    return { order, items, statusLog, payments };
  },

  // Finished orders (delivered / cancelled) can be deleted directly.
  // Orders still in progress need force = true so a live order isn't wiped by accident.
  async adminDelete(orderId: number, force = false) {
    const order = await OrderModel.findById(orderId);
    if (!order) throw new AppError('Order not found', 404);

    const finished = ['delivered', 'cancelled'].includes(order.status);
    if (!finished && !force) {
      throw new AppError(
        `Order is still "${order.status}". Cancel it first, or delete anyway with ?force=true`,
        409
      );
    }

    await OrderModel.remove(orderId);

    // If a rider was tied up on this order, free them when they have nothing else active.
    if (order.rider_id) await releaseRider(order.rider_id);

    emitToOrder(orderId, 'order:deleted', { orderId });
    emitToBusiness(order.business_id, 'order:deleted', { orderId });
  },

  async transition(orderId: number, nextStatus: OrderStatus, note?: string) {
    const order = await OrderModel.findById(orderId);
    if (!order) throw new AppError('Order not found', 404);

    const allowed = ALLOWED_TRANSITIONS[order.status] || [];
    if (!allowed.includes(nextStatus)) {
      throw new AppError(`Cannot move order from "${order.status}" to "${nextStatus}"`, 400);
    }
    if (nextStatus === 'on_the_way' && order.order_type !== 'delivery') {
      throw new AppError('Only delivery orders can be "on the way" - mark pickup / dine-in orders as delivered', 400);
    }

    // Cancelling has its own flow (stores the reason, frees the rider)
    if (nextStatus === 'cancelled') {
      await OrderService.cancel(orderId, note || 'Cancelled');
      return OrderModel.findById(orderId);
    }

    const defaultNotes: Partial<Record<OrderStatus, string>> = {
      accepted: 'Accepted by kitchen',
      cooking: 'Kitchen started preparing',
      on_the_way: 'Order is on the way',
      delivered: 'Order delivered',
    };
    const statusNote = note || defaultNotes[nextStatus] || null;

    await OrderModel.updateStatus(orderId, nextStatus, statusNote || undefined);
    emitToOrder(orderId, 'order:status', { orderId, status: nextStatus, note: statusNote });
    emitToBusiness(order.business_id, 'order:status', { orderId, status: nextStatus });

    // As soon as a delivery order starts cooking, try to auto-assign the nearest rider.
    if (nextStatus === 'cooking' && order.order_type === 'delivery') {
      await DeliveryService.autoAssignRider(orderId).catch((e) => console.error('[auto-assign]', e.message));
    }

    // Marked delivered from the dashboard (not by the rider app): do the same clean-up.
    if (nextStatus === 'delivered') {
      if (order.rider_id) {
        await RiderModel.incrementDeliveries(order.rider_id);
        await releaseRider(order.rider_id);
      }
      if (order.payment_method === 'cod') await OrderModel.setPaymentStatus(orderId, 'paid');
    }

    return OrderModel.findById(orderId);
  },

  async cancel(orderId: number, reason: string) {
    const order = await OrderModel.findById(orderId);
    if (!order) throw new AppError('Order not found', 404);
    if (['delivered', 'cancelled'].includes(order.status)) {
      throw new AppError('This order can no longer be cancelled', 400);
    }
    await OrderModel.cancel(orderId, reason);
    if (order.rider_id) await releaseRider(order.rider_id);
    emitToOrder(orderId, 'order:status', { orderId, status: 'cancelled', note: reason });
    emitToBusiness(order.business_id, 'order:status', { orderId, status: 'cancelled' });
  },
};
