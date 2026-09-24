import crypto from 'crypto';
import { env } from '../config/env';

// eSewa v2 ePay (rc-epay) integration.
// Docs: https://developer.esewa.com.np/pages/Epay#integration
// Flow: build a signed form -> redirect user to eSewa -> eSewa redirects back to
// success/failure URL with a base64-encoded `data` query param that must be verified.

interface EsewaFormFields {
  amount: string;
  tax_amount: string;
  total_amount: string;
  transaction_uuid: string;
  product_code: string;
  product_service_charge: string;
  product_delivery_charge: string;
  success_url: string;
  failure_url: string;
  signed_field_names: string;
  signature: string;
}

function sign(message: string) {
  return crypto.createHmac('sha256', env.esewa.secretKey).update(message).digest('base64');
}

export const EsewaHelper = {
  // Builds the fields the frontend should POST (as a hidden form) to
  // `${ESEWA_BASE_URL}/api/epay/main/v2/form`
  buildPaymentForm(params: { amount: number; transactionUuid: string }): EsewaFormFields {
    const amount = params.amount.toFixed(2);
    const taxAmount = '0';
    const totalAmount = amount;
    const signedFieldNames = 'total_amount,transaction_uuid,product_code';
    const message = `total_amount=${totalAmount},transaction_uuid=${params.transactionUuid},product_code=${env.esewa.merchantCode}`;

    return {
      amount,
      tax_amount: taxAmount,
      total_amount: totalAmount,
      transaction_uuid: params.transactionUuid,
      product_code: env.esewa.merchantCode,
      product_service_charge: '0',
      product_delivery_charge: '0',
      success_url: env.esewa.successUrl,
      failure_url: env.esewa.failureUrl,
      signed_field_names: signedFieldNames,
      signature: sign(message),
    };
  },

  formUrl() {
    return `${env.esewa.baseUrl}/api/epay/main/v2/form`;
  },

  // eSewa redirects to success_url?data=<base64 JSON>. Decode + verify signature.
  decodeAndVerify(base64Data: string) {
    const decoded = JSON.parse(Buffer.from(base64Data, 'base64').toString('utf-8'));
    const fieldNames: string[] = decoded.signed_field_names.split(',');
    const message = fieldNames.map((f) => `${f}=${decoded[f]}`).join(',');
    const expectedSignature = sign(message);
    const isValid = expectedSignature === decoded.signature;
    return { isValid, payload: decoded };
  },

  // Server-side status check (recommended in addition to signature check):
  // GET {base}/api/epay/transaction/status/?product_code=..&total_amount=..&transaction_uuid=..
  statusCheckUrl(transactionUuid: string, totalAmount: number) {
    return `${env.esewa.baseUrl}/api/epay/transaction/status/?product_code=${env.esewa.merchantCode}&total_amount=${totalAmount}&transaction_uuid=${transactionUuid}`;
  },
};
