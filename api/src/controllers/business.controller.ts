import { Request, Response } from 'express';
import { asyncHandler } from '../utils/AppError';
import { ok, created } from '../utils/response.util';
import { BusinessService } from '../services/business.service';

export const BusinessController = {
  register: asyncHandler(async (req: Request, res: Response) => {
    const business = await BusinessService.register(req.user!.id, req.body);
    created(res, business, 'Business registered - pending approval');
  }),

  list: asyncHandler(async (req: Request, res: Response) => {
    const { type, city, search, limit, offset } = req.query;
    const businesses = await BusinessService.list({
      type: type as any, city: city as any, search: search as any,
      limit: limit ? Number(limit) : undefined, offset: offset ? Number(offset) : undefined,
    });
    ok(res, businesses);
  }),

  // super_admin: search every business (any status) with owner + menu/order counts
  adminList: asyncHandler(async (req: Request, res: Response) => {
    const { search, status, type, city, limit, offset } = req.query;
    const result = await BusinessService.listAdmin({
      search: search ? String(search) : undefined,
      status: status ? String(status) : undefined,
      type: type ? String(type) : undefined,
      city: city ? String(city) : undefined,
      limit: limit ? Number(limit) : undefined,
      offset: offset ? Number(offset) : undefined,
    });
    ok(res, { businesses: result.rows, total: result.total, limit: result.limit, offset: result.offset });
  }),

  getOne: asyncHandler(async (req: Request, res: Response) => {
    const business = await BusinessService.getOrThrow(Number(req.params.id));
    ok(res, business);
  }),

  update: asyncHandler(async (req: Request, res: Response) => {
    const businessId = Number(req.params.id);
    await BusinessService.assertCanManage(businessId, req.user!);
    const business = await BusinessService.update(businessId, req.body, req.user!.role);
    ok(res, business, 'Business updated');
  }),

  toggleOpen: asyncHandler(async (req: Request, res: Response) => {
    const businessId = Number(req.params.id);
    await BusinessService.assertCanManage(businessId, req.user!);
    await BusinessService.toggleOpen(businessId, req.body.is_open);
    ok(res, null, 'Status updated');
  }),

  approve: asyncHandler(async (req: Request, res: Response) => {
    const business = await BusinessService.approve(Number(req.params.id));
    ok(res, business, 'Business approved');
  }),

  suspend: asyncHandler(async (req: Request, res: Response) => {
    await BusinessService.suspend(Number(req.params.id));
    ok(res, null, 'Business suspended');
  }),

  remove: asyncHandler(async (req: Request, res: Response) => {
    await BusinessService.remove(Number(req.params.id));
    ok(res, null, 'Business deleted');
  }),
};
