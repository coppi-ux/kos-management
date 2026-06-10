import 'package:flutter/material.dart';
import '../repositories/bill_repository.dart';

class BillProvider extends ChangeNotifier {
  final BillRepository _repo = BillRepository();

  List<dynamic> _bills = [];
  List<dynamic> _overdueBills = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get bills => _bills;
  List<dynamic> get overdueBills => _overdueBills;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalBills => _bills.length;

  int get unpaidCount {
    return _bills.where((b) {
      return '${b['status']}'.toLowerCase() == 'unpaid';
    }).length;
  }

  int get paidCount {
    return _bills.where((b) {
      return '${b['status']}'.toLowerCase() == 'paid';
    }).length;
  }

  double get totalUnpaidAmount {
    return _bills.where((b) {
      return '${b['status']}'.toLowerCase() == 'unpaid';
    }).fold(0.0, (sum, b) {
      final amount = double.tryParse('${b['total_amount']}') ?? 0.0;
      return sum + amount;
    });
  }

  // ✅ FETCH BILLS
  Future<void> fetchBills(String token, int kosId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bills = await _repo.getBillsByKos(token, kosId);

      _bills = bills;
      _overdueBills = bills.where((b) {
        final dueDate = DateTime.tryParse('${b['due_date']}');
        if (dueDate == null) return false;

        return b['status'] == 'unpaid' &&
            dueDate.isBefore(DateTime.now());
      }).toList();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _bills = [];
      _overdueBills = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // ✅ ✅ GENERATE BILLS (FIXED)
  Future<bool> generateBills(String token, int kosId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.generateBills(token, kosId);

      // ✅ penting: ambil data baru
      await fetchBills(token, kosId);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');

      _isLoading = false;
      notifyListeners();

      return false;
    }
  }

  // ✅ MARK AS PAID
  Future<bool> markPaid(String token, int billId, int kosId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.markPaid(token, billId);

      await fetchBills(token, kosId);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');

      _isLoading = false;
      notifyListeners();

      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}