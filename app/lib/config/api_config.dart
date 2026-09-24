/// Central place to point the app at your backend.
///
/// The backend in `migrations.zip` boots on `http://localhost:5000` and
/// mounts everything under `/api` (see src/app.ts / src/routes/index.ts).
///
/// - Android emulator -> use 10.0.2.2 instead of localhost
/// - iOS simulator    -> localhost works
/// - Physical device / production -> your real host, e.g. https://api.yourapp.com
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.18.201:5000/api',
  );

  // Socket.io server root (same host, no /api suffix — see src/utils/socket.ts)
  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'http://192.168.18.201:5000',
  );

  // Google Maps / Geocoding key. Never hardcode the real value here — pass
  // it at build/run time instead, e.g.:
  //   flutter run --dart-define=MAPS_API_KEY=your_key_here
  // or put it in a git-ignored dart-define file and use
  // --dart-define-from-file=maps.env.json
  static const String mapsApiKey = String.fromEnvironment('MAPS_API_KEY');
  // --- Auth ---
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';

  // --- Businesses ---
  static const String businesses = '/businesses';
  static String business(int id) => '/businesses/$id';

  // --- Menu ---
  static String menu(int businessId) => '/menu/$businessId';
  static const String menuSearch = '/menu/search';

  // --- Orders ---
  static const String orders = '/orders';
  static const String myOrders = '/orders/mine';
  static String order(int id) => '/orders/$id';
  static String orderStatus(int id) => '/orders/$id/status';
  static String orderCancel(int id) => '/orders/$id/cancel';

  // --- Delivery / rider tracking ---
  static const String deliveryPing = '/delivery/ping';
  static const String deliveryOnline = '/delivery/online';
  static const String deliveryOffline = '/delivery/offline';
  static const String deliveryMine = '/delivery/mine';
  static String deliveryPickedUp(int orderId) => '/delivery/$orderId/picked-up';
  static String deliveryOnTheWay(int orderId) =>
      '/delivery/$orderId/on-the-way';
  static String deliveryDelivered(int orderId) =>
      '/delivery/$orderId/delivered';

  // --- Addresses ---
  static const String addresses = '/addresses';
  static String address(int id) => '/addresses/$id';

  // --- Payments ---
  static const String paymentInitiate = '/payments/initiate';
  static String paymentStatus(String uuid) => '/payments/status/$uuid';
}
