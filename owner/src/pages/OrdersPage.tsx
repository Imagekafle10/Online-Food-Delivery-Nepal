import { Fragment, useEffect, useMemo } from "react";
import { ChevronDown, ChevronRight } from "lucide-react";
import { useAppDispatch, useAppSelector } from "../hooks/redux";
import { Navigate } from "react-router-dom";
import AdminOrdersPage from "./AdminOrdersPage";
import {
  fetchBusinessOrders,
  fetchOrderItems,
  toggleOrderExpanded,
  setSearch,
} from "../features/orders/ordersSlice";

/**
 * Order history for restaurant owners.
 * Owners only need to know WHAT was ordered so they can prepare it — order
 * status and payment / paid-unpaid info are managed by the super admin and
 * are intentionally left out of this screen.
 */
export default function OrdersPage() {
  const role = useAppSelector((s) => s.auth.user?.role);
  return role === "super_admin" ? <AdminOrdersPage mode="active" /> : <OwnerOrdersPage />;
}

/** super_admin only: delivered + cancelled orders. Owners already have their own history at /orders. */
export function OrderHistoryPage() {
  const role = useAppSelector((s) => s.auth.user?.role);
  return role === "super_admin" ? <AdminOrdersPage mode="history" /> : <Navigate to="/orders" replace />;
}

function OwnerOrdersPage() {
  const dispatch = useAppDispatch();
  const selectedId = useAppSelector((s) => s.business.selectedId);
  const {
    list,
    search,
    loading,
    error,
    expandedOrderId,
    itemsByOrderId,
    itemsLoadingId,
  } = useAppSelector((s) => s.orders);

  useEffect(() => {
    if (selectedId) dispatch(fetchBusinessOrders({ businessId: selectedId }));
  }, [selectedId, dispatch]);

  // Load item breakdowns for every order up front so items are visible
  // directly in the table, without needing to click into each row.
  useEffect(() => {
    list.forEach((order) => {
      if (!itemsByOrderId[order.id] && !order.items) {
        dispatch(fetchOrderItems(order.id));
      }
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [list]);

  const filtered = useMemo(() => {
    const q = search.toLowerCase();
    if (!q) return list;
    return list.filter(
      (o) =>
        String(o.id).includes(q) ||
        String(o.order_number || "")
          .toLowerCase()
          .includes(q),
    );
  }, [list, search]);

  const handleToggle = (orderId: number) => {
    dispatch(toggleOrderExpanded(orderId));
    if (!itemsByOrderId[orderId]) {
      dispatch(fetchOrderItems(orderId));
    }
  };

  if (!selectedId) {
    return (
      <div>
        <div className="page-header">
          <h1>Order history</h1>
        </div>
        <div className="alert alert-info">
          Select your business from the top bar.
        </div>
      </div>
    );
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Order history</h1>
          <p>What’s been ordered from your restaurant · {list.length} total</p>
        </div>
        <button
          className="btn btn-ghost btn-sm"
          onClick={() =>
            dispatch(fetchBusinessOrders({ businessId: selectedId }))
          }
        >
          Refresh
        </button>
      </div>

      {error && <div className="alert alert-error">{error}</div>}

      <div className="filters-bar">
        <input
          className="input"
          placeholder="Search order #…"
          value={search}
          onChange={(e) => dispatch(setSearch(e.target.value))}
        />
      </div>

      <div className="card" style={{ padding: 0 }}>
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th style={{ width: 28 }} />
                <th>Order</th>
                <th>Items</th>
                <th>Total</th>
                <th>Placed</th>
              </tr>
            </thead>
            <tbody>
              {loading && (
                <tr>
                  <td colSpan={5} className="loading-row">
                    Loading…
                  </td>
                </tr>
              )}
              {!loading &&
                filtered.map((order) => {
                  const isOpen = expandedOrderId === order.id;
                  const items = itemsByOrderId[order.id] || order.items || [];
                  const itemsLoading = itemsLoadingId === order.id;
                  return (
                    <Fragment key={order.id}>
                      <tr
                        className="row-clickable"
                        onClick={() => handleToggle(order.id)}
                      >
                        <td>
                          {isOpen ? (
                            <ChevronDown size={16} />
                          ) : (
                            <ChevronRight size={16} />
                          )}
                        </td>
                        <td>
                          <strong className="gold-text">
                            {(order.order_number as string) || `#${order.id}`}
                          </strong>
                        </td>
                        <td className="muted">
                          {itemsLoading && items.length === 0 ? (
                            "Loading…"
                          ) : items.length > 0 ? (
                            <span className="order-item-summary">
                              {items
                                .map(
                                  (it) =>
                                    `${it.quantity}× ${
                                      it.name || it.item_name || "Item"
                                    }`,
                                )
                                .join(", ")}
                            </span>
                          ) : (
                            "No items"
                          )}
                        </td>
                        <td>
                          <strong>
                            Rs.{" "}
                            {Number(
                              order.total ?? order.total_amount ?? 0,
                            ).toFixed(2)}
                          </strong>
                        </td>
                        <td className="muted" style={{ fontSize: 13 }}>
                          {order.created_at
                            ? String(order.created_at).slice(0, 16)
                            : "—"}
                        </td>
                      </tr>
                      {isOpen && (
                        <tr>
                          <td />
                          <td colSpan={4} style={{ padding: "4px 16px 16px" }}>
                            {itemsLoading && (
                              <p className="muted" style={{ fontSize: 13 }}>
                                Loading items…
                              </p>
                            )}
                            {!itemsLoading && items.length === 0 && (
                              <p className="muted" style={{ fontSize: 13 }}>
                                No item breakdown available for this order.
                              </p>
                            )}
                            {!itemsLoading && items.length > 0 && (
                              <ul className="order-item-list">
                                {items.map((it, idx) => (
                                  <li key={it.id ?? idx}>
                                    <span className="order-item-qty">
                                      {it.quantity}×
                                    </span>
                                    <span>
                                      {it.name || it.item_name || "Item"}
                                    </span>
                                    {(it.notes || it.special_instructions) && (
                                      <span className="muted order-item-note">
                                        “{it.notes || it.special_instructions}”
                                      </span>
                                    )}
                                  </li>
                                ))}
                              </ul>
                            )}
                          </td>
                        </tr>
                      )}
                    </Fragment>
                  );
                })}
              {!loading && filtered.length === 0 && (
                <tr>
                  <td colSpan={5} className="loading-row">
                    No orders yet
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
