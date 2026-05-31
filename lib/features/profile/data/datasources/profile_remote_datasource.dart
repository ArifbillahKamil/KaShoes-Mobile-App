import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/user_model.dart';

/// Profile remote datasource.
/// Endpoints assumed:
///   GET   /api/user     - get current user profile
///   PATCH /api/profile  - update profile fields
///
/// TODO: Confirm PATCH endpoint (/api/profile or /api/user) with backend team
class ProfileRemoteDatasource {
  final Dio _dio;
  ProfileRemoteDatasource(this._dio);

  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get('/user');
      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        return UserModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return UserModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AuthException) throw e.error as AuthException;
      throw NetworkException('Gagal memuat profil');
    }
  }

  Future<UserModel> updateProfile({
    String? phone,
    String? address,
  }) async {
    try {
      // TODO: Confirm endpoint with backend team
      final response = await _dio.patch('/profile', data: {
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
      });
      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        return UserModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      if (data is Map<String, dynamic> && data.containsKey('user')) {
        return UserModel.fromJson(data['user'] as Map<String, dynamic>);
      }
      return UserModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AuthException) throw e.error as AuthException;
      if (e.error is ServerException) throw e.error as ServerException;
      throw NetworkException('Gagal memperbarui profil');
    }
  }
}
