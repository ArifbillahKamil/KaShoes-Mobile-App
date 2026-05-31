// Custom application exceptions.
/// These are thrown by data sources and caught by repositories,
/// which convert them into [Failure] objects.

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  ServerException(this.message, {this.statusCode});
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Network error occurred']);
}

class AuthException implements Exception {
  final String message;
  AuthException([this.message = 'Unauthorized']);
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'Cache error']);
}

class PermissionException implements Exception {
  final String message;
  PermissionException([this.message = 'Permission denied']);
}
