import { Response } from 'express';

export function ok<T>(res: Response, data: T, message = 'Success', status = 200) {
  return res.status(status).json({ success: true, message, data });
}

export function created<T>(res: Response, data: T, message = 'Created') {
  return ok(res, data, message, 201);
}

export function fail(res: Response, message = 'Something went wrong', status = 400, errors?: any) {
  return res.status(status).json({ success: false, message, errors });
}

export function orderNumber() {
  const rand = Math.floor(1000 + Math.random() * 9000);
  return `ORD${Date.now().toString().slice(-8)}${rand}`;
}
