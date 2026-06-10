import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tenant_model.dart';
import '../repositories/tenant_auth_repository.dart';
import '../repositories/tenant_bill_repository.dart';

class TenantProvider extends ChangeNotifier {
  final TenantAuthRepository _authRepo = TenantAuthRepository();
  final TenantBillRepository _billRepo = TenantBillRepository();

  TenantModel? _tenant;

  List<dynamic> _tenants = [];
  List<dynamic> _bills = [];

  Map<String, dynamic>? _currentBill;

  bool _isLoading = false;
  bool _isFetchingTenants = false;
  bool _isSettingPassword = false;
  bool _isLoggingIn = false;
  bool _isFetchingBills = false;
  bool _isPayingBill = false;

  String? _errorMessage;

  TenantModel? get tenant => _tenant;

  List<dynamic> get tenants => _tenants;
  List<dynamic> get bills => _bills;

  Map<String, dynamic>? get currentBill => _currentBill;

  bool get isLoading => _isLoading;
  bool get isFetchingTenants => _isFetchingTenants;
  bool get isSettingPassword => _isSettingPassword;
  bool get isLoggingIn => _isLoggingIn;
  bool get isFetchingBills => _isFetchingBills;
  bool get isPayingBill => _isPayingBill;

  String? get errorMessage => _errorMessage;

  bool get isLoggedIn => _tenant != null;
  String? get token => _tenant?.token;

  List<dynamic> get paidBills {
    return _sortBillsNewestFirst(
      _bills.where((bill) {
        return _getStatus(bill) == 'paid';
      }).toList(),
    );
  }

  List<dynamic> get unpaidBills {
    return _sortBillsNewestFirst(
      _bills.where((bill) {
        return _getStatus(bill) == 'unpaid';
      }).toList(),
    );
  }

  int get paidBillCount => paidBills.length;
  int get unpaidBillCount => unpaidBills.length;

  double get totalPaidAmount {
    return paidBills.fold(0.0, (sum, bill) {
      return sum + _toDouble(bill['total_amount']);
    });
  }

  double get totalUnpaidAmount {
    return unpaidBills.fold(0.0, (sum, bill) {
      return sum + _toDouble(bill['total_amount']);
    });
  }

  void _refreshGlobalLoading() {
    _isLoading = _isFetchingTenants ||
        _isSettingPassword ||
        _isLoggingIn ||
        _isFetchingBills ||
        _isPayingBill;
  }

