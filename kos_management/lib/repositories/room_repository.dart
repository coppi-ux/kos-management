import '../services/room_service.dart';

class RoomRepository {
  final RoomService _service = RoomService();

  Future<List<dynamic>> getRooms(String token, int kosId) async {
    try {
      return await _service.getRooms(token, kosId);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> createRoom(
      String token, int kosId, int roomTypeId, String roomNumber) async {
    try {
      await _service.createRoom(token, kosId, roomTypeId, roomNumber);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<List<dynamic>> getTenants(String token, int kosId,
      {bool activeOnly = true}) async {
    try {
      return await _service.getTenants(token, kosId, activeOnly: activeOnly);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> addTenant(String token, String name, String email,
      String phone, int roomId, String startDate) async {
    try {
      await _service.addTenant(token, name, email, phone, roomId, startDate);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}