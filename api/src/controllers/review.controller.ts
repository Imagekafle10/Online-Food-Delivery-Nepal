import { Request, Response } from 'express';
import { asyncHandler } from '../utils/AppError';
import { ok, created } from '../utils/response.util';
import { ReviewService } from '../services/review.service';

export const ReviewController = {
  create: asyncHandler(async (req: Request, res: Response) => {
    const r = await ReviewService.create(req.user!.id, req.body);
    created(res, r, 'Thanks for your rating');
  }),
  forBusiness: asyncHandler(async (req: Request, res: Response) => {
    ok(res, await ReviewService.listForBusiness(Number(req.params.businessId)));
  }),
  forOrder: asyncHandler(async (req: Request, res: Response) => {
    ok(res, await ReviewService.getForOrder(req.user!.id, Number(req.params.orderId)));
  }),
};
