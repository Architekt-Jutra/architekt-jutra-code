import { useState, useEffect } from "react";
import { getSDK } from "../../../sdk";
import {
  type Order,
  type DeliveryMethod,
  toOrder,
  nextStatus,
  suggestDeliveryMethod,
  DELIVERY_METHODS,
  DELIVERY_METHOD_LABELS,
  STATUS_BADGE_CLASS,
  STATUS_LABELS,
} from "../domain";

export function ProductDeliveryTab() {
  // sdk is a stable singleton — intentionally not in useEffect dependency arrays
  const sdk = getSDK();
  const productId = sdk.thisPlugin.productId ?? "";

  const [orders, setOrders] = useState<Order[]>([]);
  const [suggestedMethod, setSuggestedMethod] = useState<DeliveryMethod | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [formOrderNumber, setFormOrderNumber] = useState("");
  const [formDeliveryMethod, setFormDeliveryMethod] = useState<DeliveryMethod>("parcel_locker");
  const [formLockerCode, setFormLockerCode] = useState("");
  const [formError, setFormError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!productId) {
      setLoading(false);
      return;
    }
    async function load() {
      try {
        const [orderObjects, productRaw] = await Promise.all([
          sdk.thisPlugin.objects.list("order", { entityType: "PRODUCT", entityId: productId }),
          sdk.hostApp.getProduct(productId),
        ]);
        setOrders(orderObjects.map(toOrder));

        const product = productRaw as {
          pluginData?: Record<string, { length: number; width: number; height: number }>;
        };
        const boxData = product.pluginData?.["box-size"] ?? null;
        // Use the local `suggested` variable, NOT the state variable `suggestedMethod`
        // (which would read the previous render's value and cause a stale-closure bug)
        const suggested = suggestDeliveryMethod(boxData);
        setSuggestedMethod(suggested);
        setFormDeliveryMethod(suggested ?? "parcel_locker");
      } catch (err) {
        setError(err instanceof Error ? err.message : "Failed to load delivery data");
      } finally {
        setLoading(false);
      }
    }
    void load();
  }, [productId]); // eslint-disable-line react-hooks/exhaustive-deps -- sdk is a stable singleton

  async function handleAddOrder() {
    setFormError(null);

    const trimmed = formOrderNumber.trim();
    if (!trimmed) {
      setFormError("Order number is required.");
      return;
    }
    const duplicate = orders.some(
      (o) => o.orderNumber.toLowerCase() === trimmed.toLowerCase()
    );
    if (duplicate) {
      setFormError(`Order number "${trimmed}" already exists for this product.`);
      return;
    }

    setSaving(true);
    try {
      const id = crypto.randomUUID();
      const data: Record<string, unknown> = {
        orderNumber: trimmed,
        status: "pending",
        deliveryMethod: formDeliveryMethod,
        productId,
      };
      if (formDeliveryMethod === "parcel_locker") {
        data.lockerCode = formLockerCode.trim();
      }
      await sdk.thisPlugin.objects.save("order", id, data, {
        entityType: "PRODUCT",
        entityId: productId,
      });
      setFormOrderNumber("");
      setFormLockerCode("");
      const updated = await sdk.thisPlugin.objects.list("order", {
        entityType: "PRODUCT",
        entityId: productId,
      });
      setOrders(updated.map(toOrder));
    } catch (err) {
      setFormError(err instanceof Error ? err.message : "Failed to add order.");
    } finally {
      setSaving(false);
    }
  }

  async function handleAdvanceStatus(order: Order) {
    const next = nextStatus(order.status);
    if (!next) return;
    setError(null);
    try {
      const data: Record<string, unknown> = {
        orderNumber: order.orderNumber,
        status: next,
        deliveryMethod: order.deliveryMethod,
        productId: order.productId,
      };
      if (order.deliveryMethod === "parcel_locker") {
        data.lockerCode = order.lockerCode;
      }
      await sdk.thisPlugin.objects.save("order", order.objectId, data, {
        entityType: "PRODUCT",
        entityId: productId,
      });
      const updated = await sdk.thisPlugin.objects.list("order", {
        entityType: "PRODUCT",
        entityId: productId,
      });
      setOrders(updated.map(toOrder));
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to update order status.");
    }
  }

  async function handleMarkReturned(order: Order) {
    // delivered → returned is intentionally blocked (V1 scope: delivered is terminal)
    if (order.status === "returned" || order.status === "delivered") return;
    setError(null);
    try {
      const data: Record<string, unknown> = {
        orderNumber: order.orderNumber,
        status: "returned",
        deliveryMethod: order.deliveryMethod,
        productId: order.productId,
      };
      if (order.deliveryMethod === "parcel_locker") {
        data.lockerCode = order.lockerCode;
      }
      await sdk.thisPlugin.objects.save("order", order.objectId, data, {
        entityType: "PRODUCT",
        entityId: productId,
      });
      const updated = await sdk.thisPlugin.objects.list("order", {
        entityType: "PRODUCT",
        entityId: productId,
      });
      setOrders(updated.map(toOrder));
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to mark order as returned.");
    }
  }

  async function handleDeleteOrder(order: Order) {
    setError(null);
    try {
      await sdk.thisPlugin.objects.delete("order", order.objectId);
      setOrders((prev) => prev.filter((o) => o.objectId !== order.objectId));
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to delete order.");
    }
  }

  if (!productId)
    return (
      <div className="tc-plugin" style={{ padding: "1rem" }}>
        No product context.
      </div>
    );
  if (loading)
    return (
      <div className="tc-plugin" style={{ padding: "1rem" }}>
        Loading...
      </div>
    );

  return (
    <div className="tc-plugin" style={{ padding: "1.5rem" }}>
      <h3 style={{ margin: "0 0 1rem" }}>Delivery Orders</h3>

      {error && <p className="tc-error">{error}</p>}

      {suggestedMethod && (
        <p style={{ marginBottom: "1rem", fontSize: "13px", color: "#475569" }}>
          Suggested delivery method based on box size:
          <strong> {DELIVERY_METHOD_LABELS[suggestedMethod]}</strong>
        </p>
      )}

      <section className="tc-section">
        <h4 style={{ margin: "0 0 0.75rem" }}>Add Order</h4>
        <div
          className="tc-flex"
          style={{ flexWrap: "wrap", alignItems: "flex-end", gap: "0.5rem" }}
        >
          <label
            style={{ display: "flex", flexDirection: "column", gap: "0.25rem", fontSize: "13px" }}
          >
            Order Number
            <input
              className="tc-input"
              type="text"
              placeholder="e.g. ORD-0042"
              value={formOrderNumber}
              onChange={(e) => setFormOrderNumber(e.target.value)}
              style={{ width: 140 }}
            />
          </label>
          <label
            style={{ display: "flex", flexDirection: "column", gap: "0.25rem", fontSize: "13px" }}
          >
            Delivery Method
            <select
              className="tc-select"
              value={formDeliveryMethod}
              onChange={(e) => {
                setFormDeliveryMethod(e.target.value as DeliveryMethod);
                setFormLockerCode("");
              }}
              style={{ width: 160 }}
            >
              {DELIVERY_METHODS.map((m) => (
                <option key={m} value={m}>
                  {DELIVERY_METHOD_LABELS[m]}
                </option>
              ))}
            </select>
          </label>
          {formDeliveryMethod === "parcel_locker" && (
            <label
              style={{
                display: "flex",
                flexDirection: "column",
                gap: "0.25rem",
                fontSize: "13px",
              }}
            >
              Locker Code
              <input
                className="tc-input"
                type="text"
                placeholder="e.g. ABC-123"
                value={formLockerCode}
                onChange={(e) => setFormLockerCode(e.target.value)}
                style={{ width: 120 }}
              />
            </label>
          )}
          <button
            className="tc-primary-button"
            onClick={() => void handleAddOrder()}
            disabled={saving}
            style={{ alignSelf: "flex-end" }}
          >
            {saving ? "Adding..." : "Add Order"}
          </button>
        </div>
        {formError && (
          <p className="tc-error" style={{ marginTop: "0.5rem" }}>
            {formError}
          </p>
        )}
      </section>

      {orders.length === 0 ? (
        <p style={{ color: "#64748b", fontSize: "13px" }}>No orders yet for this product.</p>
      ) : (
        <table className="tc-table">
          <thead>
            <tr>
              <th>Order #</th>
              <th>Status</th>
              <th>Method</th>
              <th>Locker Code</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {orders.map((order) => (
              <tr key={order.objectId}>
                <td>{order.orderNumber}</td>
                <td>
                  <span className={STATUS_BADGE_CLASS[order.status]}>
                    {STATUS_LABELS[order.status]}
                  </span>
                </td>
                <td>{DELIVERY_METHOD_LABELS[order.deliveryMethod]}</td>
                <td>
                  {order.deliveryMethod === "parcel_locker" ? order.lockerCode || "—" : "—"}
                </td>
                <td>
                  <div className="tc-flex">
                    {nextStatus(order.status) && (
                      <button
                        className="tc-ghost-button"
                        onClick={() => void handleAdvanceStatus(order)}
                      >
                        → {STATUS_LABELS[nextStatus(order.status)!]}
                      </button>
                    )}
                    {order.status !== "returned" && order.status !== "delivered" && (
                      <button
                        className="tc-ghost-button tc-ghost-button--danger"
                        onClick={() => void handleMarkReturned(order)}
                      >
                        Return
                      </button>
                    )}
                    <button
                      className="tc-ghost-button tc-ghost-button--danger"
                      onClick={() => void handleDeleteOrder(order)}
                    >
                      Delete
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
