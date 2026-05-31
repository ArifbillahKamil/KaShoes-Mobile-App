import 'dart:convert';

/// Assumption: User model matches Laravel Sanctum's typical user payload.
/// API response shape:
/// {
///   "id": 1,
///   "name": "John Doe",
///   "email": "john@example.com",
///   "phone": "08123456789",
///   "address": "Jl. Merdeka No. 1",
///   "is_member": true,
///   "created_at": "2025-01-01T00:00:00.000000Z"
/// }
class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final bool isMember;
  final String? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.isMember = false,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      // TODO: Confirm the field name for member status with backend team
      isMember: map['is_member'] as bool? ?? false,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'is_member': isMember,
        'created_at': createdAt,
      };

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    bool? isMember,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      isMember: isMember ?? this.isMember,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Serialize to JSON string for caching in shared_preferences
  String toJsonString() => jsonEncode(toJson());

  /// Deserialize from JSON string cached in shared_preferences
  static UserModel? fromJsonString(String? jsonString) {
    if (jsonString == null) return null;
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() => 'UserModel(id: $id, name: $name, email: $email, isMember: $isMember)';
}
