/**
 * Order lifecycle (single source of truth for the admin panel):
 *   placed -> accepted -> cooking -> on_the_way -> delivered   (cancelled if there is a problem)
 * Keep in sync with ALLOWED_TRANSITIONS in the API (order.service.ts).
 */
export const ORDER_STATUSES = [
  'placed',
  'accepted',
  'cooking',
  'on_the_way',
  'delivered',
  'cancelled',
] as const

export type OrderStatus = (typeof ORDER_STATUSES)[number]

export const ORDER_STATUS_LABEL: Record<OrderStatus, string> = {
  placed: 'Placed',
  accepted: 'Accepted',
  cooking: 'Cooking',
  on_the_way: 'On the way',
  delivered: 'Delivered',
  cancelled: 'Cancelled',
}

export const ORDER_STATUS_BADGE: Record<OrderStatus, string> = {
  placed: 'badge-muted',
  accepted: 'badge-info',
  cooking: 'badge-warning',
  on_the_way: 'badge-gold',
  delivered: 'badge-success',
  cancelled: 'badge-danger',
}

const NEXT: Record<OrderStatus, OrderStatus[]> = {
  placed: ['accepted', 'cooking', 'cancelled'],
  accepted: ['cooking', 'cancelled'],
  cooking: ['on_the_way', 'delivered', 'cancelled'],
  on_the_way: ['delivered', 'cancelled'],
  delivered: [],
  cancelled: [],
}

/** Statuses an order can be moved to from its current one. */
export function nextStatuses(status: string, orderType?: string): OrderStatus[] {
  const options = NEXT[status as OrderStatus] ?? []
  // pickup / dine-in orders are never "on the way"
  return options.filter((s) => s !== 'on_the_way' || !orderType || orderType === 'delivery')
}

/** Order still needs a rider / is still being worked on (kitchen has accepted or beyond). */
export function isActiveStatus(status: string): boolean {
  return status === 'accepted' || status === 'cooking' || status === 'on_the_way'
}

/** Waiting for kitchen to accept — not yet in active prep. */
export function isPendingKitchen(status: string): boolean {
  return status === 'placed'
}

export function statusLabel(status?: string | null): string {
  if (!status) return '—'
  return ORDER_STATUS_LABEL[status as OrderStatus] ?? status.replace(/_/g, ' ')
}

export function statusBadge(status?: string | null): string {
  return ORDER_STATUS_BADGE[status as OrderStatus] ?? 'badge-muted'
}

const ADMIN_STATUSES: OrderStatus[] = ['accepted', 'cooking', 'on_the_way', 'delivered', 'cancelled']

/** Super admin can move an order to any of these at any time (current status excluded). */
export function adminStatuses(status: string, orderType?: string): OrderStatus[] {
  return ADMIN_STATUSES.filter(
    (s) => s !== status && (s !== 'on_the_way' || !orderType || orderType === 'delivery')
  )
}
