import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/tenant_model.dart';

class TenantAuthService {
  static const Duration _timeoutDuration = Duration(seconds: 10);

  Map<String, String> _headers() {
    return {
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

  Future<String> setupPassword(
      String email,
      String password,
      ) async {
    try {
      final response = await http
          .post(
        Uri.parse('${ApiConfig.baseUrl}/tenant-auth/setup-password'),
        headers: _headers(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      )
          .timeout(_timeoutDuration);

      final data = _decodeResponse(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data['message']?.toString() ?? 'Password set successfully';
      }

      throw Exception(data['message'] ?? 'Failed to set password');
    } catch (e) {
      throw _handleError(e, 'Failed to set password');
    }
  }

  Future<TenantModel> login(
      String email,
      String password,
      ) async {
    try {
      final response = await http
          .post(
        Uri.parse('${ApiConfig.baseUrl}/tenant-auth/login'),
        headers: _headers(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      )
          .timeout(_timeoutDuration);

      final data = _decodeResponse(response.body);

      if (response.statusCode == 200) {
        final tenantData = data['tenant'];
        final token = data['token'];

        if (tenantData == null || token == null) {
          throw Exception('Invalid login response from server');
        }

        return TenantModel.fromJson(
          tenantData,
          token.toString(),
        );
      }

      if (data['needs_setup'] == true) {
        throw Exception('NEEDS_SETUP');
      }

      throw Exception(data['message'] ?? 'Failed to login');
    } catch (e) {
      throw _handleError(e, 'Failed to login');
    }
  }
}