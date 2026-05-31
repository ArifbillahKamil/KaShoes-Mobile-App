/// Base failure class for the app.
/// Every repository method returns either data or a [Failure].
sealed class Failure {
  final String message;
  const Failure(this.message);
}

/// Network connectivity failure (no internet, timeout, etc.)
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Tidak ada koneksi internet. Periksa jaringan Anda.']);
}

/// Server-side errors (4xx, 5xx)
class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});
}

/// Authentication failure (401 Unauthorized)
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Sesi Anda telah berakhir. Silakan login kembali.']);
}

/// Cache/local storage failure
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Gagal memuat data lokal.']);
}

/// Permission failure (e.g., location permission denied)
class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Izin ditolak. Aktifkan izin di pengaturan.']);
}

/// Unknown / unexpected failure
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Terjadi kesalahan yang tidak terduga.']);
}
