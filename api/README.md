# Multi Hotel / Restaurant / Cafe / Guest House Management System — Backend

A multi-tenant backend for businesses (hotels, restaurants, cafes, guest houses) to manage:
- 🍔 **Online food ordering & delivery** (primary focus — full order lifecycle + rider assignment + live tracking)
- 🍽️ **Table booking** (restaurant/cafe dine-in reservations)
- 🛏️ **Room booking** (hotel/guest house, with date-range availability)
- 💳 **Payments**: eSewa, Khalti, and Cash on Delivery/Arrival (COD)

Stack: **Node.js + TypeScript + Express + MySQL**, layered as `routes → controllers → services → models`, matching the structure you asked for. Realtime updates (order status, rider GPS) run over **Socket.io**.

---

## 1. Setup

```bash
cd backend
npm install
cp .env.example .env      # fill in your MySQL credentials + gateway keys
```

Create the database schema:

```bash
mysql -u root -p < migrations/schema.sql
```

Already have a database from before the status change? Run `mysql -u root -p < migrations/002_simplify_order_status.sql` once instead (it converts existing orders to the new statuses).

Run in dev (auto-reload):

```bash
npm run dev
```

Build & run in production:

```bash
npm run build
npm start
```

Server starts on `http://localhost:5000` (change `PORT` in `.env`). Health check: `GET /api/health`.

Create the super_admin account (no `super_admin` can self-register via `/auth/register`):

```bash
npm run seed:admin
```

Default credentials are `admin@bhansa.app` / `Bhansa@Admin2026!` — override with `ADMIN_EMAIL` / `ADMIN_PASSWORD` / `ADMIN_NAME` env vars, or edit `scripts/seed-admin.ts`. Change the password after first login.

---

## 2. Folder structure

```
backend/
  src/
    config/        # db pool, env loader
    types/          # shared TS types (roles, order status, etc.)
    utils/          # jwt/hashing, response helpers, AppError, socket.io
    middlewares/     # auth (JWT), role guard, validation, error handler
    models/          # raw-SQL data access (one file per table group)
    services/        # business logic (order pricing, rider assignment, payments...)
    controllers/     # thin HTTP handlers — call services, return response
    routes/          # express routers, one per resource + routes/index.ts mount
    app.ts           # express app (middleware pipeline)
    server.ts        # boots HTTP server + socket.io + DB check
  migrations/
    schema.sql       # full MySQL schema
  .env.example
```

This mirrors your reference project's layering (routes → controllers → services → models), just built fresh for a multi-tenant delivery-first platform rather than extending the original.

---

## 3. Core concepts

### Multi-tenant businesses
One `users` table holds everyone (customers, business owners, staff, riders, super admins — see `role` enum). Each **business** (`businesses` table) has a `type`: `hotel | restaurant | cafe | guest_house`, and feature flags (`has_food_ordering`, `has_table_booking`, `has_room_booking`) so a guest house can skip tables, a cafe can skip rooms, etc. New businesses register as `pending` and a `super_admin` approves them (`PATCH /api/businesses/:id/approve`).

### Food ordering & delivery (primary flow)
1. Customer browses `GET /api/menu/:businessId`, adds items, `POST /api/orders` with `order_type: delivery|pickup|dine_in`.
2. Order pricing (subtotal, 13% tax, delivery fee, total) is computed server-side in `order.service.ts` — never trust client-sent totals.
3. Order statuses are just **`accepted` → `cooking` → `on_the_way` → `delivered`**, or **`cancelled`** if there is a problem. A new order starts as `accepted`. Change it with `PATCH /api/orders/:id/status { status, note }` — the state machine (`ALLOWED_TRANSITIONS` in `order.service.ts`) blocks illegal jumps. Pickup / dine-in orders skip `on_the_way` (`cooking → delivered`).
4. The moment a delivery order goes to `cooking`, `DeliveryService.autoAssignRider` finds the nearest **available** rider by Haversine distance and links them to the order (assigning a rider does not change the status). Dispatchers can also assign manually.
5. Rider flow: `POST /api/delivery/online` → gets a job → `.../picked-up` (order becomes `on_the_way`) → `.../delivered`. Rider GPS pings (`POST /api/delivery/ping`) broadcast over the `order:<id>` socket room for live map tracking, and are also stored in `rider_location_pings` for a path history.
6. Every status change is logged to `order_status_log` for a full audit trail / order tracking screen.

### Table booking
`POST /api/tables/bookings` tries to auto-assign a free table matching party size; if none is free right now it still books as `pending` so staff can seat/reassign manually. Status flow: `pending → confirmed → seated → completed` (or `cancelled` / `no_show`).

