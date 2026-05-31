/// Form validation utility methods.
class AppValidators {
  AppValidators._();

  /// Returns error message if empty, otherwise null.
  static String? required(String? value, {String fieldName = 'Field ini'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    return null;
  }

  /// Validates email format.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email tidak boleh kosong';
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Format email tidak valid';
    return null;
  }

  /// Validates Indonesian phone number.
  /// Accepts: 08xx, +628xx, 628xx
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nomor telepon tidak boleh kosong';
    final cleaned = value.replaceAll(RegExp(r'[\s\-()]'), '');
    final phoneRegex = RegExp(r'^(\+62|62|0)[0-9]{8,12}$');
    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Format nomor telepon tidak valid (contoh: 08123456789)';
    }
    return null;
  }

  /// Validates password minimum length.
  static String? password(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) return 'Password tidak boleh kosong';
    if (value.length < minLength) return 'Password minimal $minLength karakter';
    return null;
  }

  /// Validates that password confirmation matches.
  static String? Function(String?) confirmPassword(String? original) {
    return (String? value) {
      if (value == null || value.isEmpty) return 'Konfirmasi password tidak boleh kosong';
      if (value != original) return 'Password tidak cocok';
      return null;
    };
  }

  /// Validates minimum text length.
  static String? minLength(String? value, int min, {String fieldName = 'Field ini'}) {
    if (value == null || value.isEmpty) return '$fieldName tidak boleh kosong';
    if (value.length < min) return '$fieldName minimal $min karakter';
    return null;
  }

  /// Combines multiple validators; returns first error or null.
  static String? Function(String?) compose(List<String? Function(String?)> validators) {
    return (value) {
      for (final v in validators) {
        final result = v(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}
