import { Request, Response } from 'express';
import { asyncHandler, AppError } from '../utils/AppError';
import { ok } from '../utils/response.util';
import { DeliveryService } from '../services/delivery.service';
import { RiderModel } from '../models/rider.model';

async function riderIdOfUser(userId: number) {
  const rider = await RiderModel.findByUserId(userId);
  if (!rider) throw new AppError('Rider profile not found', 404);
  return rider.id;
}

export const DeliveryController = {
  goOnline: asyncHandler(async (req: Request, res: Response) => {
    const riderId = await riderIdOfUser(req.user!.id);
    await DeliveryService.goOnline(riderId);
    ok(res, null, 'You are now online');
  }),

  goOffline: asyncHandler(async (req: Request, res: Response) => {
    const riderId = await riderIdOfUser(req.user!.id);
    await DeliveryService.goOffline(riderId);
    ok(res, null, 'You are now offline');
  }),

  ping: asyncHandler(async (req: Request, res: Response) => {
    const riderId = await riderIdOfUser(req.user!.id);
    const { lat, lng, orderId } = req.body;
    await DeliveryService.pingLocation(riderId, lat, lng, orderId);
    ok(res, null, 'Location updated');
  }),

  myDeliveries: asyncHandler(async (req: Request, res: Response) => {
    const riderId = await riderIdOfUser(req.user!.id);
    const orders = await DeliveryService.activeDeliveries(riderId);
    ok(res, orders);
  }),

  history: asyncHandler(async (req: Request, res: Response) => {
    const riderId = await riderIdOfUser(req.user!.id);
    const limit = req.query.limit ? Number(req.query.limit) : undefined;
    const offset = req.query.offset ? Number(req.query.offset) : undefined;
    const orders = await DeliveryService.history(riderId, limit, offset);
    ok(res, orders);
  }),

  pickedUp: asyncHandler(async (req: Request, res: Response) => {
    const riderId = await riderIdOfUser(req.user!.id);
    const order = await DeliveryService.markPickedUp(Number(req.params.orderId), riderId);
    ok(res, order, 'Marked as picked up');
  }),

  onTheWay: asyncHandler(async (req: Request, res: Response) => {
    const riderId = await riderIdOfUser(req.user!.id);
    const order = await DeliveryService.markOnTheWay(Number(req.params.orderId), riderId);
    ok(res, order, 'Marked as on the way');
  }),

  delivered: asyncHandler(async (req: Request, res: Response) => {
    const riderId = await riderIdOfUser(req.user!.id);
    const order = await DeliveryService.markDelivered(Number(req.params.orderId), riderId);
    ok(res, order, 'Marked as delivered');
  }),

  manualAssign: asyncHandler(async (req: Request, res: Response) => {
    const order = await DeliveryService.manualAssign(Number(req.params.orderId), req.body.rider_id);
    ok(res, order, 'Rider assigned');
  }),

  unassignedReady: asyncHandler(async (req: Request, res: Response) => {
    const businessId = req.query.businessId ? Number(req.query.businessId) : undefined;
    const orders = await DeliveryService.unassignedReadyOrders(businessId);
    ok(res, orders);
  }),

  allOrders: asyncHandler(async (req: Request, res: Response) => {
    const businessId = req.query.businessId ? Number(req.query.businessId) : undefined;
    const status = req.query.status as any;
    const orders = await DeliveryService.allOrders(businessId, status);
    ok(res, orders);
  }),
};
