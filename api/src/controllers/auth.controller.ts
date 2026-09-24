import { Request, Response } from 'express';
import { asyncHandler } from '../utils/AppError';
import { ok, created } from '../utils/response.util';
import { AuthService } from '../services/auth.service';

export const AuthController = {
  register: asyncHandler(async (req: Request, res: Response) => {
    const result = await AuthService.register(req.body);
    created(res, result, 'Account created');
  }),

  login: asyncHandler(async (req: Request, res: Response) => {
    const { identifier, password } = req.body;
    const result = await AuthService.login(identifier, password);
    ok(res, result, 'Logged in');
  }),

  refresh: asyncHandler(async (req: Request, res: Response) => {
    const { refreshToken } = req.body;
    const result = await AuthService.refresh(refreshToken);
    ok(res, result, 'Token refreshed');
  }),

  me: asyncHandler(async (req: Request, res: Response) => {
    ok(res, req.user, 'Current user');
  }),
};
