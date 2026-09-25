# Flutter rider status fix + rider history + remember-me login

Aligns the mobile app with the current backend order lifecycle:

```
placed → accepted → cooking → on_the_way → delivered
```

## Files to replace in your Flutter project

Copy these over the matching paths under `lib/`:

| Fixed file | Copy to |
|---|---|
| `models/order.dart` | `lib/models/order.dart` |
| `models/rider_order.dart` | `lib/models/rider_order.dart` |
| `providers/rider_provider.dart` | `lib/providers/rider_provider.dart` |
| `screens/rider/rider_order_screen.dart` | `lib/screens/rider/rider_order_screen.dart` |
| `screens/rider/rider_deliveries_screen.dart` | `lib/screens/rider/rider_deliveries_screen.dart` |
| `screens/orders/order_history_screen.dart` | `lib/screens/orders/order_history_screen.dart` |
| `screens/orders/order_tracking_screen.dart` | `lib/screens/orders/order_tracking_screen.dart` |
| `widgets/order_status_stepper.dart` | `lib/widgets/order_status_stepper.dart` |
| `services/rider_service.dart` | `lib/services/rider_service.dart` |
| `screens/rider/rider_history_screen.dart` | `lib/screens/rider/rider_history_screen.dart` (**new file**) |
| `screens/rider/rider_home_screen.dart` | `lib/screens/rider/rider_home_screen.dart` |
| `services/auth_service.dart` | `lib/services/auth_service.dart` |
| `providers/auth_provider.dart` | `lib/providers/auth_provider.dart` |
| `screens/auth/login_screen.dart` | `lib/screens/auth/login_screen.dart` |
| `models/business.dart` | `lib/models/business.dart` |
| `screens/orders/rider_tracking_screen.dart` | `lib/screens/orders/rider_tracking_screen.dart` (**new file**) |
| `screens/orders/order_history_screen.dart` | `lib/screens/orders/order_history_screen.dart` |
| `screens/orders/order_tracking_screen.dart` | `lib/screens/orders/order_tracking_screen.dart` |

## What changed

### Status enum
- Removed: `preparing`, `ready`, `riderAssigned`, `pickedUp`, `completed`, `rejected`
- Kept / added: `placed`, `accepted`, `cooking`, `onTheWay`, `delivered`, `cancelled`
- `orderStatusFromString` still accepts legacy strings so old data doesn’t break

### Rider flow
| Backend status | Rider sees | Primary action |
|---|---|---|
| `accepted` / `cooking` | Navigate to **restaurant** | **PICKED UP FROM RESTAURANT** → calls `markPickedUp` → becomes `on_the_way` |
| `on_the_way` | Navigate to **customer** | **MARK AS DELIVERED** → calls `markDelivered` |

### Customer tracking
Simplified stages still work: Order placed → Cooking → On the way → Delivered.

## After applying

```bash
flutter clean
flutter pub get
flutter run
```

Then test:
1. Place a new delivery order (status `placed`)
2. Kitchen accepts → `accepted`
3. Assign rider (or wait for auto-assign)
4. Rider opens order → should see “Navigate to restaurant” + “PICKED UP FROM RESTAURANT”
5. Rider taps picked up → status becomes `on_the_way`, map switches to customer
6. Rider taps delivered → done

## New: rider order history

The backend has no "delivery history" endpoint, so completed deliveries are
recorded **on the device** the moment a rider taps "Mark as delivered"
(`RiderProvider.addToHistory`, persisted via `SharedPreferences`). A new
**History** tab sits between Deliveries and Profile on the rider bottom nav
(`rider_home_screen.dart` → `rider_history_screen.dart`) showing each past
delivery's order number, restaurant, customer, amount and when it finished,
with a "clear history" option in the app bar.

Because it's stored per-device rather than per-account on the server, it
won't follow the rider to a different phone, and (by design) it survives
logout/login on the same phone. If you'd rather have real server-side
history, that needs a new backend endpoint (e.g. `GET /delivery/history`
returning the rider's `delivered`/`cancelled` orders) — happy to wire that up
too if you share the backend route file.

## New: "Track Rider" from order history

Order history (and the order-detail/status screen) now has a **Track Rider**
button on any order that currently has a rider assigned (`accepted` /
`cooking` / `on_the_way` — see `FoodOrder.hasRiderAssigned`). It opens a new
live map screen, `rider_tracking_screen.dart`:

- Shows the restaurant, the delivery address, and the rider's live position
  as markers on an OpenStreetMap map (`flutter_map`, no Google Maps key
  needed — same library already used on the rider side).
- Shows the rider's name/phone if the backend includes them, with a tap-to-
  call button.
- For orders with no rider yet, or that are delivered/cancelled, it shows an
  explanatory state instead of an empty map.

**Important — this needs a live location feed, and there's no REST endpoint
for it.** The rider side only *sends* pings (`POST /delivery/ping`); nothing
in `api_config.dart` lets a customer *read* a rider's current position. So
this screen connects over **Socket.io** and listens for a `rider:location`
event after joining a room named `order:<id>` — that matches what was
already documented (but unused) in the original `order_tracking_screen.dart`
comment, referencing the backend's `src/utils/socket.ts`. If your backend's
actual join call or event/payload names differ, `_connectSocket()` in
`rider_tracking_screen.dart` is the only place to change — order status
polling keeps working either way, so a mismatched socket just means the map
marker won't move, nothing else breaks.

Two model changes support this and are backend-shape-defensive (won't crash
if your API doesn't send these fields, they'll just be null):
- `FoodOrder` gained `riderId` / `riderName` / `riderPhone` (read from either
  flat `rider_id`/`rider_name`/`rider_phone` columns or a nested `rider`
  object) and `deliveryLat` / `deliveryLng`.
- `Business` gained `latitude` / `longitude` — the `/businesses/:id`
  endpoint already returns these (the rider-side model was already reading
  them), the customer-side model just wasn't capturing them yet.

The shared login screen (used by both customer and rider logins) now saves
**every account you log into on that device**, not just one — like a
browser's saved passwords:

- On successful login, if "Remember this account on this device" is checked
  (on by default), the identifier + password are saved as an entry keyed by
  identifier (case-insensitive), so logging into a second account doesn't
  overwrite the first — `AuthService.saveAccount` in `auth_service.dart`.
- The login screen shows a **"Saved logins"** row of chips above the form —
  one per remembered account. Tapping a chip fills the identifier/password
  fields; the small ✕ on a chip forgets that one account
  (`AuthService.removeSavedAccount`) without touching the others.
- The most recently used account pre-fills the form automatically when the
  screen opens.
- Logging out does **not** forget any saved account, so they're still there
  next time — call `clearSavedAccounts()` from a "forget all" / shared-device
  option in Settings if you want that.
- If you're upgrading from the earlier single-slot version of this feature,
  `AuthService` migrates that one saved login into the new list
  automatically the first time `savedAccounts()` runs — nobody loses it.

**Security note:** passwords are still stored in plain text in
`SharedPreferences`, same as the rest of this app's local storage (e.g. the
cached user). Fine for a personal phone; on a shared/rooted device, swap the
prefs calls in `AuthService` for `flutter_secure_storage` (OS keychain /
keystore) instead — same method shapes, safer at rest.
