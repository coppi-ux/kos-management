import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  static const Duration _timeoutDuration = Duration(seconds: 10);

  // REGISTER
  Future<String> register(String name, String email, String password) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/register');

      final response = await http
          .post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      )
          .timeout(_timeoutDuration);

      final data = _decodeResponse(response.body);

      if (response.statusCode == 201) {
        return data['message']?.toString() ?? 'Owner registered successfully';
      }

      throw Exception(data['message']?.toString() ?? 'Register failed');
    } on TimeoutException {
      throw Exception(
        'Connection timeout. Pastikan backend sedang berjalan dan IP API sudah benar.',
      );
    } on SocketException {
      throw Exception(
        'Tidak bisa terhubung ke server. Pastikan HP dan laptop berada di WiFi yang sama.',
      );
    } on FormatException {
      throw Exception('Invalid server response.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // LOGIN
  Future<UserModel> login(String email, String password) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/login');

      final response = await http
          .post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      )
          .timeout(_timeoutDuration);

      final data = _decodeResponse(response.body);

      if (response.statusCode == 200) {
        final token = data['token'];
        final user = data['user'];

        if (token == null || user == null) {
          throw Exception('Invalid login response from server.');
        }

        return UserModel.fromJson(user, token);
      }

      throw Exception(data['message']?.toString() ?? 'Login failed');
    } on TimeoutException {
      throw Exception(
        'Connection timeout. Pastikan backend sedang berjalan dan IP API sudah benar.',
      );
    } on SocketException {
      throw Exception(
        'Tidak bisa terhubung ke server. Pastikan HP dan laptop berada di WiFi yang sama.',
      );
    } on FormatException {
      throw Exception('Invalid server response.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Map<String, dynamic> _decodeResponse(String body) {
    if (body.isEmpty) {
      throw const FormatException('Empty response body');
    }

    final decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const FormatException('Response is not a JSON object');
  }
}