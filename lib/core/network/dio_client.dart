import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../errors/exceptions.dart';
import '../storage/token_storage.dart';

/// Creates and configures the Dio HTTP client with:
/// - Base URL from [AppConfig]
/// - Authorization token injection via [AuthInterceptor]
/// - Error response parsing via [ErrorInterceptor]
Dio createDioClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(milliseconds: AppConfig.connectTimeoutMs),
      receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeoutMs),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(),
    ErrorInterceptor(),
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      // Disable in production
      logPrint: (obj) => print('[DIO] $obj'),
    ),
  ]);

  return dio;
}

/// Injects Authorization Bearer token into every request.
class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await TokenStorage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Parses Dio errors into typed [ServerException] / [NetworkException] / [AuthException].
/// On 401, automatically clears the stored token.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: NetworkException('Koneksi timeout atau tidak ada internet.'),
            type: err.type,
          ),
        );
        return;

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final responseData = err.response?.data;
        final message = _extractMessage(responseData);

        if (statusCode == 401) {
          // Clear the stored token on 401
          await TokenStorage.deleteToken();
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: AuthException(message),
              type: err.type,
              response: err.response,
            ),
          );
          return;
        }

        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: ServerException(message, statusCode: statusCode),
            type: err.type,
            response: err.response,
          ),
        );
        return;

      default:
        handler.next(err);
    }
  }

  String _extractMessage(dynamic data) {
    if (data == null) return 'Terjadi kesalahan pada server.';
    if (data is Map) {
      // Laravel validation errors: {"message": "...", "errors": {...}}
      if (data.containsKey('message')) return data['message'].toString();
      if (data.containsKey('error')) return data['error'].toString();
    }
    return 'Terjadi kesalahan pada server.';
  }
}
