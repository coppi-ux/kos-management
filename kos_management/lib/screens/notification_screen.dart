import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'billing_screen.dart';

class NotificationScreen extends StatefulWidget {
  final int ownerId;
  final String token;

  const NotificationScreen({
    super.key,
    required this.ownerId,
    required this.token,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final Color primaryGreen = const Color(0xFF34D399);
  final Color darkGreen = const Color(0xFF0F3D2E);

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    debugPrint('NOTIFICATION OWNER ID: ${widget.ownerId}');
    debugPrint('NOTIFICATION BASE URL: ${ApiConfig.baseUrl}');

    _fetchNotifications();
  }

  List<Map<String, dynamic>> _parseNotifications(dynamic data) {
    dynamic rawNotifications;

    if (data is Map<String, dynamic>) {
      rawNotifications = data['notifications'] ?? data['data'] ?? [];
    } else if (data is List) {
      rawNotifications = data;
    } else {
      rawNotifications = [];
    }

    if (rawNotifications is! List) {
      return [];
    }

    final parsedNotifications = rawNotifications
        .map<Map<String, dynamic>>((item) {
      if (item is Map<String, dynamic>) {
        return item;
      }

      if (item is Map) {
        return Map<String, dynamic>.from(item);
      }

      return <String, dynamic>{};
    })
        .where((item) => item.isNotEmpty)
        .toList();

    final paymentNotifications = parsedNotifications.where((notification) {
      final type = (notification['type'] ?? '').toString();

      return type == 'payment_requested' ||
          type == 'payment_paid' ||
          type == 'bill_paid' ||
          type == 'paid';
    }).toList();

    return paymentNotifications;
  }

  bool _isRead(dynamic value) {
    if (value == 1) return true;
    if (value == true) return true;
    if (value == '1') return true;
    if (value == 'true') return true;

    return false;
  }

  int? _toInt(dynamic value) {
    return int.tryParse(value?.toString() ?? '');
  }

  int? _extractKosId(Map<String, dynamic> notification) {
    return _toInt(
      notification['kos_id'] ??
          notification['kosId'] ??
          notification['kosID'] ??
          notification['boarding_house_id'] ??
          notification['boardingHouseId'] ??
          notification['property_id'] ??
          notification['propertyId'],
    );
  }

  Future<void> _fetchNotifications() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/notifications/owner/${widget.ownerId}',
      );

      debugPrint('Fetching notifications from: $url');

      final response = await http
          .get(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      )
          .timeout(
        const Duration(seconds: 12),
      );

