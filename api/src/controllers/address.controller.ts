import { Request, Response } from 'express';
import { asyncHandler } from '../utils/AppError';
import { ok, created } from '../utils/response.util';
import { AddressModel } from '../models/address.model';

export const AddressController = {
  add: asyncHandler(async (req: Request, res: Response) => {
    const id = await AddressModel.create({ ...req.body, user_id: req.user!.id });
    created(res, { id }, 'Address added');
  }),

  list: asyncHandler(async (req: Request, res: Response) => {
    const addresses = await AddressModel.listByUser(req.user!.id);
    ok(res, addresses);
  }),

  remove: asyncHandler(async (req: Request, res: Response) => {
    await AddressModel.remove(Number(req.params.id), req.user!.id);
    ok(res, null, 'Address removed');
  }),
};