  double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0.0;
  }

  String _getStatus(dynamic bill) {
    if (bill is Map) {
      return '${bill['status'] ?? ''}'.toLowerCase().trim();
    }

    return '';
  }

  DateTime _parseDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime(1900);
  }

  List<dynamic> _sortBillsNewestFirst(List<dynamic> bills) {
    final copiedBills = List<dynamic>.from(bills);

    copiedBills.sort((a, b) {
      if (a is! Map || b is! Map) return 0;

      final monthA = '${a['billing_month'] ?? ''}';
      final monthB = '${b['billing_month'] ?? ''}';

      final monthCompare = monthB.compareTo(monthA);

      if (monthCompare != 0) {
        return monthCompare;
      }

      final dateA = _parseDate(a['due_date']);
      final dateB = _parseDate(b['due_date']);

      return dateB.compareTo(dateA);
    });

    return copiedBills;
  }

  Map<String, dynamic>? _mapFromDynamic(dynamic value) {
    if (value == null) return null;

    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  Map<String, dynamic>? _findCurrentUnpaidBillFromList() {
    final unpaid = unpaidBills;

    if (unpaid.isEmpty) {
      return null;
    }

    return _mapFromDynamic(unpaid.first);
  }

  bool _isBillPaid(dynamic bill) {
    return _getStatus(bill) == 'paid';
  }

  bool _isBillUnpaid(dynamic bill) {
    return _getStatus(bill) == 'unpaid';
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearTenantData() {
    _tenant = null;
    _tenants = [];
    _bills = [];
    _currentBill = null;
    _errorMessage = null;

    _isLoading = false;
    _isFetchingTenants = false;
    _isSettingPassword = false;
    _isLoggingIn = false;
    _isFetchingBills = false;
    _isPayingBill = false;

    notifyListeners();
  }

  Future<void> fetchAllTenants(
      String token,
      int kosId,
      ) async {
    _isFetchingTenants = true;
    _errorMessage = null;
    _refreshGlobalLoading();
    notifyListeners();

    try {
      final data = await _billRepo.getTenantsByKos(
        token,
        kosId,
      );

      _tenants = data;
    } catch (e) {
      _setError(e);
      _tenants = [];
    } finally {
      _isFetchingTenants = false;
      _refreshGlobalLoading();
      notifyListeners();
    }
  }

  Future<bool> setupPassword(
      String email,
      String password,
      ) async {
    _isSettingPassword = true;
    _errorMessage = null;
    _refreshGlobalLoading();
    notifyListeners();

    try {
      await _authRepo.setupPassword(
        email,
        password,
      );

      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _isSettingPassword = false;
      _refreshGlobalLoading();
      notifyListeners();
    }
  }

  Future<bool> login(
      String email,
      String password,
      ) async {
    _isLoggingIn = true;
    _errorMessage = null;
    _refreshGlobalLoading();
    notifyListeners();

    try {
      _tenant = await _authRepo.login(
        email,
        password,
      );

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'tenant_token',
        _tenant!.token,
      );

      await prefs.setString(
        'tenant_name',
        _tenant!.name,
      );

      await prefs.setInt(
        'tenant_id',
        _tenant!.id,
      );

      await fetchBills();

      return true;
    } catch (e) {
      _setError(e);
      _tenant = null;
      _bills = [];
      _currentBill = null;
      return false;
    } finally {
      _isLoggingIn = false;
      _refreshGlobalLoading();
      notifyListeners();
    }
  }

  Future<void> fetchBills() async {
    if (_tenant == null) return;

    _isFetchingBills = true;
    _errorMessage = null;
    _refreshGlobalLoading();
    notifyListeners();

    try {
      final allBills = await _billRepo.getMyBills(
        _tenant!.token,
      );

      _bills = _sortBillsNewestFirst(allBills);

      Map<String, dynamic>? currentFromList = _findCurrentUnpaidBillFromList();

      if (currentFromList != null) {
        _currentBill = currentFromList;
      } else {
        try {
          final currentFromApi = await _billRepo.getCurrentBill(
            _tenant!.token,
          );

          final mappedCurrent = _mapFromDynamic(currentFromApi);

          if (mappedCurrent != null && _isBillUnpaid(mappedCurrent)) {
            _currentBill = mappedCurrent;
          } else {
            _currentBill = null;
          }
        } catch (_) {
          _currentBill = null;
        }
      }
    } catch (e) {
      _setError(e);
      _bills = [];
      _currentBill = null;
    } finally {
      _isFetchingBills = false;
      _refreshGlobalLoading();
      notifyListeners();
    }
  }

  Future<bool> payBill(
      int billId,
      String paymentMethod,
      ) async {
    if (_tenant == null) return false;

    _isPayingBill = true;
    _errorMessage = null;
    _refreshGlobalLoading();
    notifyListeners();

    try {
      await _billRepo.payBill(
        _tenant!.token,
        billId,
        paymentMethod,
      );

      await fetchBills();

      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _isPayingBill = false;
      _refreshGlobalLoading();
      notifyListeners();
    }
  }

  Future<void> refreshAfterOwnerPaid() async {
    await fetchBills();
  }

  Future<void> logout() async {
    _tenant = null;
    _tenants = [];
    _bills = [];
    _currentBill = null;
    _errorMessage = null;

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('tenant_token');
    await prefs.remove('tenant_name');
    await prefs.remove('tenant_id');

    _isLoading = false;
    _isFetchingTenants = false;
    _isSettingPassword = false;
    _isLoggingIn = false;
    _isFetchingBills = false;
    _isPayingBill = false;

    notifyListeners();
  }
}
