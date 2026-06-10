import '../services/notification_service.dart';

class NotificationRepository {
  final NotificationService _service = NotificationService();

  Future<List<dynamic>> getOwnerNotifications(
      String token, int ownerId) async {
    try {
      return await _service.getOwnerNotifications(token, ownerId);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<int> getUnreadCount(String token, int ownerId) async {
    try {
      return await _service.getUnreadCount(token, ownerId);
    } catch (e) {
      return 0;
    }
  }

  Future<void> markAllRead(String token, int ownerId) async {
    try {
      await _service.markAllRead(token, ownerId);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> markRead(String token, int notificationId) async {
    try {
      await _service.markRead(token, notificationId);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}