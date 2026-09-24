import axios from 'axios';
import { env } from '../config/env';

// Khalti Payment Gateway (ePayment API v2).
// Docs: https://docs.khalti.com/khalti-epayment/
// Flow: call /epayment/initiate/ to get a `pidx` + payment_url -> redirect user there ->
// Khalti redirects back to return_url -> verify with /epayment/lookup/.

const client = axios.create({
  baseURL: env.khalti.baseUrl,
  headers: { Authorization: `Key ${env.khalti.secretKey}`, 'Content-Type': 'application/json' },
});

export const KhaltiHelper = {
  async initiate(params: {
    amount: number; // in NPR (helper converts to paisa)
    purchaseOrderId: string;
    purchaseOrderName: string;
    customerName?: string;
    customerEmail?: string;
    customerPhone?: string;
  }) {
    const { data } = await client.post('/epayment/initiate/', {
      return_url: env.khalti.returnUrl,
      website_url: env.clientUrl,
      amount: Math.round(params.amount * 100), // paisa
      purchase_order_id: params.purchaseOrderId,
      purchase_order_name: params.purchaseOrderName,
      customer_info: {
        name: params.customerName || 'Customer',
        email: params.customerEmail || undefined,
        phone: params.customerPhone || undefined,
      },
    });
    return data as { pidx: string; payment_url: string; expires_at: string };
  },

  async verify(pidx: string) {
    const { data } = await client.post('/epayment/lookup/', { pidx });
    return data as { pidx: string; status: string; total_amount: number; transaction_id: string | null };
  },
};
