import { useState, useEffect } from "react";
import { getSDK } from "../../../sdk";
import {
  type Order,
  type OrderStatus,
  toOrder,
  nextStatus,
  ORDER_STATUSES,
  DELIVERY_METHOD_LABELS,
  STATUS_BADGE_CLASS,
  STATUS_LABELS,
} from "../domain";

export function CourierDashboard() {
  // sdk is a stable singleton — intentionally not in useEffect dependency arrays
  const sdk = getSDK();

  const [orders, setOrders] = useState<Order[]>([]);
  const [products, setProducts] = useState<{ id: string; name: string; sku: string }[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<OrderStatus | "all">("all");

  useEffect(() => {
    async function load() {
      try {
        const [orderObjects, productsRaw] = await Promise.all([
          sdk.thisPlugin.objects.list("order"),
          sdk.hostApp.getProducts(),
        ]);
        setOrders(orderObjects.map(toOrder));
        const prods = productsRaw as { id: string; name: string; sku: string }[];
        setProducts(prods);
      } catch (err) {
        setError(err instanceof Error ? err.message : "Failed to load orders");
      } finally {
        setLoading(false);
      }
    }
    void load();
  }, []); // eslint-disable-line react-hooks/exhaustive-deps -- sdk is a stable singleton

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
        entityId: order.productId,
      });
      const updated = await sdk.thisPlugin.objects.list("order");
      setOrders(updated.map(toOrder));
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to update order status.");
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

  if (loading)
    return (
      <div className="tc-plugin" style={{ padding: "1rem" }}>
        Loading orders...
      </div>
    );

  const filteredOrders =
    statusFilter === "all" ? orders : orders.filter((o) => o.status === statusFilter);

  const productMap = new Map(products.map((p) => [p.id, p]));

  return (
    <div className="tc-plugin" style={{ padding: "1rem", maxWidth: 900 }}>
      <h1>Courier Dashboard</h1>

      {error && <p className="tc-error">{error}</p>}

      <div className="tc-flex" style={{ marginBottom: "1rem", alignItems: "center" }}>
        <label style={{ fontSize: "13px", fontWeight: 500 }}>
          Filter by status:{" "}
          <select
            className="tc-select"
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as OrderStatus | "all")}
          >
            <option value="all">All</option>
            {ORDER_STATUSES.map((s) => (
              <option key={s} value={s}>
                {STATUS_LABELS[s]}
              </option>
            ))}
          </select>
        </label>
        <span style={{ fontSize: "13px", color: "#64748b" }}>
          {filteredOrders.length} order{filteredOrders.length !== 1 ? "s" : ""}
        </span>
      </div>

      {filteredOrders.length === 0 ? (
        <p style={{ color: "#64748b" }}>
          No orders
          {statusFilter !== "all" ? ` with status "${STATUS_LABELS[statusFilter]}"` : ""} found.
        </p>
      ) : (
        <table className="tc-table">
          <thead>
            <tr>
              <th>Order #</th>
              <th>Product</th>
              <th>Status</th>
              <th>Method</th>
              <th>Locker Code</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {filteredOrders.map((order) => {
              const product = productMap.get(order.productId);
              return (
                <tr key={order.objectId}>
                  <td>{order.orderNumber}</td>
                  <td>{product ? `${product.name} (${product.sku})` : order.productId}</td>
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
                      <button
                        className="tc-ghost-button tc-ghost-button--danger"
                        onClick={() => void handleDeleteOrder(order)}
                      >
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      )}
    </div>
  );
}
