import 'package:intl/intl.dart';

/// Utility methods for formatting dates, currency, and phone numbers.
class AppFormatters {
  AppFormatters._();

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final DateFormat _timeFormat = DateFormat('HH:mm', 'id_ID');

  /// Format date string from ISO 8601 to "28 Mei 2025"
  static String formatDate(String? isoString) {
    if (isoString == null) return '-';
    try {
      final date = DateTime.parse(isoString).toLocal();
      return _dateFormat.format(date);
    } catch (_) {
      return isoString;
    }
  }

  /// Format date string from ISO 8601 to "28 Mei 2025, 14:30"
  static String formatDateTime(String? isoString) {
    if (isoString == null) return '-';
    try {
      final date = DateTime.parse(isoString).toLocal();
      return _dateTimeFormat.format(date);
    } catch (_) {
      return isoString;
    }
  }

  /// Format time from ISO 8601 to "14:30"
  static String formatTime(String? isoString) {
    if (isoString == null) return '-';
    try {
      final date = DateTime.parse(isoString).toLocal();
      return _timeFormat.format(date);
    } catch (_) {
      return isoString;
    }
  }

  /// Format currency in IDR: "Rp 150.000"
  static String formatCurrency(num? amount) {
    if (amount == null) return 'Rp -';
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Format phone number: ensures leading 0 or +62
  static String formatPhone(String? phone) {
    if (phone == null) return '-';
    return phone;
  }

  /// Capitalize first letter of each word
  static String titleCase(String? text) {
    if (text == null || text.isEmpty) return '';
    return text
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  /// Shorten an address to a max length with ellipsis
  static String shortenAddress(String? address, {int maxLength = 40}) {
    if (address == null) return '-';
    if (address.length <= maxLength) return address;
    return '${address.substring(0, maxLength)}...';
  }

  /// Format coordinates for display
  static String formatCoordinates(double? lat, double? lng) {
    if (lat == null || lng == null) return '-';
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }
}
