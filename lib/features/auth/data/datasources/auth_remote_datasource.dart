import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/user_model.dart';

/// Assumption: Login endpoint POST /api/login
/// Request:  { "email": "...", "password": "..." }
/// Response: { "token": "...", "user": { ... } }
///
/// Register endpoint POST /api/register
/// Request:  { "name": "...", "email": "...", "phone": "...", "password": "...", "password_confirmation": "..." }
/// Response: { "token": "...", "user": { ... } }
///
/// Logout endpoint POST /api/logout
/// Response: { "message": "Logged out" }
///
/// Get current user GET /api/user
/// Response: { user data }
class AuthRemoteDatasource {
  final Dio _dio;
  AuthRemoteDatasource(this._dio);

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/login', data: {
        'email': email,
        'password': password,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.error is AuthException) throw e.error as AuthException;
      if (e.error is ServerException) throw e.error as ServerException;
      throw NetworkException(e.message ?? 'Network error during login');
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _dio.post('/register', data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.error is ServerException) throw e.error as ServerException;
      throw NetworkException(e.message ?? 'Network error during registration');
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/logout');
    } on DioException catch (e) {
      // Silently ignore logout errors (token may already be invalid)
      if (e.error is! AuthException) {
        throw NetworkException(e.message ?? 'Network error during logout');
      }
    }
  }

  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get('/user');
      final data = response.data;
      // Handle both { "user": {...} } and direct user object
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        return UserModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return UserModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AuthException) throw e.error as AuthException;
      throw NetworkException(e.message ?? 'Failed to load user data');
    }
  }
}
