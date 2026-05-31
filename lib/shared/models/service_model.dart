/// Assumption: Service model from GET /api/layanan
/// API response shape:
/// {
///   "id": 1,
///   "name": "Cuci Sepatu",
///   "description": "Cuci sepatu premium dengan bahan ramah lingkungan",
///   "price": 50000,
///   "icon": "cleaning",
///   "is_active": true
/// }
class ServiceModel {
  final int id;
  final String name;
  final String? description;
  final num? price;
  final String? icon;
  final bool isActive;

  const ServiceModel({
    required this.id,
    required this.name,
    this.description,
    this.price,
    this.icon,
    this.isActive = true,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      price: map['price'] as num?,
      icon: map['icon'] as String?,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'icon': icon,
        'is_active': isActive,
      };

  @override
  String toString() => 'ServiceModel(id: $id, name: $name)';
}
