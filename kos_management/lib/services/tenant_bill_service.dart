import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class TenantBillService {
  static const Duration _timeoutDuration = Duration(seconds: 10);

  Map<String, String> _headers(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  dynamic _decodeResponse(String body) {
    if (body.isEmpty) {
      throw const FormatException('Empty response from server');
    }

    try {
      return jsonDecode(body);
    } catch (_) {
      throw FormatException('Invalid server response: $body');
    }
  }

  Exception _handleError(
      Object error,
      String fallbackMessage,
      ) {
    if (error is TimeoutException) {
      return Exception('Connection timeout. Please check your backend or WiFi.');
    }

    if (error is SocketException) {
      return Exception('Cannot connect to server. Please check your connection.');
    }

    if (error is FormatException) {
      return Exception(error.message);
    }

    final message = error.toString().replaceAll('Exception: ', '').trim();

    if (message.isEmpty) {
      return Exception(fallbackMessage);
    }

    return Exception(message);
  }

  String _extractErrorMessage(
      dynamic data,
      String fallbackMessage,
      ) {
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }

    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }

    return fallbackMessage;
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map && data['bills'] is List) {
      return data['bills'];
    }

    if (data is Map && data['bill'] is List) {
      return data['bill'];
    }

    if (data is Map && data['data'] is List) {
      return data['data'];
    }

    if (data is Map && data['tenants'] is List) {
      return data['tenants'];
    }

    if (data is Map && data['addons'] is List) {
      return data['addons'];
    }

    return [];
  }

  Map<String, dynamic>? _extractMapOrNull(dynamic data) {
    if (data == null) {
      return null;
    }

    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString().toLowerCase() ?? '';

      if (message.contains('no current bill') ||
          message.contains('no unpaid bill') ||
          message.contains('no outstanding bill') ||
          message.contains('not found')) {
        return null;
      }

      if (data['bill'] is Map<String, dynamic>) {
        return data['bill'];
      }

      if (data['current_bill'] is Map<String, dynamic>) {
        return data['current_bill'];
      }

      if (data['currentBill'] is Map<String, dynamic>) {
        return data['currentBill'];
      }

      if (data['data'] is Map<String, dynamic>) {
        return data['data'];
      }

      final hasBillKeys = data.containsKey('id') ||
          data.containsKey('tenant_id') ||
          data.containsKey('billing_month') ||
          data.containsKey('base_amount') ||
          data.containsKey('total_amount') ||
          data.containsKey('status');

      if (hasBillKeys) {
        return data;
      }

      return null;
    }

    if (data is Map) {
      final mapped = Map<String, dynamic>.from(data);
      return _extractMapOrNull(mapped);
    }

    return null;
  }

  Map<String, dynamic> _extractMap(dynamic data, String fallbackMessage) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return {
      'success': true,
      'message': fallbackMessage,
    };
  }

  Future<List<dynamic>> getMyBills(
      String token,
      ) async {
    try {
      final response = await http
          .get(
        Uri.parse('${ApiConfig.baseUrl}/tenant/bills'),
        headers: _headers(token),
      )
          .timeout(_timeoutDuration);

      final data = _decodeResponse(response.body);

      if (response.statusCode == 200) {
        return _extractList(data);
      }

      throw Exception(
        _extractErrorMessage(
          data,
          'Failed to fetch bills',
        ),
      );
    } catch (e) {
      throw _handleError(
        e,
        'Failed to fetch bills',
      );
    }
  }

  Future<Map<String, dynamic>?> getCurrentBill(
      String token,
      ) async {
    try {
      final response = await http
          .get(
        Uri.parse('${ApiConfig.baseUrl}/tenant/current-bill'),
        headers: _headers(token),
      )
          .timeout(_timeoutDuration);

      final data = _decodeResponse(response.body);

      if (response.statusCode == 200) {
        return _extractMapOrNull(data);
      }

      if (response.statusCode == 404) {
        return null;
      }

      throw Exception(
        _extractErrorMessage(
          data,
          'Failed to fetch current bill',
        ),
      );
    } catch (e) {
      final message = e.toString().toLowerCase();

      if (message.contains('404') ||
          message.contains('no current bill') ||
          message.contains('no unpaid bill') ||
          message.contains('no outstanding bill') ||
          message.contains('not found')) {
        return null;
      }

      throw _handleError(
        e,
        'Failed to fetch current bill',
      );
    }
  }

  Future<Map<String, dynamic>> payBill(
      String token,
      int billId,
      String paymentMethod,
      ) async {
    try {
      final response = await http
          .post(
        Uri.parse('${ApiConfig.baseUrl}/tenant/pay/$billId'),
        headers: _headers(token),
        body: jsonEncode({
          'payment_method': paymentMethod,
        }),
      )
          .timeout(_timeoutDuration);

      final data = _decodeResponse(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _extractMap(
          data,
          'Payment successful',
        );
      }

      throw Exception(
        _extractErrorMessage(
          data,
          'Failed to pay bill',
        ),
      );
    } catch (e) {
      throw _handleError(
        e,
        'Failed to pay bill',
      );
    }
  }

  Future<List<dynamic>> getTenantsByKos(
      String token,
      int kosId,
      ) async {
    try {
      final response = await http
          .get(
        Uri.parse('${ApiConfig.baseUrl}/tenants/kos/$kosId'),
        headers: _headers(token),
      )
          .timeout(_timeoutDuration);

      final data = _decodeResponse(response.body);

      if (response.statusCode == 200) {
        return _extractList(data);
      }

      throw Exception(
        _extractErrorMessage(
          data,
          'Failed to fetch tenants',
        ),
      );
    } catch (e) {
      throw _handleError(
        e,
        'Failed to fetch tenants',
      );
    }
  }

  Future<List<dynamic>> getMyActiveAddons(
      String token,
      ) async {
    try {
      final response = await http
          .get(
        Uri.parse('${ApiConfig.baseUrl}/tenant/my-addons'),
        headers: _headers(token),
      )
          .timeout(_timeoutDuration);

      final data = _decodeResponse(response.body);

      if (response.statusCode == 200) {
        return _extractList(data);
      }

      throw Exception(
        _extractErrorMessage(
          data,
          'Failed to fetch additional bills',
        ),
      );
    } catch (e) {
      throw _handleError(
        e,
        'Failed to fetch additional bills',
      );
    }
  }
}