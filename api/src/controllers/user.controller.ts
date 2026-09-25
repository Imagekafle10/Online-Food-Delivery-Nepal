import { Request, Response } from 'express';
import { asyncHandler, AppError } from '../utils/AppError';
import { ok, created } from '../utils/response.util';
import { UserModel } from '../models/user.model';
import { RiderModel } from '../models/rider.model';
import { BusinessModel } from '../models/business.model';
import { AuthService } from '../services/auth.service';

async function loadTarget(req: Request) {
  const id = Number(req.params.id);
  if (!id) throw new AppError('Invalid user id', 422);
  const user = await UserModel.findById(id);
  if (!user) throw new AppError('User not found', 404);
  return user;
}

export const UserController = {
  // super_admin: onboard any account (customer, business_owner, staff, rider, super_admin) from the panel.
  create: asyncHandler(async (req: Request, res: Response) => {
    const { full_name, email, phone, password, role } = req.body;
    if (!full_name || !password) throw new AppError('Full name and password are required', 422);
    if (!email && !phone) throw new AppError('Email or phone is required', 422);

    // AuthService.register already creates the riders row when role === 'rider'.
    const result = await AuthService.register(
      { full_name, email, phone, password, role },
      { allowAnyRole: true }
    );

    created(res, result.user, 'User created');
  }),

  // super_admin: search / filter every account
  adminList: asyncHandler(async (req: Request, res: Response) => {
    const { search, role, status, limit, offset } = req.query;
    const result = await UserModel.listAdmin({
      search: search ? String(search) : undefined,
      role: role ? String(role) : undefined,
      status: status ? String(status) : undefined,
      limit: limit ? Number(limit) : undefined,
      offset: offset ? Number(offset) : undefined,
    });
    ok(res, { users: result.rows, total: result.total, limit: result.limit, offset: result.offset });
  }),

  suspend: asyncHandler(async (req: Request, res: Response) => {
    const user = await loadTarget(req);
    if (user.id === req.user!.id) throw new AppError('You cannot suspend your own account', 400);
    if (user.role === 'super_admin') throw new AppError('Admin accounts cannot be suspended', 403);

    await UserModel.setActive(user.id, false);

    // A suspended rider must not keep receiving deliveries
    if (user.role === 'rider') {
      const rider = await RiderModel.findByUserId(user.id);
      if (rider) await RiderModel.setStatus(rider.id, 'offline');
    }
    ok(res, null, 'User suspended');
  }),

  activate: asyncHandler(async (req: Request, res: Response) => {
    const user = await loadTarget(req);
    await UserModel.setActive(user.id, true);
    ok(res, null, 'User reactivated');
  }),

  // Permanent delete - only allowed AFTER the account has been suspended.
  remove: asyncHandler(async (req: Request, res: Response) => {
    const user = await loadTarget(req);
    if (user.id === req.user!.id) throw new AppError('You cannot delete your own account', 400);
    if (user.role === 'super_admin') throw new AppError('Admin accounts cannot be deleted', 403);
    if (user.is_active) throw new AppError('Suspend this account first, then delete it', 409);

    if (await BusinessModel.countByOwner(user.id)) {
      throw new AppError('This user owns a restaurant/business. Delete that business first.', 409);
    }
    if (user.role === 'rider') {
      const rider = await RiderModel.findByUserId(user.id);
      if (rider && (await RiderModel.countOrders(rider.id)) > 0) {
        throw new AppError('This rider has delivery history and cannot be deleted. Keep the account suspended.', 409);
      }
    }

    await UserModel.remove(user.id); // FK errors (orders, bookings...) -> friendly 409 in error middleware
    ok(res, null, 'User deleted');
  }),
};
