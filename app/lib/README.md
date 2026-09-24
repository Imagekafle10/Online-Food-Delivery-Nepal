# Flutter rider status fix

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
