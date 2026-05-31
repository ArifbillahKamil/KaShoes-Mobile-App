import 'order_status_model.dart';

/// Assumption: Order model from GET /api/orders and GET /api/orders/{id}
/// API response shape:
/// {
///   "id": 1,
///   "order_number": "KS-20250101-001",
///   "customer_name": "John Doe",
///   "customer_phone": "08123456789",
///   "customer_address": "Jl. Merdeka No. 1",
///   "service_id": 1,
///   "service_name": "Cuci Sepatu",
///   "notes": "Sepatu olahraga berwarna putih",
///   "status": "pending",
///   "latitude": -6.2088,
///   "longitude": 106.8456,
///   "created_at": "2025-01-01T10:00:00Z",
///   "updated_at": "2025-01-01T10:00:00Z",
///   "status_histories": [...]
/// }
class OrderModel {
  final int id;
  final String? orderNumber;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final int? serviceId;
  final String? serviceName;
  final String? notes;
  final String status;
  final double? latitude;
  final double? longitude;
  final String? createdAt;
  final String? updatedAt;
  final List<OrderStatusModel>? statusHistories;

  const OrderModel({
    required this.id,
    this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    this.serviceId,
    this.serviceName,
    this.notes,
    required this.status,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
    this.statusHistories,
  });

  /// Whether this order is still active (not completed/cancelled).
  bool get isActive => status == 'pending' || status == 'processing' || status == 'diproses';

  /// Whether this order has location data
  bool get hasLocation => latitude != null && longitude != null;

  factory OrderModel.fromJson(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] as int,
      orderNumber: map['order_number'] as String?,
      customerName: map['customer_name'] as String? ??
          map['name'] as String? ??
          '',
      customerPhone: map['customer_phone'] as String? ??
          map['phone'] as String? ??
          '',
      customerAddress: map['customer_address'] as String? ??
          map['address'] as String? ??
          '',
      serviceId: map['service_id'] as int?,
      serviceName: map['service_name'] as String? ??
          (map['service'] as Map<String, dynamic>?)?['name'] as String?,
      notes: map['notes'] as String? ?? map['description'] as String?,
      status: map['status'] as String? ?? 'pending',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
      statusHistories: (map['status_histories'] as List<dynamic>?)
          ?.map((e) => OrderStatusModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_number': orderNumber,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'customer_address': customerAddress,
        'service_id': serviceId,
        'service_name': serviceName,
        'notes': notes,
        'status': status,
        'latitude': latitude,
        'longitude': longitude,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  OrderModel copyWith({
    int? id,
    String? orderNumber,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    int? serviceId,
    String? serviceName,
    String? notes,
    String? status,
    double? latitude,
    double? longitude,
    String? createdAt,
    String? updatedAt,
    List<OrderStatusModel>? statusHistories,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      statusHistories: statusHistories ?? this.statusHistories,
    );
  }
}
