/// Central place to point the app at your backend.
///
/// Pick the server at run/build time with a dart-define file:
///   flutter run --dart-define-from-file=env.local.json
///   flutter run --dart-define-from-file=env.live.json
/// With no file, the app uses the live server below.
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://online-food-delivery-nepal.onrender.com/api',
  );

  // Socket.io server root (same host, no /api suffix)
  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'https://online-food-delivery-nepal.onrender.com',
  );

  // Google Maps / Geocoding key. Never hardcode it; pass it in the env file.
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
