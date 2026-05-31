/// KaShoes App Configuration
/// Update [baseUrl] to match your Laravel backend URL.
/// For Android Emulator testing: use 'http://10.0.2.2:8000'
/// For real device testing: use your machine's local IP e.g. 'http://192.168.1.x:8000'
/// For production: use your actual domain e.g. 'https://api.kashoes.com'
class AppConfig {
  AppConfig._();

  // ─── API ─────────────────────────────────────────────────────────────────
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const String apiVersion = '/api';
  static const String apiBaseUrl = '$baseUrl$apiVersion';

  // ─── WebSocket ────────────────────────────────────────────────────────────
  // TODO: Confirm WebSocket URL with backend team.
  // If using laravel-websockets or soketi:
  static const String wsBaseUrl = 'ws://10.0.2.2:6001/app/kashoes-key';
  // If using Pusher, replace with: wss://ws-ap1.pusher.com/app/{YOUR_KEY}

  // ─── Pusher (optional) ───────────────────────────────────────────────────
  // If you use Pusher, fill these in and switch the location datasource.
  static const String pusherAppKey = 'kashoes-key';
  static const String pusherCluster = 'ap1';

  // ─── Location Broadcast ──────────────────────────────────────────────────
  /// How often (in seconds) to broadcast GPS coordinates when sharing location
  static const int locationBroadcastIntervalSeconds = 10;

  // ─── Cache ────────────────────────────────────────────────────────────────
  static const String dashboardCacheKey = 'dashboard_cache';
  static const String tokenKey = 'auth_token';
  static const String userCacheKey = 'user_cache';

  // ─── Timeouts ─────────────────────────────────────────────────────────────
  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 15000;
}
