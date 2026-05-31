import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/models/service_model.dart';
import '../../../../shared/models/user_model.dart';

/// Dashboard data aggregator.
/// NOTE: There may not be a dedicated /api/dashboard endpoint.
/// We fall back to fetching user + orders + services separately.
/// TODO: Confirm if /api/dashboard exists with backend team.
class DashboardRemoteDatasource {
  final Dio _dio;
  DashboardRemoteDatasource(this._dio);

  Future<UserModel> getUser() async {
    try {
      final response = await _dio.get('/user');
      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        return UserModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return UserModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AuthException) throw e.error as AuthException;
      throw NetworkException('Gagal memuat data pengguna');
    }
  }

  /// Fetch recent orders for the dashboard (first page, 5 items max)
  Future<List<OrderModel>> getRecentOrders() async {
    try {
      // TODO: Confirm endpoint and query params with backend team
      final response = await _dio.get('/orders', queryParameters: {
        'per_page': 5,
        'page': 1,
      });
      final data = response.data;
      final List<dynamic> list = data is Map ? (data['data'] ?? data['orders'] ?? []) : data;
      return list
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is AuthException) throw e.error as AuthException;
      throw NetworkException('Gagal memuat riwayat pesanan');
    }
  }

  /// Fetch all available services/layanan
  Future<List<ServiceModel>> getServices() async {
    try {
      // TODO: Confirm endpoint with backend team (may be /api/layanan or /api/services)
      final response = await _dio.get('/layanan');
      final data = response.data;
      final List<dynamic> list = data is Map ? (data['data'] ?? data['services'] ?? []) : data;
      return list
          .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is AuthException) throw e.error as AuthException;
      throw NetworkException('Gagal memuat daftar layanan');
    }
  }
}