      debugPrint('Notification status: ${response.statusCode}');
      debugPrint('Notification body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final parsedNotifications = _parseNotifications(decoded);

        setState(() {
          _notifications = parsedNotifications;
        });
      } else {
        setState(() {
          _notifications = [];
        });

        _showSnackBar(
          'Failed to load payment notifications. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Notification fetch error detail: $e');

      if (!mounted) return;

      setState(() {
        _notifications = [];
      });

      _showSnackBar(
        'Failed to load payment notifications. Please check your connection or server.',
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/notifications/owner/${widget.ownerId}/read-all',
      );

      debugPrint('Mark all read URL: $url');

      final response = await http
          .patch(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      )
          .timeout(
        const Duration(seconds: 12),
      );

      debugPrint('Mark read status: ${response.statusCode}');
      debugPrint('Mark read body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _notifications = _notifications.map((notification) {
            return {
              ...notification,
              'is_read': 1,
            };
          }).toList();
        });

        _showSnackBar('All payment notifications marked as read.');
      } else {
        _showSnackBar(
          'Failed to mark payment notifications. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Mark read error: $e');

      if (!mounted) return;

      _showSnackBar('Failed to mark payment notifications as read.');
    }
  }

  Future<void> _markSingleReadLocal(Map<String, dynamic> notification) async {
    final notificationId = notification['id'];

    if (notificationId == null) {
      return;
    }

    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/notifications/$notificationId/read',
      );

      debugPrint('Mark single notification read URL: $url');

      final response = await http
          .patch(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      )
          .timeout(
        const Duration(seconds: 12),
      );

      debugPrint('Mark single read status: ${response.statusCode}');
      debugPrint('Mark single read body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _notifications = _notifications.map((item) {
            if (item['id'] == notificationId) {
              return {
                ...item,
                'is_read': 1,
              };
            }

            return item;
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Mark single read error: $e');
    }
  }

  Future<void> _openBillingPage(Map<String, dynamic> notification) async {
    final type = (notification['type'] ?? '').toString();
    final billId = notification['bill_id'];
    final kosId = _extractKosId(notification);

    debugPrint('OPEN BILLING FROM NOTIFICATION');
    debugPrint('TYPE: $type');
    debugPrint('BILL ID: $billId');
    debugPrint('KOS ID: $kosId');
    debugPrint('RAW NOTIFICATION: $notification');

    if (kosId == null) {
      _showSnackBar(
        'Cannot open Billing because kos_id is missing from notification data.',
      );
      return;
    }

    await _markSingleReadLocal(notification);

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BillingScreen(
          kosId: kosId,
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'payment_requested':
        return Icons.pending_actions_rounded;
      case 'payment_paid':
      case 'bill_paid':
      case 'paid':
        return Icons.check_circle_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'payment_requested':
        return const Color(0xFFFFB74D);
      case 'payment_paid':
      case 'bill_paid':
      case 'paid':
        return const Color(0xFF34D399);
      default:
        return const Color(0xFF60A5FA);
    }
  }

  String _getDefaultTitle(String type) {
    switch (type) {
      case 'payment_requested':
        return 'Payment Confirmation Needed';
      case 'payment_paid':
      case 'bill_paid':
      case 'paid':
        return 'Payment Received';
      default:
        return 'Payment Notification';
    }
  }

  String _getStatusLabel(String type) {
    switch (type) {
      case 'payment_requested':
        return 'Waiting Confirmation';
      case 'payment_paid':
      case 'bill_paid':
      case 'paid':
        return 'Paid';
      default:
        return 'Payment';
    }
  }

  String _formatDate(dynamic value) {
    final raw = value?.toString() ?? '';

    if (raw.isEmpty || raw == 'null') {
      return '';
    }

    if (raw.length >= 16) {
      return raw.substring(0, 16);
    }

    return raw;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF071B14),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _blurCircle({
    required double size,
    required Color color,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((notification) {
      return !_isRead(notification['is_read']);
    }).length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: darkGreen,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(82),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 38,
                  sigmaY: 38,
                ),
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.30),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.18),
                        blurRadius: 1,
                        offset: const Offset(0, -0.5),
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.22),
                        Colors.white.withOpacity(0.13),
                        Colors.white.withOpacity(0.08),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 6,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                          splashRadius: 20,
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Payment Notifications',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: Colors.white,
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3B30),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.65),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF3B30)
                                        .withOpacity(0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                unreadCount > 9 ? '9+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          child: GestureDetector(
                            onTap: _markAllRead,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: primaryGreen.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: primaryGreen.withOpacity(0.34),
                                ),
                              ),
                              child: const Text(
                                'Read',
                                style: TextStyle(
                                  color: Color(0xFFB8FFE2),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: darkGreen,
          ),
          Positioned(
            top: -120,
            left: -90,
            child: _blurCircle(
              size: 310,
              color: const Color(0xFF6EE7B7).withOpacity(0.55),
            ),
          ),
          Positioned(
            top: 130,
            right: -130,
            child: _blurCircle(
              size: 390,
              color: const Color(0xFF22C55E).withOpacity(0.45),
            ),
          ),
          Positioned(
            bottom: 70,
            left: -140,
            child: _blurCircle(
              size: 360,
              color: const Color(0xFF10B981).withOpacity(0.42),
            ),
          ),
          Positioned(
            bottom: -130,
            right: -90,
            child: _blurCircle(
              size: 340,
              color: const Color(0xFFA7F3D0).withOpacity(0.35),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 75,
                sigmaY: 75,
              ),
              child: Container(
                color: Colors.white.withOpacity(0.015),
              ),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator.adaptive(
                backgroundColor: Colors.white,
              ),
            )
                : RefreshIndicator(
              color: primaryGreen,
              backgroundColor: darkGreen,
              onRefresh: _fetchNotifications,
              child: _notifications.isEmpty
                  ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 32),
                children: const [
                  _EmptyNotificationState(),
                ],
              )
                  : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 32),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];

                  final type =
                  (notification['type'] ?? 'payment_requested')
                      .toString();

                  final title =
                  (notification['title'] ??
                      _getDefaultTitle(type))
                      .toString();

                  final message =
                  (notification['message'] ?? '').toString();

                  final createdAt = _formatDate(
                    notification['created_at'],
                  );

                  final isRead = _isRead(
                    notification['is_read'],
                  );

                  final color = _getColor(type);

                  return _NotificationGlassCard(
                    title: title,
                    message: message,
                    createdAt: createdAt,
                    icon: _getIcon(type),
                    iconColor: color,
                    isRead: isRead,
                    statusLabel: _getStatusLabel(type),
                    onTap: () {
                      _openBillingPage(notification);
                    },
                  );
                },
              ),
            ),
          ),
          const _TopScrollShield(),
        ],
      ),
    );
  }
}

