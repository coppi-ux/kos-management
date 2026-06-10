import 'package:flutter/material.dart';

import '../repositories/analytics_repository.dart';

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsRepository _repo = AnalyticsRepository();

  Map<String, dynamic>? _stats;
  List<dynamic> _paymentHistory = [];

  bool _isLoading = false;
  bool _isFetchingStats = false;
  bool _isFetchingPaymentHistory = false;

  String? _errorMessage;

  Map<String, dynamic>? get stats => _stats;
  List<dynamic> get paymentHistory => _paymentHistory;

  bool get isLoading => _isLoading;
  bool get isFetchingStats => _isFetchingStats;
  bool get isFetchingPaymentHistory => _isFetchingPaymentHistory;

  String? get errorMessage => _errorMessage;

  void _refreshGlobalLoading() {
    _isLoading = _isFetchingStats || _isFetchingPaymentHistory;
  }

  void _setError(dynamic error) {
    final text = error.toString().replaceAll('Exception: ', '').trim();

    if (text.isEmpty) {
      _errorMessage = 'Something went wrong';
      return;
    }

    if (text.contains('401') ||
        text.toLowerCase().contains('unauthorized') ||
        text.toLowerCase().contains('token')) {
      _errorMessage = 'Session expired, please login again';
      return;
    }

    _errorMessage = text;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is double) return value.round();

    return int.tryParse(value.toString()) ??
        double.tryParse(value.toString())?.round() ??
        0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is double) return value;

    if (value is int) return value.toDouble();

    return double.tryParse(value.toString()) ?? 0.0;
  }

  dynamic _nestedValue(String parentKey, String childKey) {
    final parent = _stats?[parentKey];

    if (parent is Map<String, dynamic>) {
      return parent[childKey];
    }

    if (parent is Map) {
      return parent[childKey];
    }

    return null;
  }

  int get totalRooms {
    return _toInt(_nestedValue('rooms', 'total'));
  }

  int get occupiedRooms {
    return _toInt(_nestedValue('rooms', 'occupied'));
  }

  int get availableRooms {
    return _toInt(_nestedValue('rooms', 'available'));
  }

  int get occupancyRate {
    return _toInt(_nestedValue('rooms', 'occupancy_rate'));
  }

  int get totalTenants {
    return _toInt(_nestedValue('tenants', 'total'));
  }

  double get monthlyIncome {
    return _toDouble(_nestedValue('billing', 'monthly_income'));
  }

  int get unpaidCount {
    return _toInt(_nestedValue('billing', 'unpaid_count'));
  }

  double get unpaidAmount {
    return _toDouble(_nestedValue('billing', 'unpaid_amount'));
  }

  List<dynamic> get chartData {
    final value = _stats?['chart'];

    if (value is List) {
      return value;
    }

    return [];
  }

  List<dynamic> get recentActivity {
    final value = _stats?['recent_activity'];

    if (value is List) {
      return value;
    }

    return [];
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearAnalyticsData() {
    _stats = null;
    _paymentHistory = [];
    _errorMessage = null;

    _isLoading = false;
    _isFetchingStats = false;
    _isFetchingPaymentHistory = false;

    notifyListeners();
  }

  Future<void> fetchStats(
      String token,
      int kosId,
      ) async {
    _isFetchingStats = true;
    _errorMessage = null;
    _refreshGlobalLoading();
    notifyListeners();

    try {
      final result = await _repo.getDashboardStats(
        token,
        kosId,
      );

      _stats = result;
    } catch (e) {
      _setError(e);
      _stats ??= {};
    } finally {
      _isFetchingStats = false;
      _refreshGlobalLoading();
      notifyListeners();
    }
  }

  Future<void> fetchPaymentHistory(
      String token,
      int tenantId,
      ) async {
    _isFetchingPaymentHistory = true;
    _errorMessage = null;
    _refreshGlobalLoading();
    notifyListeners();

    try {
      _paymentHistory = await _repo.getTenantPaymentHistory(
        token,
        tenantId,
      );
    } catch (e) {
      _setError(e);
      _paymentHistory = [];
    } finally {
      _isFetchingPaymentHistory = false;
      _refreshGlobalLoading();
      notifyListeners();
    }
  }
}