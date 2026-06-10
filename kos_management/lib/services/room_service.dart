import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class RoomService {
  // Get rooms by kos
  Future<List<dynamic>> getRooms(String token, int kosId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/rooms/$kosId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data['rooms'];
    throw Exception(data['message']);
  }

  // Create room
  Future<void> createRoom(String token, int kosId, int roomTypeId,
      String roomNumber) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/rooms'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'kos_id': kosId,
        'room_type_id': roomTypeId,
        'room_number': roomNumber,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 201) throw Exception(data['message']);
  }

  // Get tenants by kos
  Future<List<dynamic>> getTenants(String token, int kosId,
      {bool activeOnly = true}) async {
    final url = activeOnly
        ? '${ApiConfig.baseUrl}/rooms/tenants/$kosId'
        : '${ApiConfig.baseUrl}/rooms/tenants/$kosId?active=false';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data['tenants'];
    throw Exception(data['message']);
  }

  // Add tenant
  Future<void> addTenant(String token, String name, String email,
      String phone, int roomId, String startDate) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/rooms/tenants'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'room_id': roomId,
        'start_date': startDate,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 201) throw Exception(data['message']);
  }
}