import type { PluginObject } from "../../sdk";

// ── Status ────────────────────────────────────────────────────────────────────

export type OrderStatus = "pending" | "packed" | "shipped" | "delivered" | "returned";

export const ORDER_STATUSES: OrderStatus[] = [
  "pending",
  "packed",
  "shipped",
  "delivered",
  "returned",
];

/**
 * Returns the next status in the linear flow, or null when already at a
 * terminal state (delivered or returned).
 *
 * Flow: pending → packed → shipped → delivered
 * returned is a terminal state reachable from any non-delivered status via the
 * "Return" action — it is NOT part of the linear advance flow.
 */
export function nextStatus(current: OrderStatus): OrderStatus | null {
  const flow: OrderStatus[] = ["pending", "packed", "shipped", "delivered"];
  const idx = flow.indexOf(current);
  if (idx === -1 || idx === flow.length - 1) return null; // terminal or returned
  return flow[idx + 1];
}

// ── Delivery Method ───────────────────────────────────────────────────────────

export type DeliveryMethod = "parcel_locker" | "delivery_man";

export const DELIVERY_METHODS: DeliveryMethod[] = ["parcel_locker", "delivery_man"];

export const DELIVERY_METHOD_LABELS: Record<DeliveryMethod, string> = {
  parcel_locker: "Parcel Locker",
  delivery_man: "Delivery Man",
};

/**
 * Suggest delivery method based on box dimensions from the box-size plugin.
 * Rule: max(length, width, height) ≤ 60 cm → parcel_locker; otherwise delivery_man.
 * Returns null when no box-size data is available (caller should not pre-select).
 */
export function suggestDeliveryMethod(
  boxData: { length: number; width: number; height: number } | null
): DeliveryMethod | null {
  if (!boxData) return null;
  const maxDim = Math.max(boxData.length, boxData.width, boxData.height);
  return maxDim <= 60 ? "parcel_locker" : "delivery_man";
}

// ── Order ─────────────────────────────────────────────────────────────────────

export interface Order {
  /** Stable object ID (UUID). Not the business order number. */
  objectId: string;
  /** Human-readable order number entered by the user. Unique per product. */
  orderNumber: string;
  status: OrderStatus;
  deliveryMethod: DeliveryMethod;
  /** Present only when deliveryMethod === "parcel_locker". Empty string when not set. */
  lockerCode: string;
  /** The product this order belongs to. */
  productId: string;
}

export function toOrder(obj: PluginObject): Order {
  const d = obj.data;
  return {
    objectId: obj.objectId,
    orderNumber: d.orderNumber as string,
    status: d.status as OrderStatus,
    deliveryMethod: d.deliveryMethod as DeliveryMethod,
    lockerCode: (d.lockerCode as string | undefined) ?? "",
    productId: d.productId as string,
  };
}

/** Status badge classes — maps status to the appropriate tc-badge modifier. */
export const STATUS_BADGE_CLASS: Record<OrderStatus, string> = {
  pending: "tc-badge",
  packed: "tc-badge",
  shipped: "tc-badge tc-badge--success",
  delivered: "tc-badge tc-badge--success",
  returned: "tc-badge tc-badge--danger",
};

/** Human-readable status labels. */
export const STATUS_LABELS: Record<OrderStatus, string> = {
  pending: "Pending",
  packed: "Packed",
  shipped: "Shipped",
  delivered: "Delivered",
  returned: "Returned",
};
