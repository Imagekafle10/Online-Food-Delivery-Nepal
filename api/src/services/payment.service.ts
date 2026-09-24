import { v4 as uuidv4 } from 'uuid';
import { PaymentModel } from '../models/payment.model';
import { OrderModel } from '../models/order.model';
import { RoomModel } from '../models/room.model';
import { UserModel } from '../models/user.model';
import { EsewaHelper } from './esewa.helper';
import { KhaltiHelper } from './khalti.helper';
import { AppError } from '../utils/AppError';
import { PaymentMethod } from '../types';
import { pool } from '../config/db';

async function getReference(referenceType: 'order' | 'room_booking', referenceId: number) {
  const ref = referenceType === 'order'
    ? await OrderModel.findById(referenceId)
    : await RoomModel.findBookingById(referenceId);
  if (!ref) throw new AppError(`${referenceType} not found`, 404);
  return ref;
}

export const PaymentService = {
  // Initiates a payment for an order/room booking. COD needs no gateway call.
  async initiate(userId: number, referenceType: 'order' | 'room_booking', referenceId: number, method: PaymentMethod) {
    const ref: any = await getReference(referenceType, referenceId);
    if (ref.user_id !== userId) throw new AppError('Not your order/booking', 403);

    const amount = Number(ref.total_amount);
    const paymentUuid = uuidv4();
    await PaymentModel.create({ uuid: paymentUuid, reference_type: referenceType, reference_id: referenceId, user_id: userId, amount, method });

    if (method === 'cod') {
      await PaymentModel.markStatus(paymentUuid, 'pending');
      return { method: 'cod', paymentUuid, message: 'Pay with cash on delivery/arrival' };
    }

    if (method === 'esewa') {
      const form = EsewaHelper.buildPaymentForm({ amount, transactionUuid: paymentUuid });
      return { method: 'esewa', paymentUuid, formUrl: EsewaHelper.formUrl(), formFields: form };
    }

    if (method === 'khalti') {
      const user = await UserModel.findById(userId);
      const initiated = await KhaltiHelper.initiate({
        amount,
        purchaseOrderId: paymentUuid,
        purchaseOrderName: `${referenceType} #${referenceId}`,
        customerName: user?.full_name,
        customerEmail: user?.email || undefined,
        customerPhone: user?.phone || undefined,
      });
      await PaymentModel.markStatus(paymentUuid, 'pending', undefined, initiated.pidx);
      return { method: 'khalti', paymentUuid, paymentUrl: initiated.payment_url, pidx: initiated.pidx };
    }

    throw new AppError('Unsupported payment method', 400);
  },

  async handleEsewaCallback(base64Data: string) {
    const { isValid, payload } = EsewaHelper.decodeAndVerify(base64Data);
    if (!isValid) throw new AppError('eSewa signature verification failed', 400);

    const payment = await PaymentModel.findByUuid(payload.transaction_uuid);
    if (!payment) throw new AppError('Payment record not found', 404);

    const success = payload.status === 'COMPLETE';
    await PaymentModel.markStatus(payment.uuid, success ? 'success' : 'failed', payload.transaction_code, payload.transaction_uuid, payload);
    await markReferencePaid(payment, success);
    return { success, payload };
  },

  async handleKhaltiCallback(pidx: string) {
    const result = await KhaltiHelper.verify(pidx);
    const success = result.status === 'Completed';

    const [rows] = await pool.query('SELECT * FROM payments WHERE gateway_ref_id = ?', [pidx]);
    const payment = (rows as any[])[0];
    if (!payment) throw new AppError('Payment record not found', 404);

    await PaymentModel.markStatus(payment.uuid, success ? 'success' : 'failed', result.transaction_id || undefined, pidx, result);
    await markReferencePaid(payment, success);
    return { success, result };
  },

  async getStatus(paymentUuid: string) {
    const payment = await PaymentModel.findByUuid(paymentUuid);
    if (!payment) throw new AppError('Payment not found', 404);
    return payment;
  },
};

async function markReferencePaid(payment: any, success: boolean) {
  const status = success ? 'paid' : 'failed';
  if (payment.reference_type === 'order') {
    await OrderModel.setPaymentStatus(payment.reference_id, status);
  } else {
    await RoomModel.setPaymentStatus(payment.reference_id, status);
  }
}