class _NotificationGlassCard extends StatelessWidget {
  final String title;
  final String message;
  final String createdAt;
  final IconData icon;
  final Color iconColor;
  final bool isRead;
  final String statusLabel;
  final VoidCallback? onTap;

  const _NotificationGlassCard({
    required this.title,
    required this.message,
    required this.createdAt,
    required this.icon,
    required this.iconColor,
    required this.isRead,
    required this.statusLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canTap = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 85,
              sigmaY: 85,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isRead
                      ? Colors.white.withOpacity(0.22)
                      : iconColor.withOpacity(0.42),
                  width: isRead ? 1 : 1.2,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isRead
                      ? [
                    Colors.white.withOpacity(0.20),
                    Colors.white.withOpacity(0.11),
                    Colors.white.withOpacity(0.06),
                  ]
                      : [
                    iconColor.withOpacity(0.22),
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.08),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          iconColor,
                          iconColor.withOpacity(0.72),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withOpacity(0.24),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFF062116),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.25,
                                  fontWeight: isRead
                                      ? FontWeight.w700
                                      : FontWeight.w900,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            if (!isRead) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 5),
                                decoration: BoxDecoration(
                                  color: iconColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: iconColor.withOpacity(0.45),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: iconColor.withOpacity(0.28),
                                ),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  color: iconColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ),
                            if (canTap) ...[
                              const SizedBox(width: 7),
                              Icon(
                                Icons.touch_app_rounded,
                                size: 14,
                                color: iconColor.withOpacity(0.95),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          message,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.66),
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (createdAt.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: Colors.white.withOpacity(0.44),
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  createdAt,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.46),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (canTap) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: iconColor.withOpacity(0.95),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Tap to open Billing',
                                style: TextStyle(
                                  color: iconColor.withOpacity(0.95),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyNotificationState extends StatelessWidget {
  const _EmptyNotificationState();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 85,
          sigmaY: 85,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 38,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: Colors.white.withOpacity(0.26),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.13),
                Colors.white.withOpacity(0.07),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.20),
                  ),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: Color(0xFF6EE7B7),
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No payment notifications yet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tenant payment requests will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.62),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopScrollShield extends StatelessWidget {
  const _TopScrollShield();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: MediaQuery.of(context).padding.top + 10,
      child: IgnorePointer(
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 35,
              sigmaY: 35,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0F3D2E).withOpacity(0.96),
                    const Color(0xFF0F3D2E).withOpacity(0.82),
                    const Color(0xFF0F3D2E).withOpacity(0.00),
                  ],
                  stops: const [0.0, 0.72, 1.0],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}