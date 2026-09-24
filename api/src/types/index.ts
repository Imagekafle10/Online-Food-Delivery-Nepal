export type UserRole =
  | "customer"
  | "business_owner"
  | "staff"
  | "rider"
  | "super_admin";

export interface JwtPayload {
  id: number;
  uuid: string;
  role: UserRole;
  email?: string;
}

declare global {
  namespace Express {
    interface Request {
      user?: JwtPayload;
    }
  }
}

export type BusinessType = "hotel" | "restaurant" | "cafe" | "guest_house";

// Order lifecycle: placed -> accepted -> cooking -> on_the_way -> delivered  (cancelled if there is a problem)
// New orders start as "placed" and wait for kitchen acceptance.
export type OrderStatus =
  | "placed"
  | "accepted"
  | "cooking"
  | "on_the_way"
  | "delivered"
  | "cancelled";

export type PaymentMethod = "esewa" | "khalti" | "cod";

// Status of an order/room_booking's `payment_status` column
export type PaymentStatus =
  | "unpaid"
  | "pending"
  | "paid"
  | "failed"
  | "refunded";

// Status of a row in the `payments` gateway-transaction table (different enum, see schema.sql)
export type GatewayPaymentStatus =
  | "initiated"
  | "pending"
  | "success"
  | "failed"
  | "refunded";
export interface ApiSuccess<T = any> {
  success: true;
  message?: string;
  data: T;
}

export interface ApiError {
  success: false;
  message: string;
  errors?: any;
}
