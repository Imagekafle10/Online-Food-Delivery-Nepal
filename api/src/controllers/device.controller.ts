import { Request, Response } from 'express';
import { asyncHandler, AppError } from '../utils/AppError';
import { ok } from '../utils/response.util';
import { DeviceModel } from '../models/device.model';

export const DeviceController = {
  register: asyncHandler(async (req: Request, res: Response) => {
    const { token, platform } = req.body || {};
    if (!token || typeof token !== 'string') throw new AppError('token is required', 422);
    const p = ['android', 'ios', 'web'].includes(platform) ? platform : 'android';
    await DeviceModel.upsert(req.user!.id, token, p);
    ok(res, null, 'Device registered');
  }),

  unregister: asyncHandler(async (req: Request, res: Response) => {
    const { token } = req.body || {};
    if (!token || typeof token !== 'string') throw new AppError('token is required', 422);
    await DeviceModel.remove(token, req.user!.id);
    ok(res, null, 'Device removed');
  }),
};