### Room booking
`GET /api/rooms/:businessId/rooms/available?check_in=YYYY-MM-DD&check_out=YYYY-MM-DD` returns only rooms with **no overlapping booking** for that date range (checked in `room.model.ts#isAvailable`). Booking computes `nights × price_per_night` server-side.

### Payments (eSewa / Khalti / COD)
`POST /api/payments/initiate { reference_type: "order"|"room_booking", reference_id, method }`:
- **cod** → marks payment `pending`, settled as `paid` automatically when a rider marks an order `delivered` (or staff can do it for room bookings).
- **esewa** → returns a signed form (`formUrl` + `formFields`) your frontend POSTs to eSewa's hosted page (v2 ePay, HMAC-SHA256 signed). eSewa redirects back to `GET /api/payments/esewa/success?data=...`, which verifies the signature and updates the order/booking.
- **khalti** → calls Khalti's `epayment/initiate/` and returns `paymentUrl` to redirect the user to. Khalti redirects back to `GET /api/payments/khalti/callback?pidx=...`, which is verified via `epayment/lookup/`.

Fill the real merchant/secret keys for both gateways in `.env` before going live — the ones shipped are the public eSewa **test/sandbox** credentials.

---

## 4. Key endpoints (see `src/routes/*.ts` for the full list)

| Area | Endpoint |
|---|---|
| Auth | `POST /api/auth/register`, `POST /api/auth/login`, `GET /api/auth/me` |
| Businesses | `GET /api/businesses`, `POST /api/businesses`, `PATCH /api/businesses/:id` |
| Menu | `GET /api/menu/:businessId`, `POST /api/menu/:businessId/items` |
| Orders | `POST /api/orders`, `GET /api/orders/mine`, `PATCH /api/orders/:id/status` |
| Delivery | `POST /api/delivery/online`, `POST /api/delivery/:orderId/picked-up`, `POST /api/delivery/ping` |
| Tables | `POST /api/tables/bookings`, `GET /api/tables/bookings/mine` |
| Rooms | `GET /api/rooms/:businessId/rooms/available`, `POST /api/rooms/bookings` |
| Payments | `POST /api/payments/initiate`, `GET /api/payments/esewa/success`, `GET /api/payments/khalti/callback` |

All protected routes need `Authorization: Bearer <accessToken>` from login/register.

### Super admin controls
A `super_admin` can now manage **any** business (menu, orders, tables, rooms, business details) without owning it, plus:

| What | Endpoint |
|---|---|
| Search all restaurants/hotels/cafes (any status, with owner + menu/order counts) | `GET /api/businesses/admin/all?search=&status=&type=&city=&limit=&offset=` |
| Edit a business (also `status`, `commission_percent`) | `PATCH /api/businesses/:id` |
| Full menu incl. hidden items/categories | `GET /api/menu/:businessId/manage` |
| Add / edit / delete menu item | `POST` / `PATCH` / `DELETE /api/menu/:businessId/items[/:itemId]` |
| Toggle item availability | `PATCH /api/menu/:businessId/items/:itemId/availability` |
| Add / edit / delete category | `POST` / `PATCH` / `DELETE /api/menu/:businessId/categories[/:categoryId]` |
| List all orders (filter: `search`, `status`, `business_id`, `order_type`, `payment_status`, `from`, `to`, `limit`, `offset`) | `GET /api/orders/admin/all` |
| View one order (customer, business, rider, address, items, status log, payments) | `GET /api/orders/admin/:id` |
| Delete an order (`?force=true` needed if it is still in progress) | `DELETE /api/orders/admin/:id` |

Notes: deleting a menu item that already appears in past orders hides it (`is_available = 0`) instead of deleting it, so order history stays intact. Deleting an order removes its items and status log but keeps `payments` rows for accounting.

---

## 5. Realtime (Socket.io)

Connect to the same server; join rooms to receive events:
- `join` with `order:<id>` → `order:status`, `rider:location`
- `join` with `business:<id>` → `order:new`, `order:status`, `booking:new_table`, `booking:new_room`
- `join` with `rider:<id>` → `delivery:assigned`

---

## 6. Notes / next steps for the Flutter app
- Use the `role` on the JWT to route users into Customer / Business Owner / Rider dashboards.
- The nearest-rider matching (`RiderModel.findNearestAvailable`) is a simple Haversine query — fine for a single city's launch; swap for a geo-index (Redis GEO / MySQL spatial index) once rider volume grows.
- `zod` and a `validate` middleware are wired in (`middlewares/validate.middleware.ts`) — add per-route schemas as you harden input validation.
- Add a file-upload route (multer is already a dependency) for menu item photos / business logos if you want images hosted here rather than S3/Cloudinary.
