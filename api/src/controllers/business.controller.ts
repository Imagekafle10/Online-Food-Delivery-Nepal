import { Request, Response } from 'express';
import { asyncHandler } from '../utils/AppError';
import { ok, created } from '../utils/response.util';
import { BusinessService } from '../services/business.service';

// The admin-create form may arrive as JSON or as multipart (when a logo image is attached).
// Multipart sends every field as a string, so convert lat/lng back to numbers and attach
// the uploaded image path, same as the menu item image handling.
function parseAdminCreateBody(req: Request): Record<string, any> {
  const body: Record<string, any> = { ...req.body };
  if (req.file) body.logo_url = `/uploads/${req.file.filename}`;

  const toNumber = (v: any) => (typeof v === 'string' ? (v.trim() === '' ? undefined : Number(v)) : v);
  if (body.latitude !== undefined) body.latitude = toNumber(body.latitude);
  if (body.longitude !== undefined) body.longitude = toNumber(body.longitude);
  return body;
}

export const BusinessController = {
  register: asyncHandler(async (req: Request, res: Response) => {
    const business = await BusinessService.register(req.user!.id, req.body);
    created(res, business, 'Business registered - pending approval');
  }),

  // super_admin: onboard a restaurant/hotel/cafe + its owner account in one step.
  adminCreate: asyncHandler(async (req: Request, res: Response) => {
    const business = await BusinessService.adminCreate(parseAdminCreateBody(req) as any);
    created(res, business, 'Restaurant created');
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
