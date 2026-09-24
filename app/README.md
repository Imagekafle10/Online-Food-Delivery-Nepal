# Foodie — Black & Gold Food Delivery App

A Flutter customer app built against your **Multi Hotel/Restaurant/Cafe/Guest House** backend
(Node + TypeScript + Express + MySQL, from `migrations.zip`), focused on the
**online food ordering & delivery** flow specifically (table/room booking exist
in the API but are intentionally out of scope for this app).

## What's included

- **Black & gold theme** (`lib/theme/app_theme.dart`) applied app-wide — dark
  scaffold, gold accents on buttons/icons/highlights, gold gradient CTA.
- **Auth**: register/login (email OR phone, matches `POST /api/auth/register` & `/login`),
  JWT stored locally, auto-attached to every request.
- **Discover**: browse businesses with `has_food_ordering = true`, filter by
  type (restaurant/cafe/hotel/guest house), search.
- **Menu & cart**: category-grouped menu per business, add/remove items,
  single-business cart (the backend only allows one `business_id` per order).
- **Checkout**: saved delivery addresses, payment method (COD / eSewa / Khalti),
  order placed via `POST /api/orders` — pricing is always trusted from the
  server response, never computed client-side.
- **Order tracking**: status stepper mirroring the backend's status machine
  (`placed → accepted → preparing → ready → rider_assigned → on_the_way → delivered`),
  polling `GET /api/orders/:id` every 8s.
- **Order history**, **address book**, **profile/logout**.

## Wiring it to your backend

1. Run the Node backend from `migrations.zip` (`npm install`, apply
   `migrations/schema.sql`, `npm run dev`) — it listens on port 5000 by default.
2. Point the app at it in `lib/config/api_config.dart`, or pass at build/run time:
   ```bash
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api \
               --dart-define=SOCKET_URL=http://10.0.2.2:5000
   ```
   - Android emulator → host machine is `10.0.2.2`
   - iOS simulator → `localhost` works
   - Real device / production → your real host (use `https://` in prod)

## Getting started

This package ships the Dart source (`lib/`), `pubspec.yaml`, and `analysis_options.yaml`
only — no `android/`, `ios/`, or `web/` platform folders. Generate those once for your
machine, then drop these files in:

```bash
flutter create --org com.yourcompany --project-name foodie_black_gold .
# then copy/overwrite lib/, pubspec.yaml, analysis_options.yaml from this project
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
```

## Next steps / things intentionally left as extension points

- **Realtime tracking**: `socket_io_client` is already a dependency. Join
  room `order:<id>` (see backend `src/utils/socket.ts`) and listen for
  `order:status` / `rider:location` to replace polling with push updates and
  show a live rider map.
- **eSewa / Khalti checkout**: `PaymentService.initiate()` returns
  `formUrl`/`formFields` (eSewa) or `paymentUrl` (Khalti). Open these in a
  `webview_flutter` view and handle the redirect back to
  `/payments/esewa/success` / `/payments/khalti/callback`.
- **Business owner / rider apps**: this build is customer-only, as requested.
  The same `ApiClient`/models can seed a second Flutter target (or role-based
  routing off the JWT's `role` claim) for restaurant dashboards and rider apps.
- Menu item images, add-on selection UI, and reviews are modeled but kept
  minimal — extend `MenuItemTile` / `BusinessDetailScreen` as needed.
