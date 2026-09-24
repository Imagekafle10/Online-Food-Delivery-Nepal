# Bhansa — Restaurant Owner Panel (React)

Each **restaurant / cafe / hotel owner** logs in with their own email + password and can:

1. **CRUD menu items** (create, edit, delete, availability) for **their** business only  
2. **View order history** for their business  

**Paid / unpaid** and platform payment checks are for **super admin**, not this panel.

## Login

| Account | Password | Role |
|---------|----------|------|
| `owner@foodie.test` | `password123` | business_owner |

## Run

```bash
# API on :5000 with CLIENT_URL=http://localhost:5173
cd admin-api
npm install
npm run dev
```

`VITE_API_URL=http://localhost:5000/api` in `.env`

## Not in this panel

- Super admin (all businesses, approve/suspend, payment oversight) — separate UI later  
- Customer ordering app  

## Super admin (`super_admin` role)

Log in with the seeded admin account (`npm run seed:admin` in the API project — default `admin@bhansa.app`). The same panel switches to admin mode:

- **Restaurant search** (Restaurants and Menus pages) — find any restaurant / hotel / cafe (all statuses) by name, city, owner or phone and jump to it. The Menus page also has quick buttons for **User suspension monitor** (`/users`) and **Rider management** (`/riders`).
- **Restaurants** — searchable, filterable, paged list with owner, menu and order counts. Buttons: **Menu**, **Orders**, **Approve / Suspend**.
- **Menus** — add, edit, hide and delete any item; rename / delete categories. Items already used in past orders are hidden instead of deleted.
- **All orders** — every order on the platform with search + filters (status, type, payment, dates, restaurant). **View** opens the full order (customer, rider, items, payments, status history); **Delete** removes it (in-progress orders ask for a second confirmation).

- **Order statuses** — only `Accepted → Cooking → On the way → Delivered`, or `Cancelled` if there is a problem. Use the *Change to…* dropdown on **All orders** (or the buttons in the order view). Cancelling asks for a reason. Pickup / dine-in orders skip *On the way*.

Requires the updated API (run `migrations/002_simplify_order_status.sql` on an existing database once) (`/businesses/admin/all`, `/menu/:id/manage`, `/orders/admin/*`).
