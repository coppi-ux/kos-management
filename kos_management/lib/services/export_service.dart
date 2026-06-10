import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config/api_config.dart';

class ExportService {
  static const Duration _timeoutDuration = Duration(seconds: 15);

  Map<String, String> _headers(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'text/csv',
    };
  }

  Exception _handleError(Object error, String fallbackMessage) {
    if (error is TimeoutException) {
      return Exception('Connection timeout. Please check your backend or WiFi.');
    }

    if (error is SocketException) {
      return Exception('Cannot connect to server. Please check your connection.');
    }

    final message = error.toString().replaceAll('Exception: ', '').trim();

    if (message.isEmpty) {
      return Exception(fallbackMessage);
    }

    return Exception(message);
  }

  String _safeTimestamp() {
    final now = DateTime.now();

    String twoDigits(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${now.year}'
        '${twoDigits(now.month)}'
        '${twoDigits(now.day)}_'
        '${twoDigits(now.hour)}'
        '${twoDigits(now.minute)}'
        '${twoDigits(now.second)}';
  }

  Future<File> downloadCsv({
    required String token,
    required int kosId,
    required String type,
  }) async {
    try {
      if (type != 'bills' && type != 'tenants') {
        throw Exception('Invalid export type');
      }

      final response = await http
          .get(
        Uri.parse('${ApiConfig.baseUrl}/export/$type/$kosId'),
        headers: _headers(token),
      )
          .timeout(_timeoutDuration);

      if (response.statusCode != 200) {
        final body = response.body.trim();

        if (body.isNotEmpty) {
          throw Exception(body);
        }

        throw Exception('Failed to download CSV');
      }

      final directory = await getApplicationDocumentsDirectory();

      final fileName = '${type}_kos_${kosId}_${_safeTimestamp()}.csv';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(response.bodyBytes);

      return file;
    } catch (e) {
      throw _handleError(e, 'Failed to download CSV');
    }
  }
}