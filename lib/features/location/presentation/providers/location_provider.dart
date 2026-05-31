import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/datasources/location_datasource.dart';

// ─── State ─────────────────────────────────────────────────────────────────────

enum LocationSharingStatus { idle, requesting, sharing, error, stopped }

class LocationSharingState {
  final LocationSharingStatus status;
  final Position? currentPosition;
  final String? errorMessage;
  final DateTime? sharingStartedAt;

  const LocationSharingState({
    this.status = LocationSharingStatus.idle,
    this.currentPosition,
    this.errorMessage,
    this.sharingStartedAt,
  });

  bool get isSharing => status == LocationSharingStatus.sharing;

  Duration? get sharingDuration => sharingStartedAt != null
      ? DateTime.now().difference(sharingStartedAt!)
      : null;

  LocationSharingState copyWith({
    LocationSharingStatus? status,
    Position? currentPosition,
    String? errorMessage,
    DateTime? sharingStartedAt,
  }) {
    return LocationSharingState(
      status: status ?? this.status,
      currentPosition: currentPosition ?? this.currentPosition,
      errorMessage: errorMessage ?? this.errorMessage,
      sharingStartedAt: sharingStartedAt ?? this.sharingStartedAt,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class LocationSharingNotifier extends StateNotifier<LocationSharingState> {
  final LocationDatasource _datasource;
  final int orderId;

  LocationSharingNotifier(this._datasource, this.orderId)
      : super(const LocationSharingState());

  Future<void> startSharing() async {
    state = state.copyWith(status: LocationSharingStatus.requesting);

    await _datasource.startSharing(
      orderId: orderId,
      onPositionUpdate: (position) {
        state = state.copyWith(
          status: LocationSharingStatus.sharing,
          currentPosition: position,
          sharingStartedAt: state.sharingStartedAt ?? DateTime.now(),
        );
      },
      onError: (error) {
        state = state.copyWith(
          status: LocationSharingStatus.error,
          errorMessage: error,
        );
      },
    );

    if (state.status == LocationSharingStatus.requesting) {
      state = state.copyWith(status: LocationSharingStatus.sharing);
    }
  }

  Future<void> stopSharing() async {
    await _datasource.stopSharing();
    state = state.copyWith(status: LocationSharingStatus.stopped);
  }

  @override
  void dispose() {
    _datasource.dispose();
    super.dispose();
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final locationDatasourceProvider = Provider<LocationDatasource>((ref) {
  final datasource = LocationDatasource();
  ref.onDispose(() => datasource.dispose());
  return datasource;
});

final locationSharingProvider = StateNotifierProvider.family<
    LocationSharingNotifier, LocationSharingState, int>(
  (ref, orderId) {
    final datasource = ref.watch(locationDatasourceProvider);
    return LocationSharingNotifier(datasource, orderId);
  },
);
