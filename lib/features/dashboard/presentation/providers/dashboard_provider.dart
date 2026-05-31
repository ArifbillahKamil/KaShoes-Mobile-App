import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/models/service_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';

// ─── Dashboard State ──────────────────────────────────────────────────────────

enum DashboardStatus { initial, loading, loaded, error }

class DashboardState {
  final DashboardStatus status;
  final UserModel? user;
  final List<OrderModel> recentOrders;
  final List<ServiceModel> services;
  final int activeOrderCount;
  final String? errorMessage;
  final bool isFromCache;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.user,
    this.recentOrders = const [],
    this.services = const [],
    this.activeOrderCount = 0,
    this.errorMessage,
    this.isFromCache = false,
  });

  DashboardState copyWith({
    DashboardStatus? status,
    UserModel? user,
    List<OrderModel>? recentOrders,
    List<ServiceModel>? services,
    int? activeOrderCount,
    String? errorMessage,
    bool? isFromCache,
  }) {
    return DashboardState(
      status: status ?? this.status,
      user: user ?? this.user,
      recentOrders: recentOrders ?? this.recentOrders,
      services: services ?? this.services,
      activeOrderCount: activeOrderCount ?? this.activeOrderCount,
      errorMessage: errorMessage ?? this.errorMessage,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }
}

// ─── Dashboard Notifier ────────────────────────────────────────────────────────

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardRemoteDatasource _datasource;

  DashboardNotifier(this._datasource) : super(const DashboardState());

  Future<void> load({bool forceRefresh = false}) async {
    state = state.copyWith(status: DashboardStatus.loading, errorMessage: null);

    // Load from cache first (if not forcing refresh)
    if (!forceRefresh) {
      await _loadFromCache();
    }

    try {
      // Fetch in parallel
      final results = await Future.wait([
        _datasource.getUser(),
        _datasource.getRecentOrders(),
        _datasource.getServices(),
      ]);

      final user = results[0] as UserModel;
      final orders = results[1] as List<OrderModel>;
      final services = results[2] as List<ServiceModel>;
      final activeCount = orders.where((o) => o.isActive).length;

      state = state.copyWith(
        status: DashboardStatus.loaded,
        user: user,
        recentOrders: orders.take(3).toList(),
        services: services,
        activeOrderCount: activeCount,
        isFromCache: false,
      );

      // Save to cache
      await _saveToCache(user, orders, services);
    } on AuthException {
      state = state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'Sesi telah berakhir. Silakan login kembali.',
      );
    } catch (e) {
      // If we have cache data, stay in loaded state (offline mode)
      if (state.user != null) {
        state = state.copyWith(
          status: DashboardStatus.loaded,
          isFromCache: true,
        );
      } else {
        state = state.copyWith(
          status: DashboardStatus.error,
          errorMessage: 'Gagal memuat data. Periksa koneksi internet Anda.',
        );
      }
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUser = prefs.getString('${AppConfig.dashboardCacheKey}_user');
      final cachedOrders = prefs.getString('${AppConfig.dashboardCacheKey}_orders');
      final cachedServices = prefs.getString('${AppConfig.dashboardCacheKey}_services');

      if (cachedUser != null) {
        final user = UserModel.fromJsonString(cachedUser);
        final orders = cachedOrders != null
            ? (jsonDecode(cachedOrders) as List)
                .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
                .toList()
            : <OrderModel>[];
        final services = cachedServices != null
            ? (jsonDecode(cachedServices) as List)
                .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
                .toList()
            : <ServiceModel>[];

        if (user != null) {
          state = state.copyWith(
            status: DashboardStatus.loaded,
            user: user,
            recentOrders: orders,
            services: services,
            activeOrderCount: orders.where((o) => o.isActive).length,
            isFromCache: true,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _saveToCache(
    UserModel user,
    List<OrderModel> orders,
    List<ServiceModel> services,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${AppConfig.dashboardCacheKey}_user', user.toJsonString());
      await prefs.setString(
        '${AppConfig.dashboardCacheKey}_orders',
        jsonEncode(orders.map((o) => o.toJson()).toList()),
      );
      await prefs.setString(
        '${AppConfig.dashboardCacheKey}_services',
        jsonEncode(services.map((s) => s.toJson()).toList()),
      );
    } catch (_) {}
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final dashboardDatasourceProvider = Provider<DashboardRemoteDatasource>((ref) {
  final dio = createDioClient();
  return DashboardRemoteDatasource(dio);
});

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final datasource = ref.watch(dashboardDatasourceProvider);
  return DashboardNotifier(datasource);
});
