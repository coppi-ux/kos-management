// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class KosService {
  // ======================================================
  // Helper decode response body
  // ======================================================

  dynamic _decodeBody(http.Response response) {
    if (response.body.isEmpty) {
      return {};
    }

    try {
      return jsonDecode(response.body);
    } catch (e) {
      print("❌ JSON DECODE ERROR: $e");
      return {};
    }
  }

  // ======================================================
  // Helper handle error
  // Penting: return type Never supaya Dart tahu function ini
  // tidak akan pernah selesai normal, karena selalu throw Exception.
  // ======================================================

  Never _handleError(
      http.Response response,
      dynamic data,
      String defaultMessage,
      ) {
    if (response.statusCode == 401) {
      throw Exception("UNAUTHORIZED");
    }

    if (data is Map && data['message'] != null) {
      throw Exception(data['message']);
    }

    throw Exception(defaultMessage);
  }

  // ======================================================
  // CREATE KOS
  // POST /kos
  // ======================================================

  Future<Map<String, dynamic>> createKos(
      String token,
      String name,
      String address,
      ) async {
    print("👉 CREATE KOS");
    print("TOKEN: $token");
    print("URL: ${ApiConfig.baseUrl}/kos");

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/kos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'address': address,
      }),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    final data = _decodeBody(response);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    return _handleError(response, data, 'Failed to create kos');
  }

  // ======================================================
  // GET MY KOS
  // GET /kos/my
  // ======================================================

  Future<List<dynamic>> getMyKos(String token) async {
    print("👉 GET MY KOS");
    print("TOKEN: $token");
    print("URL: ${ApiConfig.baseUrl}/kos/my");

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/kos/my'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    final data = _decodeBody(response);

    if (response.statusCode == 200) {
      if (data is Map && data['kos'] != null) {
        return data['kos'];
      }

      if (data is Map && data['data'] != null) {
        return data['data'];
      }

      return [];
    }

    return _handleError(response, data, 'Failed to fetch kos');
  }

  // ======================================================
  // UPDATE KOS
  // PUT /kos/:kosId
  // ======================================================

  Future<Map<String, dynamic>> updateKos(
      String token,
      int kosId,
      String name,
      String address,
      ) async {
    print("👉 UPDATE KOS");
    print("TOKEN: $token");
    print("URL: ${ApiConfig.baseUrl}/kos/$kosId");

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/kos/$kosId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'address': address,
      }),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    final data = _decodeBody(response);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    return _handleError(response, data, 'Failed to update kos');
  }

  // ======================================================
  // DELETE KOS
  // DELETE /kos/:kosId
  // ======================================================

  Future<Map<String, dynamic>> deleteKos(
      String token,
      int kosId,
      ) async {
    print("👉 DELETE KOS");
    print("TOKEN: $token");
    print("URL: ${ApiConfig.baseUrl}/kos/$kosId");

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/kos/$kosId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    final data = _decodeBody(response);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    return _handleError(response, data, 'Failed to delete kos');
  }

  // ======================================================
  // GET ROOM TYPES
  // GET /kos/:kosId/room-types
  // ======================================================

  Future<List<dynamic>> getRoomTypes(
      String token,
      int kosId,
      ) async {
    print("👉 GET ROOM TYPES");
    print("TOKEN: $token");
    print("URL: ${ApiConfig.baseUrl}/kos/$kosId/room-types");

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/kos/$kosId/room-types'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    final data = _decodeBody(response);

    if (response.statusCode == 200) {
      if (data is Map && data['room_types'] != null) {
        return data['room_types'];
      }

      if (data is Map && data['data'] != null) {
        return data['data'];
      }

      return [];
    }

    return _handleError(response, data, 'Failed to fetch room types');
  }

  // ======================================================
  // CREATE ROOM TYPE
  // POST /kos/:kosId/room-types
  // ======================================================

  Future<Map<String, dynamic>> createRoomType(
      String token,
      int kosId,
      String name,
      double price,
      ) async {
    print("👉 CREATE ROOM TYPE");
    print("TOKEN: $token");
    print("URL: ${ApiConfig.baseUrl}/kos/$kosId/room-types");

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/kos/$kosId/room-types'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'base_price': price,
      }),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    final data = _decodeBody(response);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    return _handleError(response, data, 'Failed to create room type');
  }

  // ======================================================
  // UPDATE ROOM TYPE
  // PUT /kos/:kosId/room-types/:roomTypeId
  // ======================================================

  Future<Map<String, dynamic>> updateRoomType(
      String token,
      int kosId,
      int roomTypeId,
      String name,
      double price,
      ) async {
    print("👉 UPDATE ROOM TYPE");
    print("TOKEN: $token");
    print("URL: ${ApiConfig.baseUrl}/kos/$kosId/room-types/$roomTypeId");

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/kos/$kosId/room-types/$roomTypeId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'base_price': price,
      }),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    final data = _decodeBody(response);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    return _handleError(response, data, 'Failed to update room type');
  }

  // ======================================================
  // DELETE ROOM TYPE
  // DELETE /kos/:kosId/room-types/:roomTypeId
  // ======================================================

  Future<Map<String, dynamic>> deleteRoomType(
      String token,
      int kosId,
      int roomTypeId,
      ) async {
    print("👉 DELETE ROOM TYPE");
    print("TOKEN: $token");
    print("URL: ${ApiConfig.baseUrl}/kos/$kosId/room-types/$roomTypeId");

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/kos/$kosId/room-types/$roomTypeId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    final data = _decodeBody(response);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    return _handleError(response, data, 'Failed to delete room type');
  }
}