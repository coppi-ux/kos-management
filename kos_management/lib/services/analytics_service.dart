import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class AnalyticsService {
  static const Duration _timeoutDuration = Duration(seconds: 10);

  Map<String, String> _headers(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Map<String, dynamic> _decodeResponse(String body) {
    if (body.isEmpty) {
      throw const FormatException('Empty response from server');
    }

    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw const FormatException('Invalid response format');
    } catch (_) {
      throw FormatException('Invalid server response: $body');
    }
  }

  Exception _handleError(Object error, String fallbackMessage) {
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

  Future<Map<String, dynamic>> getDashboardStats(
      String token,
      int kosId,
      ) async {
    try {
      final response = await http
          .get(
        Uri.parse('${ApiConfig.baseUrl}/analytics/$kosId'),
        headers: _headers(token),
      )
          .timeout(_timeoutDuration);

      final data = _decodeResponse(response.body);

      if (response.statusCode == 200) {
        return data;
      }

      throw Exception(data['message'] ?? 'Failed to fetch analytics');
    } catch (e) {
      throw _handleError(e, 'Failed to fetch analytics');
    }
  }

  Future<List<dynamic>> getTenantPaymentHistory(
      String token,
      int tenantId,
      ) async {
    try {
      final response = await http
          .get(
        Uri.parse('${ApiConfig.baseUrl}/analytics/tenant/$tenantId/history'),
        headers: _headers(token),
      )
          .timeout(_timeoutDuration);

      final data = _decodeResponse(response.body);

      if (response.statusCode == 200) {
        if (data['history'] is List) return data['history'];
        if (data['data'] is List) return data['data'];
        return [];
      }

      throw Exception(data['message'] ?? 'Failed to fetch payment history');
    } catch (e) {
      throw _handleError(e, 'Failed to fetch payment history');
    }
  }

  Future<String> getExportUrl(
      String type,
      int kosId,
      ) async {
    return '${ApiConfig.baseUrl}/export/$type/$kosId';
  }
}