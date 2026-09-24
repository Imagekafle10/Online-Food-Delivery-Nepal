import { Request, Response } from 'express';
import { asyncHandler } from '../utils/AppError';
import { ok, created } from '../utils/response.util';
import { MenuService } from '../services/menu.service';
import { BusinessService } from '../services/business.service';

// Item forms may arrive as JSON or as multipart (when a photo is attached). Multipart sends
// every field as a string, so convert them back and attach the uploaded image path.
function parseItemBody(req: Request): Record<string, any> {
  const body: Record<string, any> = { ...req.body };
  if (req.file) body.image_url = `/uploads/${req.file.filename}`;

  const toNumber = (v: any) => (typeof v === 'string' ? Number(v) : v);
  const toNullableNumber = (v: any) => (typeof v === 'string' ? (v.trim() === '' ? null : Number(v)) : v);
  const toBool = (v: any) => (typeof v === 'string' ? v === 'true' || v === '1' : v);

  if (body.price !== undefined) body.price = toNumber(body.price);
  if (body.prep_time_mins !== undefined) body.prep_time_mins = toNumber(body.prep_time_mins);
  if (body.discount_percent !== undefined) body.discount_percent = toNullableNumber(body.discount_percent);
  if (body.category_id !== undefined) body.category_id = toNullableNumber(body.category_id);
  if (body.is_veg !== undefined) body.is_veg = toBool(body.is_veg);
  if (body.is_available !== undefined) body.is_available = toBool(body.is_available);
  return body;
}

export const MenuController = {
  getMenu: asyncHandler(async (req: Request, res: Response) => {
    const menu = await MenuService.getMenu(Number(req.params.businessId));
    ok(res, menu);
  }),

  addCategory: asyncHandler(async (req: Request, res: Response) => {
    const businessId = Number(req.params.businessId);
    await BusinessService.assertCanManage(businessId, req.user!);
    const category = await MenuService.addCategory(businessId, req.body.name, req.body.sort_order);
    created(res, category, 'Category added');
  }),

  addItem: asyncHandler(async (req: Request, res: Response) => {
    const businessId = Number(req.params.businessId);
    await BusinessService.assertCanManage(businessId, req.user!);
    const item = await MenuService.addItem(businessId, parseItemBody(req));
    created(res, item, 'Menu item added');
  }),

  updateItem: asyncHandler(async (req: Request, res: Response) => {
    const businessId = Number(req.params.businessId);
    await BusinessService.assertCanManage(businessId, req.user!);
    const item = await MenuService.updateItem(businessId, Number(req.params.itemId), parseItemBody(req));
    ok(res, item, 'Menu item updated');
  }),

  setAvailability: asyncHandler(async (req: Request, res: Response) => {
    const businessId = Number(req.params.businessId);
    await BusinessService.assertCanManage(businessId, req.user!);
    await MenuService.setAvailability(businessId, Number(req.params.itemId), req.body.is_available);
    ok(res, null, 'Availability updated');
  }),

  removeItem: asyncHandler(async (req: Request, res: Response) => {
    const businessId = Number(req.params.businessId);
    await BusinessService.assertCanManage(businessId, req.user!);
    const result = await MenuService.removeItem(businessId, Number(req.params.itemId));
    ok(
      res,
      result,
      result.archived
        ? 'Item is part of past orders, so it was hidden from the menu instead of deleted'
        : 'Menu item removed'
    );
  }),

  // Management view: includes unavailable items + inactive categories
  getManageMenu: asyncHandler(async (req: Request, res: Response) => {
    const businessId = Number(req.params.businessId);
    await BusinessService.assertCanManage(businessId, req.user!);
    ok(res, await MenuService.getMenu(businessId, true));
  }),

  updateCategory: asyncHandler(async (req: Request, res: Response) => {
    const businessId = Number(req.params.businessId);
    await BusinessService.assertCanManage(businessId, req.user!);
    const cat = await MenuService.updateCategory(businessId, Number(req.params.categoryId), req.body);
    ok(res, cat, 'Category updated');
  }),

  removeCategory: asyncHandler(async (req: Request, res: Response) => {
    const businessId = Number(req.params.businessId);
    await BusinessService.assertCanManage(businessId, req.user!);
    await MenuService.removeCategory(businessId, Number(req.params.categoryId));
    ok(res, null, 'Category removed (its items were kept, now uncategorized)');
  }),

  search: asyncHandler(async (req: Request, res: Response) => {
    const results = await MenuService.search(String(req.query.q || ''));
    ok(res, results);
  }),
};
