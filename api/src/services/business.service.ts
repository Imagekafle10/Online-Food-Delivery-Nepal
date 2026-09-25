import { v4 as uuidv4 } from "uuid";
import { BusinessModel } from "../models/business.model";
import { AppError } from "../utils/AppError";
import { AuthService } from "./auth.service";
import { BusinessType, UserRole } from "../types";

function slugify(name: string) {
  return (
    name
      .toLowerCase()
      .trim()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/(^-|-$)/g, "") +
    "-" +
    Math.random().toString(36).slice(2, 6)
  );
}

// Columns a business owner/staff may change on their own business.
const OWNER_EDITABLE = [
  "name", "description", "logo_url", "cover_image_url", "phone", "email", "address", "city",
  "latitude", "longitude", "type", "has_food_ordering", "has_table_booking", "has_room_booking",
  "delivery_radius_km", "base_delivery_fee", "min_order_amount", "avg_prep_time_mins",
  "is_open", "opens_at", "closes_at",
];
// Extra columns only a super_admin may change.
const ADMIN_ONLY_EDITABLE = ["status", "commission_percent"];
const BUSINESS_STATUSES = ["pending", "approved", "suspended", "rejected"];

export const BusinessService = {
  async register(
    ownerId: number,
    data: {
      name: string;
      type: BusinessType;
      description?: string;
      phone?: string;
      email?: string;
      address?: string;
      city?: string;
      latitude?: number;
      longitude?: number;
    },
  ) {
    // Rule: one business_owner → one business only (restaurant OR cafe OR hotel OR guest_house)
    const existing = await BusinessModel.countByOwner(ownerId);
    if (existing >= 1) {
      throw new AppError(
        "You already have a business. One owner can only manage one restaurant, cafe, or hotel.",
        409,
      );
    }

    // Sensible defaults per business type - hotels/guest houses get room booking, all get food ordering
    const has_room_booking =
      data.type === "hotel" || data.type === "guest_house";
    const has_table_booking = data.type !== "guest_house"; // guest houses typically skip dine-in tables

    const businessId = await BusinessModel.create({
      uuid: uuidv4(),
      owner_id: ownerId,
      name: data.name,
      slug: slugify(data.name),
      type: data.type,
      description: data.description,
      phone: data.phone,
      email: data.email,
      address: data.address,
      city: data.city,
      latitude: data.latitude,
      longitude: data.longitude,
      has_food_ordering: true,
      has_table_booking,
      has_room_booking,
    });

    return BusinessModel.findById(businessId);
  },

  /**
   * super_admin: onboard a restaurant/hotel/cafe straight from the panel, creating a
   * brand-new business_owner account for it at the same time. Goes live immediately
   * (skips the "pending" review a self-registered owner would sit in).
   */
  async adminCreate(data: {
    name: string;
    type: BusinessType;
    description?: string;
    phone?: string;
    email?: string;
    address?: string;
    city?: string;
    latitude?: number;
    longitude?: number;
    logo_url?: string;
    owner_full_name: string;
    owner_email?: string;
    owner_phone?: string;
    owner_password: string;
  }) {
    if (!data.name || !data.type) throw new AppError("Restaurant name and type are required", 422);
    if (!data.owner_full_name || !data.owner_password) {
      throw new AppError("Owner name and password are required", 422);
    }
    if (!data.owner_email && !data.owner_phone) {
      throw new AppError("Owner email or phone is required", 422);
    }
    if (data.latitude !== undefined && (typeof data.latitude !== "number" || data.latitude < -90 || data.latitude > 90)) {
      throw new AppError("Latitude must be a number between -90 and 90", 422);
    }
    if (data.longitude !== undefined && (typeof data.longitude !== "number" || data.longitude < -180 || data.longitude > 180)) {
      throw new AppError("Longitude must be a number between -180 and 180", 422);
    }

    const { user: owner } = await AuthService.register(
      {
        full_name: data.owner_full_name,
        email: data.owner_email,
        phone: data.owner_phone,
        password: data.owner_password,
        role: "business_owner",
      },
      { allowAnyRole: true }
    );

    const has_room_booking = data.type === "hotel" || data.type === "guest_house";
    const has_table_booking = data.type !== "guest_house";

    const businessId = await BusinessModel.create({
      uuid: uuidv4(),
      owner_id: owner.id,
      name: data.name,
      slug: slugify(data.name),
      type: data.type,
      description: data.description,
      phone: data.phone,
      email: data.email,
      address: data.address,
      city: data.city,
      latitude: data.latitude,
      longitude: data.longitude,
      logo_url: data.logo_url,
      has_food_ordering: true,
      has_table_booking,
      has_room_booking,
    });

    await BusinessModel.updateStatus(businessId, "approved");
    return BusinessModel.findById(businessId);
  },

  async getOrThrow(id: number) {
    const biz = await BusinessModel.findById(id);
    if (!biz) throw new AppError("Business not found", 404);
    return biz;
  },

  async assertOwnership(businessId: number, userId: number) {
    const isOwner = await BusinessModel.isOwner(businessId, userId);
    if (!isOwner) throw new AppError("You do not manage this business", 403);
  },

  /** super_admin can manage ANY business; everyone else must own / be staff of it. */
  async assertCanManage(businessId: number, user: { id: number; role: UserRole }) {
    if (user.role === "super_admin") {
      await BusinessService.getOrThrow(businessId);
      return;
    }
    await BusinessService.assertOwnership(businessId, user.id);
  },

  /** super_admin search across every restaurant/hotel/cafe, any status. */
  async listAdmin(filters: {
    search?: string;
    status?: string;
    type?: string;
    city?: string;
    limit?: number;
    offset?: number;
  }) {
    return BusinessModel.listAdmin(filters);
  },

  async list(filters: {
    type?: BusinessType;
    city?: string;
    search?: string;
    limit?: number;
    offset?: number;
  }) {
    return BusinessModel.list({ ...filters, status: "approved" });
  },

  async approve(businessId: number) {
    await BusinessModel.updateStatus(businessId, "approved");
    return BusinessModel.findById(businessId);
  },

  async suspend(businessId: number) {
    await BusinessModel.updateStatus(businessId, "suspended");
  },

  async update(businessId: number, data: Record<string, any>, role?: UserRole) {
    // Whitelist columns (column names are interpolated into SQL, and owners must not be
    // able to self-approve or change their own commission).
    const allowed = role === "super_admin" ? [...OWNER_EDITABLE, ...ADMIN_ONLY_EDITABLE] : OWNER_EDITABLE;
    const clean: Record<string, any> = {};
    for (const key of allowed) {
      if (data && data[key] !== undefined) clean[key] = data[key];
    }
    if (!Object.keys(clean).length) throw new AppError("No valid fields to update", 422);
    if (clean.status !== undefined && !BUSINESS_STATUSES.includes(clean.status)) {
      throw new AppError(`status must be one of: ${BUSINESS_STATUSES.join(", ")}`, 422);
    }
    if (clean.commission_percent !== undefined) {
      const c = Number(clean.commission_percent);
      if (Number.isNaN(c) || c < 0 || c > 100) throw new AppError("commission_percent must be between 0 and 100", 422);
    }
    await BusinessModel.update(businessId, clean);
    return BusinessModel.findById(businessId);
  },

  async toggleOpen(businessId: number, isOpen: boolean) {
    await BusinessModel.toggleOpen(businessId, isOpen);
  },

  /** Permanent delete - only for suspended businesses. Menu, tables, rooms and staff go with it;
   *  businesses with orders / bookings are refused by the FK constraints (409 in error middleware). */
  async remove(businessId: number) {
    const biz = await BusinessService.getOrThrow(businessId);
    if (biz.status !== "suspended") {
      throw new AppError("Suspend this business first, then delete it", 409);
    }
    await BusinessModel.remove(businessId);
  },
};
