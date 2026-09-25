import { v4 as uuidv4 } from 'uuid';
import { UserModel } from '../models/user.model';
import { RiderModel } from '../models/rider.model';
import { hashPassword, comparePassword, signAccessToken, signRefreshToken, verifyRefreshToken } from '../utils/auth.util';
import { AppError } from '../utils/AppError';
import { UserRole } from '../types';

export const AuthService = {
  async register(
    data: { full_name: string; email?: string; phone?: string; password: string; role?: UserRole },
    options?: { allowAnyRole?: boolean }
  ) {
    if (!data.email && !data.phone) throw new AppError('Email or phone is required', 422);

    if (data.email) {
      const existing = await UserModel.findByEmail(data.email);
      if (existing) throw new AppError('Email already registered', 409);
    }
    if (data.phone) {
      const existing = await UserModel.findByPhone(data.phone);
      if (existing) throw new AppError('Phone already registered', 409);
    }

    const password_hash = await hashPassword(data.password);
    const uuid = uuidv4();
    // Public /auth/register can only self-sign-up as customer/business_owner/rider.
    // A super_admin onboarding an account from the admin panel may set any role (staff, super_admin included).
    const allowedRoles: UserRole[] = options?.allowAnyRole
      ? ['customer', 'business_owner', 'staff', 'rider', 'super_admin']
      : ['customer', 'business_owner', 'rider'];
    const role: UserRole = data.role && allowedRoles.includes(data.role) ? data.role : 'customer';

    const userId = await UserModel.create({
      uuid, full_name: data.full_name, email: data.email, phone: data.phone, password_hash, role,
    });

    if (role === 'rider') {
      await RiderModel.create(userId);
    }

    const user = await UserModel.findById(userId);
    return AuthService.buildAuthResponse(user!);
  },

  async login(identifier: string, password: string) {
    const user = await UserModel.findByEmailOrPhone(identifier);
    if (!user) throw new AppError('Invalid credentials', 401);
    const match = await comparePassword(password, user.password_hash);
    if (!match) throw new AppError('Invalid credentials', 401);
    if (!user.is_active) throw new AppError('Account is deactivated', 403);
    return AuthService.buildAuthResponse(user);
  },

  async refresh(refreshToken: string) {
    let payload;
    try {
      payload = verifyRefreshToken(refreshToken);
    } catch {
      throw new AppError('Invalid or expired refresh token', 401);
    }
    const user = await UserModel.findById(payload.id);
    if (!user) throw new AppError('User not found', 404);
    if (!user.is_active) throw new AppError('Account is deactivated', 403);
    return AuthService.buildAuthResponse(user);
  },

  buildAuthResponse(user: any) {
    const payload = { id: user.id, uuid: user.uuid, role: user.role, email: user.email };
    const accessToken = signAccessToken(payload);
    const refreshToken = signRefreshToken(payload);
    const { password_hash, ...safeUser } = user;
    return { user: safeUser, accessToken, refreshToken };
  },
};
