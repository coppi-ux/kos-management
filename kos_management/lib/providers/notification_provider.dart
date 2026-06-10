import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<dynamic> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> fetchNotifications(String token, int ownerId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _notifications =
      await _service.getOwnerNotifications(token, ownerId);
      _unreadCount =
          _notifications.where((n) => n['is_read'] == 0).length;
    } catch (e) {
      debugPrint(e.toString());
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAllRead(String token, int ownerId) async {
    try {
      await _service.markAllRead(token, ownerId);
      // ✅ update locally without full refetch
      for (var n in _notifications) {
        n['is_read'] = 1;
      }
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}