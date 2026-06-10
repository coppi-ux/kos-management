class TenantModel {
  final int id;
  final String name;
  final String email;
  final String roomNumber;
  final String roomType;
  final double basePrice;
  final int kosId;
  final String token;

  TenantModel({
    required this.id,
    required this.name,
    required this.email,
    required this.roomNumber,
    required this.roomType,
    required this.basePrice,
    required this.kosId,
    required this.token,
  });

  factory TenantModel.fromJson(Map<String, dynamic> tenantJson, String token) {
    return TenantModel(
      id: tenantJson['id'] as int,
      name: tenantJson['name'] as String,
      email: tenantJson['email'] as String,
      roomNumber: tenantJson['room_number'] as String,
      roomType: tenantJson['room_type'] as String,
      basePrice: double.parse(tenantJson['base_price'].toString()),
      kosId: tenantJson['kos_id'] as int,
      token: token,
    );
  }
}