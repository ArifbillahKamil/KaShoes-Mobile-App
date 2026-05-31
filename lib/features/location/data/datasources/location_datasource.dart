import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/storage/token_storage.dart';

/// Handles real-time GPS location broadcasting over WebSocket.
/// 
/// Assumption: The backend WebSocket accepts messages in this format:
/// {
///   "event": "location.update",
///   "channel": "location.{orderId}",
///   "data": {
///     "latitude": -6.2088,
///     "longitude": 106.8456,
///     "accuracy": 5.0,
///     "timestamp": "2025-01-01T10:00:00Z"
///   }
/// }
/// 
/// TODO: Confirm WebSocket channel format and event names with backend team.
/// If using Pusher/Laravel Echo, the channel may be "private-location.{orderId}"
class LocationDatasource {
  WebSocketChannel? _channel;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _broadcastTimer;
  bool _isSharing = false;

  bool get isSharing => _isSharing;

  Future<void> startSharing({
    required int orderId,
    required void Function(Position) onPositionUpdate,
    required void Function(String) onError,
  }) async {
    if (_isSharing) return;
    _isSharing = true;

    // Connect WebSocket
    try {
      final token = await TokenStorage.getToken();
      // TODO: Adjust WS URL format to match your Laravel WebSocket server
      final wsUrl = '${AppConfig.wsBaseUrl}?token=${token ?? ""}';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (data) {
          // Handle incoming messages (optional: for acknowledgements)
        },
        onError: (error) {
          onError('WebSocket error: $error');
        },
        onDone: () {
          if (_isSharing) onError('WebSocket connection closed');
        },
      );
    } catch (e) {
      // If WS connection fails, still track location locally (for display)
      // Broadcasting will silently fail but location will still show on map
    }

    // Start GPS tracking
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters moved
      ),
    ).listen(
      (position) {
        onPositionUpdate(position);
        _broadcastPosition(orderId, position);
      },
      onError: (error) {
        onError('GPS error: $error');
      },
    );
  }

  void _broadcastPosition(int orderId, Position position) {
    if (_channel == null) return;
    try {
      final message = jsonEncode({
        'event': 'location.update',
        'channel': 'location.$orderId',
        'data': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'timestamp': DateTime.now().toIso8601String(),
        },
      });
      _channel!.sink.add(message);
    } catch (_) {
      // Silently ignore broadcast errors
    }
  }

  Future<void> stopSharing() async {
    _isSharing = false;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    await _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    stopSharing();
  }
}
