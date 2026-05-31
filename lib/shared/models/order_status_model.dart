/// Assumption: Status history model from order detail endpoint
/// API response shape:
/// {
///   "id": 1,
///   "order_id": 1,
///   "status": "pending",
///   "label": "Menunggu Konfirmasi",
///   "note": "Order masuk",
///   "created_at": "2025-01-01T10:00:00Z"
/// }
class OrderStatusModel {
  final int id;
  final int? orderId;
  final String status;
  final String? label;
  final String? note;
  final String? createdAt;

  const OrderStatusModel({
    required this.id,
    this.orderId,
    required this.status,
    this.label,
    this.note,
    this.createdAt,
  });

  factory OrderStatusModel.fromJson(Map<String, dynamic> map) {
    return OrderStatusModel(
      id: map['id'] as int,
      orderId: map['order_id'] as int?,
      status: map['status'] as String? ?? '',
      label: map['label'] as String?,
      note: map['note'] as String? ?? map['notes'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'status': status,
        'label': label,
        'note': note,
        'created_at': createdAt,
      };
}

/// Maps a status string to a display label in Indonesian.
String orderStatusLabel(String status) {
  const labels = {
    'pending': 'Menunggu Konfirmasi',
    'confirmed': 'Dikonfirmasi',
    'processing': 'Sedang Diproses',
    'diproses': 'Sedang Diproses',
    'ready': 'Siap Diambil',
    'completed': 'Selesai',
    'cancelled': 'Dibatalkan',
  };
  return labels[status.toLowerCase()] ?? status;
}

/// All possible order statuses in their logical progression order.
const List<String> orderStatusFlow = [
  'pending',
  'confirmed',
  'processing',
  'ready',
  'completed',
];
