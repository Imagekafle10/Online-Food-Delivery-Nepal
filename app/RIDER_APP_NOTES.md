# Rider mode (same Flutter app)

Copy `lib/` and `test/` over your project. **No pubspec changes needed** - it only
uses packages you already have (provider, http, shared_preferences, geolocator,
google_maps_flutter).

## How it works
- Register screen has a toggle: **Order food** / **Deliver as rider** (sends `role: "rider"`;
  the backend creates the `riders` row automatically).
- After login/splash, `homeForUser()` (lib/screens/home_router.dart) routes by `user.role`:
  `rider` -> RiderHomeScreen, everyone else -> the existing customer HomeScreen.
- Rider tabs: **Deliveries** (online switch + active jobs) and **Profile** (logout).
- Delivery detail: map (pickup + customer pin), items, cash-to-collect, and the
  Picked up -> Start delivery -> Delivered buttons.

## Backend endpoints used (no backend changes)
POST /delivery/online, /offline, /ping · GET /delivery/mine ·
POST /delivery/:id/picked-up, /on-the-way, /delivered ·
GET /orders/:id · GET /businesses/:id · /auth/*

## Testing it end to end
1. Register a rider account in the app (or POST /auth/register with role "rider").
2. Turn the switch ON (GPS permission needed - the backend only auto-assigns riders that have a location).
3. As a customer place a *delivery* order; as the business move it to `ready`.
   The nearest available rider is assigned automatically and shows up within ~6 s.

## Known backend gaps (worked around in the app)
- Assignment is automatic: there is no accept/reject step.
- The rider's `riders.id` is never returned to the client, so the app polls
  /delivery/mine every 6 s instead of joining the `rider:<id>` socket room.
- No rider profile / history / earnings endpoints, so those screens are not included.
- Cancelling an order does not free the rider server-side; the app re-calls
  /delivery/online when a job disappears so the rider isn't stuck "busy".
- Customer phone and address text aren't exposed to riders - only the map pin
  and delivery instructions are shown.
- GPS is shared only while the app is in the foreground (no background service).
