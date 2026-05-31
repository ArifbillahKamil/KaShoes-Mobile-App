import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/models/service_model.dart';

/// Order remote datasource.
/// Endpoints assumed:
///   GET  /api/orders          - list orders (paginated)
///   POST /api/orders          - create order
///   GET  /api/orders/{id}     - get order detail
///   GET  /api/layanan         - get services (also used in dashboard)
class OrderRemoteDatasource {
  final Dio _dio;
  OrderRemoteDatasource(this._dio);

  Future<List<OrderModel>> getOrders({int page = 1}) async {
    try {
      // TODO: Confirm endpoint and pagination params with backend team
      final response = await _dio.get('/orders', queryParameters: {
        'page': page,
        'per_page': 15,
      });
      final data = response.data;
      final List<dynamic> list = data is Map
          ? (data['data'] ?? data['orders'] ?? [])
          : (data as List<dynamic>);
      return list
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is AuthException) throw e.error as AuthException;
      throw NetworkException('Gagal memuat pesanan');
    }
  }

  Future<OrderModel> getOrderDetail(int orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId');
      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        return OrderModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return OrderModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AuthException) throw e.error as AuthException;
      throw NetworkException('Gagal memuat detail pesanan');
    }
  }

  Future<OrderModel> createOrder({
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required int serviceId,
    String? notes,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // TODO: Confirm exact field names with backend team
      final response = await _dio.post('/orders', data: {
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'customer_address': customerAddress,
        'service_id': serviceId,
        'notes': notes,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      });
      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        return OrderModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return OrderModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AuthException) throw e.error as AuthException;
      if (e.error is ServerException) throw e.error as ServerException;
      throw NetworkException('Gagal membuat pesanan');
    }
  }

  Future<List<ServiceModel>> getServices() async {
    try {
      // TODO: Confirm endpoint (/api/layanan or /api/services)
      final response = await _dio.get('/layanan');
      final data = response.data;
      final List<dynamic> list = data is Map
          ? (data['data'] ?? data['services'] ?? [])
          : (data as List<dynamic>);
      return list
          .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is AuthException) throw e.error as AuthException;
      throw NetworkException('Gagal memuat layanan');
    }
  }
}
