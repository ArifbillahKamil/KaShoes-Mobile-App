import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/models/service_model.dart';
import '../../data/datasources/order_remote_datasource.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final orderDatasourceProvider = Provider<OrderRemoteDatasource>((ref) {
  return OrderRemoteDatasource(createDioClient());
});

// ─── Services List Provider ───────────────────────────────────────────────────

final servicesProvider = FutureProvider<List<ServiceModel>>((ref) async {
  final datasource = ref.watch(orderDatasourceProvider);
  return datasource.getServices();
});

// ─── Orders List State ────────────────────────────────────────────────────────

enum OrderListStatus { initial, loading, loaded, loadingMore, error }

class OrderListState {
  final OrderListStatus status;
  final List<OrderModel> orders;
  final int currentPage;
  final bool hasMore;
  final String? errorMessage;

  const OrderListState({
    this.status = OrderListStatus.initial,
    this.orders = const [],
    this.currentPage = 1,
    this.hasMore = true,
    this.errorMessage,
  });

  List<OrderModel> get activeOrders => orders.where((o) => o.isActive).toList();
  List<OrderModel> get historyOrders => orders.where((o) => !o.isActive).toList();

  OrderListState copyWith({
    OrderListStatus? status,
    List<OrderModel>? orders,
    int? currentPage,
    bool? hasMore,
    String? errorMessage,
  }) {
    return OrderListState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class OrderListNotifier extends StateNotifier<OrderListState> {
  final OrderRemoteDatasource _datasource;

  OrderListNotifier(this._datasource) : super(const OrderListState());

  Future<void> load() async {
    state = state.copyWith(status: OrderListStatus.loading, errorMessage: null);
    try {
      final orders = await _datasource.getOrders(page: 1);
      state = state.copyWith(
        status: OrderListStatus.loaded,
        orders: orders,
        currentPage: 1,
        hasMore: orders.length >= 15,
      );
    } catch (e) {
      state = state.copyWith(
        status: OrderListStatus.error,
        errorMessage: 'Gagal memuat pesanan. Silakan coba lagi.',
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.status == OrderListStatus.loadingMore) return;
    state = state.copyWith(status: OrderListStatus.loadingMore);
    try {
      final nextPage = state.currentPage + 1;
      final newOrders = await _datasource.getOrders(page: nextPage);
      state = state.copyWith(
        status: OrderListStatus.loaded,
        orders: [...state.orders, ...newOrders],
        currentPage: nextPage,
        hasMore: newOrders.length >= 15,
      );
    } catch (_) {
      state = state.copyWith(status: OrderListStatus.loaded);
    }
  }
}

final orderListProvider = StateNotifierProvider<OrderListNotifier, OrderListState>((ref) {
  return OrderListNotifier(ref.watch(orderDatasourceProvider));
});

// ─── Order Detail Provider ────────────────────────────────────────────────────

final orderDetailProvider = FutureProvider.family<OrderModel, int>((ref, orderId) async {
  final datasource = ref.watch(orderDatasourceProvider);
  return datasource.getOrderDetail(orderId);
});

// ─── Create Order State ───────────────────────────────────────────────────────

enum CreateOrderStatus { idle, loading, success, error }

class CreateOrderState {
  final CreateOrderStatus status;
  final OrderModel? createdOrder;
  final String? errorMessage;
  final Position? currentPosition;
  final bool isGettingLocation;

  const CreateOrderState({
    this.status = CreateOrderStatus.idle,
    this.createdOrder,
    this.errorMessage,
    this.currentPosition,
    this.isGettingLocation = false,
  });

  CreateOrderState copyWith({
    CreateOrderStatus? status,
    OrderModel? createdOrder,
    String? errorMessage,
    Position? currentPosition,
    bool? isGettingLocation,
  }) {
    return CreateOrderState(
      status: status ?? this.status,
      createdOrder: createdOrder ?? this.createdOrder,
      errorMessage: errorMessage ?? this.errorMessage,
      currentPosition: currentPosition ?? this.currentPosition,
      isGettingLocation: isGettingLocation ?? this.isGettingLocation,
    );
  }
}

class CreateOrderNotifier extends StateNotifier<CreateOrderState> {
  final OrderRemoteDatasource _datasource;

  CreateOrderNotifier(this._datasource) : super(const CreateOrderState());

  /// Request GPS permission and get current location.
  Future<void> getCurrentLocation() async {
    state = state.copyWith(isGettingLocation: true, errorMessage: null);

    // Check permission
    final permission = await Permission.location.request();
    if (permission.isDenied || permission.isPermanentlyDenied) {
      state = state.copyWith(
        isGettingLocation: false,
        errorMessage: 'Izin lokasi diperlukan. Aktifkan di pengaturan.',
      );
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      state = state.copyWith(
        currentPosition: position,
        isGettingLocation: false,
      );
    } catch (e) {
      state = state.copyWith(
        isGettingLocation: false,
        errorMessage: 'Gagal mendapatkan lokasi. Pastikan GPS aktif.',
      );
    }
  }

  Future<void> submitOrder({
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required int serviceId,
    String? notes,
  }) async {
    state = state.copyWith(status: CreateOrderStatus.loading, errorMessage: null);
    try {
      final order = await _datasource.createOrder(
        customerName: customerName,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        serviceId: serviceId,
        notes: notes,
        latitude: state.currentPosition?.latitude,
        longitude: state.currentPosition?.longitude,
      );
      state = state.copyWith(
        status: CreateOrderStatus.success,
        createdOrder: order,
      );
    } catch (e) {
      state = state.copyWith(
        status: CreateOrderStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void reset() {
    state = const CreateOrderState();
  }
}

final createOrderProvider = StateNotifierProvider<CreateOrderNotifier, CreateOrderState>((ref) {
  return CreateOrderNotifier(ref.watch(orderDatasourceProvider));
});
