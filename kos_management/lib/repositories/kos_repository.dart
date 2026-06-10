import '../services/kos_service.dart';

class KosRepository {
  final KosService _service = KosService();

  // ======================================================
  // Helper error handler
  // ======================================================

  Exception _handleError(dynamic e) {
    final errorText = e.toString();

    if (errorText.contains("UNAUTHORIZED") ||
        errorText.contains("Unauthorized") ||
        errorText.contains("401")) {
      return Exception("UNAUTHORIZED");
    }

    return Exception(errorText.replaceAll('Exception: ', ''));
  }

  // ======================================================
  // GET MY KOS
  // GET /api/kos/my
  // ======================================================

  Future<List<dynamic>> getMyKos(String token) async {
    try {
      return await _service.getMyKos(token);
    } catch (e) {
      print("❌ REPO GET MY KOS ERROR: $e");
      throw _handleError(e);
    }
  }

  // ======================================================
  // CREATE KOS
  // POST /api/kos
  // ======================================================

  Future<Map<String, dynamic>> createKos(
      String token,
      String name,
      String address,
      ) async {
    try {
      return await _service.createKos(
        token,
        name,
        address,
      );
    } catch (e) {
      print("❌ REPO CREATE KOS ERROR: $e");
      throw _handleError(e);
    }
  }

  // ======================================================
  // UPDATE KOS
  // PUT /api/kos/:kosId
  // ======================================================

  Future<Map<String, dynamic>> updateKos(
      String token,
      int kosId,
      String name,
      String address,
      ) async {
    try {
      return await _service.updateKos(
        token,
        kosId,
        name,
        address,
      );
    } catch (e) {
      print("❌ REPO UPDATE KOS ERROR: $e");
      throw _handleError(e);
    }
  }

  // ======================================================
  // DELETE KOS
  // DELETE /api/kos/:kosId
  // ======================================================

  Future<Map<String, dynamic>> deleteKos(
      String token,
      int kosId,
      ) async {
    try {
      return await _service.deleteKos(
        token,
        kosId,
      );
    } catch (e) {
      print("❌ REPO DELETE KOS ERROR: $e");
      throw _handleError(e);
    }
  }

  // ======================================================
  // GET ROOM TYPES
  // GET /api/kos/:kosId/room-types
  // ======================================================

  Future<List<dynamic>> getRoomTypes(
      String token,
      int kosId,
      ) async {
    try {
      return await _service.getRoomTypes(
        token,
        kosId,
      );
    } catch (e) {
      print("❌ REPO GET ROOM TYPES ERROR: $e");
      throw _handleError(e);
    }
  }

  // ======================================================
  // CREATE ROOM TYPE
  // POST /api/kos/:kosId/room-types
  // ======================================================

  Future<Map<String, dynamic>> createRoomType(
      String token,
      int kosId,
      String name,
      double price,
      ) async {
    try {
      await _service.createRoomType(
        token,
        kosId,
        name,
        price,
      );

      return {
        "success": true,
        "message": "Room type created successfully",
      };
    } catch (e) {
      print("❌ REPO CREATE ROOM TYPE ERROR: $e");
      throw _handleError(e);
    }
  }

  // ======================================================
  // UPDATE ROOM TYPE
  // PUT /api/kos/:kosId/room-types/:roomTypeId
  // ======================================================

  Future<Map<String, dynamic>> updateRoomType(
      String token,
      int kosId,
      int roomTypeId,
      String name,
      double price,
      ) async {
    try {
      return await _service.updateRoomType(
        token,
        kosId,
        roomTypeId,
        name,
        price,
      );
    } catch (e) {
      print("❌ REPO UPDATE ROOM TYPE ERROR: $e");
      throw _handleError(e);
    }
  }

  // ======================================================
  // DELETE ROOM TYPE
  // DELETE /api/kos/:kosId/room-types/:roomTypeId
  // ======================================================

  Future<Map<String, dynamic>> deleteRoomType(
      String token,
      int kosId,
      int roomTypeId,
      ) async {
    try {
      return await _service.deleteRoomType(
        token,
        kosId,
        roomTypeId,
      );
    } catch (e) {
      print("❌ REPO DELETE ROOM TYPE ERROR: $e");
      throw _handleError(e);
    }
  }
}