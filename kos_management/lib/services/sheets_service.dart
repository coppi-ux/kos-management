import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class SheetsService {
  static const Duration _timeoutDuration = Duration(seconds: 15);

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

  Future<Map<String, dynamic>> sync(
      String token,
      int kosId,
      ) async {
    try {
      final response = await http
          .post(
        Uri.parse('${ApiConfig.baseUrl}/sheets/sync/$kosId'),
        headers: _headers(token),
      )
          .timeout(_timeoutDuration);

      final data = _decodeResponse(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      }

      throw Exception(data['message'] ?? 'Failed to sync Google Sheets');
    } catch (e) {
      throw _handleError(e, 'Failed to sync Google Sheets');
    }
  }
}