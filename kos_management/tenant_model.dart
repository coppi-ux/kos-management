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

  factory TenantModel.fromJson(Map<String, dynamic> json, String token) {
    return TenantModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      roomNumber: json['room_number'],
      roomType: json['room_type'],
      basePrice: double.parse(json['base_price'].toString()),
      kosId: json['kos_id'],
      token: token,
    );
  }
}