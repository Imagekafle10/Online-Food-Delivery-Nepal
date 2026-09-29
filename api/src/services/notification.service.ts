import { getMessaging } from "../config/firebase";
import { DeviceModel } from "../models/device.model";
import { OrderStatus } from "../types";

type Channel = "order_updates" | "rider_alerts" | "business_orders";

interface Push {
  title: string;
  body: string;
  channel: Channel;
  data?: Record<string, string | number>;
}

// Customer-facing copy for every status change.
const CUSTOMER_COPY: Record<
  OrderStatus,
  { title: string; body: string } | null
> = {
  placed: null, // customer just placed it, no need to ping them
  accepted: {
    title: "Order confirmed ✅",
    body: "The restaurant accepted your order.",
  },
  cooking: {
    title: "Preparing your food 👨‍🍳",
    body: "Your order is being cooked.",
  },
  on_the_way: {
    title: "Out for delivery 🛵",
    body: "Your rider is on the way. Track it live in the app.",
  },
  delivered: {
    title: "Order delivered 🎉",
    body: "Enjoy your meal! Tap to rate your order.",
  },
  cancelled: { title: "Order cancelled", body: "Your order was cancelled." },
};

async function sendToTokens(tokens: string[], p: Push) {
  const messaging = getMessaging();
  if (!messaging) {
    console.log(
      "[push] SKIP: Firebase not initialised (check FIREBASE_SERVICE_ACCOUNT_BASE64 in local .env)",
    );
    return;
  }
  if (!tokens.length) {
    console.log("[push] SKIP: no device tokens for target user(s)");
    return;
  }

  // Data-only fields must be strings for FCM.
  const data: Record<string, string> = {
    channel: p.channel,
    title: p.title,
    body: p.body,
  };
  for (const [k, v] of Object.entries(p.data || {})) data[k] = String(v);

  const res = await messaging.sendEachForMulticast({
    tokens,
    notification: { title: p.title, body: p.body },
    data,
    android: {
      priority: "high",
      notification: { channelId: p.channel, sound: "default" },
    },
    apns: { payload: { aps: { sound: "default" } } },
  });

  console.log(`[push] sent ${res.successCount}/${tokens.length} "${p.title}"`);
  res.responses.forEach((r, i) => {
    if (r.error)
      console.log(`[push] token ${i} failed:`, r.error.code, r.error.message);
  });

  // Clean out tokens that are no longer valid (app uninstalled, token rotated).
  const dead: string[] = [];
  res.responses.forEach((r: { error?: { code?: string } }, i: number) => {
    const code = r.error?.code;
    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token"
    )
      dead.push(tokens[i]);
  });
  if (dead.length) await DeviceModel.removeMany(dead);
}

async function sendToUsers(userIds: number[], p: Push) {
  try {
    console.log("[push] sending to user ids:", userIds, "-", p.title);
    const tokens = await DeviceModel.tokensForUsers([...new Set(userIds)]);
    await sendToTokens(tokens, p);
  } catch (e: any) {
    // Never let a push failure break an order flow.
    console.error("[push] send failed:", e.message);
  }
}

export const NotificationService = {
  // Customer: order status changed.
  async orderStatus(
    order: { id: number; user_id: number; order_number?: string },
    status: OrderStatus,
    note?: string | null,
  ) {
    console.log("[push] orderStatus called:", {
      orderId: order.id,
      userId: order.user_id,
      status,
    });
    const copy = CUSTOMER_COPY[status];
    if (!copy) return;
    const body =
      status === "cancelled" && note && note !== "Cancelled"
        ? `Reason: ${note}`
        : copy.body;
    await sendToUsers([order.user_id], {
      title: copy.title,
      body: order.order_number ? `${body} (#${order.order_number})` : body,
      channel: "order_updates",
      data: { type: "order_status", orderId: order.id, status },
    });
  },

  // Restaurant owner + staff: new order.
  async newOrderForBusiness(
    businessId: number,
    order: { id: number; order_number?: string; total_amount?: number },
  ) {
    try {
      const ids = await DeviceModel.businessUserIds(businessId);
      await sendToUsers(ids, {
        title: "New order received 🍽️",
        body: `Order #${order.order_number ?? order.id}${order.total_amount ? ` · Rs ${order.total_amount}` : ""}`,
        channel: "business_orders",
        data: { type: "new_order", orderId: order.id },
      });
    } catch (e: any) {
      console.error("[push] business notify failed:", e.message);
    }
  },

  // Business side: customer cancelled.
  async orderCancelledForBusiness(
    businessId: number,
    orderId: number,
    reason: string,
  ) {
    try {
      const ids = await DeviceModel.businessUserIds(businessId);
      await sendToUsers(ids, {
        title: "Order cancelled",
        body: `Order #${orderId} was cancelled. ${reason || ""}`.trim(),
        channel: "business_orders",
        data: { type: "order_cancelled", orderId },
      });
    } catch (e: any) {
      console.error("[push] business notify failed:", e.message);
    }
  },

  // Rider: new delivery assigned.
  async riderAssigned(riderId: number, orderId: number) {
    try {
      const userId = await DeviceModel.riderUserId(riderId);
      if (!userId) return;
      await sendToUsers([userId], {
        title: "New delivery assigned 🛵",
        body: "Tap to view pickup and drop-off details.",
        channel: "rider_alerts",
        data: { type: "delivery_assigned", orderId },
      });
    } catch (e: any) {
      console.error("[push] rider notify failed:", e.message);
    }
  },
};
