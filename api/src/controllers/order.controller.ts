import { Request, Response } from 'express';
import { asyncHandler } from '../utils/AppError';
import { ok, created } from '../utils/response.util';
import { OrderService } from '../services/order.service';
import { BusinessService } from '../services/business.service';

export const OrderController = {
  place: asyncHandler(async (req: Request, res: Response) => {
    const result = await OrderService.placeOrder(req.user!.id, req.body);
    created(res, result, 'Order placed');
  }),

  getOne: asyncHandler(async (req: Request, res: Response) => {
    const full = await OrderService.getFullOrder(Number(req.params.id));
    ok(res, full);
  }),

  myOrders: asyncHandler(async (req: Request, res: Response) => {
    const { limit, offset } = req.query;
    const orders = await OrderService.myOrders(req.user!.id, limit ? Number(limit) : undefined, offset ? Number(offset) : undefined);
    ok(res, orders);
  }),

  businessOrders: asyncHandler(async (req: Request, res: Response) => {
    const businessId = Number(req.params.businessId);
    await BusinessService.assertCanManage(businessId, req.user!);
    const orders = await OrderService.businessOrders(businessId, req.query.status as any);
    ok(res, orders);
  }),

  // ---- super_admin ----
  adminList: asyncHandler(async (req: Request, res: Response) => {
    const q = req.query;
    const result = await OrderService.adminList({
      search: q.search ? String(q.search) : undefined,
      status: q.status ? String(q.status) : undefined,
      businessId: q.business_id ? Number(q.business_id) : undefined,
      orderType: q.order_type ? String(q.order_type) : undefined,
      paymentStatus: q.payment_status ? String(q.payment_status) : undefined,
      from: q.from ? String(q.from) : undefined,
      to: q.to ? String(q.to) : undefined,
      limit: q.limit ? Number(q.limit) : undefined,
      offset: q.offset ? Number(q.offset) : undefined,
    });
    ok(res, { orders: result.rows, total: result.total, limit: result.limit, offset: result.offset });
  }),

  adminGetOne: asyncHandler(async (req: Request, res: Response) => {
    ok(res, await OrderService.adminGetDetail(Number(req.params.id)));
  }),

  adminRemove: asyncHandler(async (req: Request, res: Response) => {
    const force = String(req.query.force || '').toLowerCase() === 'true';
    await OrderService.adminDelete(Number(req.params.id), force);
    ok(res, null, 'Order deleted');
  }),

  updateStatus: asyncHandler(async (req: Request, res: Response) => {
    const order = await OrderService.transition(Number(req.params.id), req.body.status, req.body.note);
    ok(res, order, 'Order status updated');
  }),

  cancel: asyncHandler(async (req: Request, res: Response) => {
    await OrderService.cancel(Number(req.params.id), req.body.reason || 'Cancelled by user');
    ok(res, null, 'Order cancelled');
  }),
};
