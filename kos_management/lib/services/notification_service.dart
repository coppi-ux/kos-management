import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class NotificationService {
  Future<List<dynamic>> getOwnerNotifications(String token, int ownerId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/notifications/owner/$ownerId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data['notifications'];
    throw Exception(data['message']);
  }

  Future<int> getUnreadCount(String token, int ownerId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/notifications/owner/$ownerId/unread-count'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data['count'];
    return 0;
  }

  Future<void> markAllRead(String token, int ownerId) async {
    await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/notifications/owner/$ownerId/read-all'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<void> markRead(String token, int notificationId) async {
    await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/notifications/$notificationId/read'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}