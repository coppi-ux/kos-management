import '../services/tenant_bill_service.dart';

class TenantBillRepository {
  final TenantBillService _service = TenantBillService();

  String _cleanError(Object error) {
    final message = error.toString().replaceAll('Exception: ', '').trim();

    if (message.isEmpty) {
      return 'Something went wrong';
    }

    return message;
  }

  List<dynamic> _normalizeList(dynamic data) {
    if (data is List) {
      return data;
    }

    return [];
  }

  Map<String, dynamic>? _normalizeNullableMap(dynamic data) {
    if (data == null) {
      return null;
    }

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return null;
  }

  Map<String, dynamic> _normalizeMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return {
      'success': true,
    };
  }

  Future<List<dynamic>> getMyBills(
      String token,
      ) async {
    try {
      final data = await _service.getMyBills(
        token,
      );

      return _normalizeList(data);
    } catch (e) {
      final message = _cleanError(e);

      if (message.isEmpty) {
        throw Exception('Failed to fetch bills');
      }

      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>?> getCurrentBill(
      String token,
      ) async {
    try {
      final data = await _service.getCurrentBill(
        token,
      );

      return _normalizeNullableMap(data);
    } catch (e) {
      final message = _cleanError(e);

      if (message.toLowerCase().contains('no current bill') ||
          message.toLowerCase().contains('no unpaid bill') ||
          message.toLowerCase().contains('not found') ||
          message.contains('404')) {
        return null;
      }

      if (message.isEmpty) {
        throw Exception('Failed to fetch current bill');
      }

      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> payBill(
      String token,
      int billId,
      String paymentMethod,
      ) async {
    try {
      if (billId <= 0) {
        throw Exception('Invalid bill selected');
      }

      if (paymentMethod.trim().isEmpty) {
        throw Exception('Payment method is required');
      }

      final data = await _service.payBill(
        token,
        billId,
        paymentMethod,
      );

      return _normalizeMap(data);
    } catch (e) {
      final message = _cleanError(e);

      if (message.isEmpty) {
        throw Exception('Failed to pay bill');
      }

      throw Exception(message);
    }
  }

  Future<List<dynamic>> getTenantsByKos(
      String token,
      int kosId,
      ) async {
    try {
      if (kosId <= 0) {
        throw Exception('Invalid kos selected');
      }

      final data = await _service.getTenantsByKos(
        token,
        kosId,
      );

      return _normalizeList(data);
    } catch (e) {
      final message = _cleanError(e);

      if (message.isEmpty) {
        throw Exception('Failed to fetch tenants');
      }

      throw Exception(message);
    }
  }
}