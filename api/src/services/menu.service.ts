import { MenuModel } from '../models/menu.model';
import { AppError } from '../utils/AppError';

const MIN_DISCOUNT_PERCENT = 5;
const MAX_DISCOUNT_PERCENT = 90;

function assertValidDiscountPercent(discountPercent: unknown) {
  if (discountPercent === undefined || discountPercent === null) return;
  const value = Number(discountPercent);
  if (
    Number.isNaN(value) ||
    value < MIN_DISCOUNT_PERCENT ||
    value > MAX_DISCOUNT_PERCENT
  ) {
    throw new AppError(
      `discount_percent must be between ${MIN_DISCOUNT_PERCENT} and ${MAX_DISCOUNT_PERCENT}`,
      422
    );
  }
}

export const MenuService = {
  async addCategory(businessId: number, name: string, sortOrder?: number) {
    const id = await MenuModel.createCategory(businessId, name, sortOrder);
    return { id, business_id: businessId, name };
  },

  async getCategories(businessId: number) {
    return MenuModel.listCategories(businessId);
  },

  async addItem(businessId: number, data: any) {
    assertValidDiscountPercent(data.discount_percent);
    const id = await MenuModel.createItem({ ...data, business_id: businessId });
    return MenuModel.findById(id);
  },

  // includeHidden = true -> management view: inactive categories + unavailable items too.
  async getMenu(businessId: number, includeHidden = false) {
    const [categories, items] = await Promise.all([
      MenuModel.listCategories(businessId, !includeHidden),
      MenuModel.listByBusiness(businessId, !includeHidden),
    ]);
    const grouped = categories.map((cat: any) => ({
      ...cat,
      items: items.filter((i: any) => i.category_id === cat.id),
    }));
    const uncategorized = items.filter((i: any) => !i.category_id);
    if (uncategorized.length) grouped.push({ id: null, name: 'Other', items: uncategorized });
    return grouped;
  },

  async updateItem(businessId: number, itemId: number, data: Record<string, any>) {
    const item = await MenuModel.findById(itemId);
    if (!item || item.business_id !== businessId) throw new AppError('Menu item not found', 404);
    assertValidDiscountPercent(data.discount_percent);
    if (data.price !== undefined && (Number.isNaN(Number(data.price)) || Number(data.price) < 0)) {
      throw new AppError('price must be a valid non-negative number', 422);
    }
    if (data.category_id !== undefined && data.category_id !== null) {
      const cat = await MenuModel.findCategoryById(Number(data.category_id));
      if (!cat || cat.business_id !== businessId) throw new AppError('Category not found for this business', 404);
    }
    const changed = await MenuModel.update(itemId, data);
    if (!changed) throw new AppError('No valid fields to update', 422);
    return MenuModel.findById(itemId);
  },

  async updateCategory(businessId: number, categoryId: number, data: Record<string, any>) {
    const cat = await MenuModel.findCategoryById(categoryId);
    if (!cat || cat.business_id !== businessId) throw new AppError('Category not found', 404);
    const changed = await MenuModel.updateCategory(categoryId, data);
    if (!changed) throw new AppError('No valid fields to update', 422);
    return MenuModel.findCategoryById(categoryId);
  },

  async removeCategory(businessId: number, categoryId: number) {
    const cat = await MenuModel.findCategoryById(categoryId);
    if (!cat || cat.business_id !== businessId) throw new AppError('Category not found', 404);
    await MenuModel.removeCategory(categoryId);
  },

  async setAvailability(businessId: number, itemId: number, isAvailable: boolean) {
    const item = await MenuModel.findById(itemId);
    if (!item || item.business_id !== businessId) throw new AppError('Menu item not found', 404);
    await MenuModel.setAvailability(itemId, isAvailable);
  },

  // Items that appear in past orders can't be hard-deleted (order_items keeps a FK to them),
  // so they are hidden instead (is_available = 0) and order history stays intact.
  async removeItem(businessId: number, itemId: number) {
    const item = await MenuModel.findById(itemId);
    if (!item || item.business_id !== businessId) throw new AppError('Menu item not found', 404);
    if ((await MenuModel.countOrderReferences(itemId)) > 0) {
      await MenuModel.setAvailability(itemId, false);
      return { deleted: false, archived: true };
    }
    await MenuModel.remove(itemId);
    return { deleted: true, archived: false };
  },

  async search(query: string) {
    return MenuModel.search(query);
  },
};
