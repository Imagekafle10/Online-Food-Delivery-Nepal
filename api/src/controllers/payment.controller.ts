import { Request, Response } from 'express';
import { asyncHandler } from '../utils/AppError';
import { ok } from '../utils/response.util';
import { PaymentService } from '../services/payment.service';
import { env } from '../config/env';

export const PaymentController = {
  initiate: asyncHandler(async (req: Request, res: Response) => {
    const { reference_type, reference_id, method } = req.body;
    const result = await PaymentService.initiate(req.user!.id, reference_type, reference_id, method);
    ok(res, result, 'Payment initiated');
  }),

  status: asyncHandler(async (req: Request, res: Response) => {
    const payment = await PaymentService.getStatus(req.params.uuid);
    ok(res, payment);
  }),

  // eSewa redirects here with ?data=<base64> after payment
  esewaSuccess: asyncHandler(async (req: Request, res: Response) => {
    const { success, payload } = await PaymentService.handleEsewaCallback(String(req.query.data));
    res.redirect(`${env.clientUrl}/payment/result?provider=esewa&status=${success ? 'success' : 'failed'}&ref=${payload.transaction_uuid}`);
  }),

  esewaFailure: asyncHandler(async (req: Request, res: Response) => {
    res.redirect(`${env.clientUrl}/payment/result?provider=esewa&status=failed`);
  }),

  // Khalti redirects here with ?pidx=...
  khaltiCallback: asyncHandler(async (req: Request, res: Response) => {
    const { success } = await PaymentService.handleKhaltiCallback(String(req.query.pidx));
    res.redirect(`${env.clientUrl}/payment/result?provider=khalti&status=${success ? 'success' : 'failed'}&pidx=${req.query.pidx}`);
  }),
};
