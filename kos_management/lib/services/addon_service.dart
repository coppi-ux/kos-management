import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class AddonService {
  static const Duration _timeoutDuration = Duration(seconds: 10);

  Map<String, String> _headers(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  bool _isSuccessStatus(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  dynamic _decodeResponse(String body) {
    if (body.trim().isEmpty) {
      return {
        'success': true,
      };
    }

    try {
      return jsonDecode(body);
    } catch (_) {
      throw FormatException('Invalid server response: $body');
    }
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

    if (data is Map && data['errors'] != null) {
      return data['errors'].toString();
    }

    return fallbackMessage;
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

  List<dynamic> _extractList(
      dynamic data,
      String primaryKey,
      ) {
    if (data == null) {
      return [];
    }

    if (data is List) {
      return data;
    }

    if (data is! Map) {
      return [];
    }

    final map = Map<String, dynamic>.from(data);

    final keys = [
      primaryKey,
      'addons',
      'addon',
      'kos_addons',
      'kosAddons',
      'tenant_addons',
      'tenantAddons',
      'assigned_addons',
      'assignedAddons',
      'active_addons',
      'activeAddons',
      'my_addons',
      'myAddons',
      'bill_addons',
      'billAddons',
      'bill_items',
      'billItems',
      'items',
      'tenants',
      'bills',
      'data',
      'result',
      'results',
      'payload',
      'response',
    ];

    for (final key in keys) {
      if (map[key] is List) {
        return map[key];
      }
    }

    final nestedCandidates = [
      map['data'],
      map['result'],
      map['results'],
      map['payload'],
      map['response'],
      map['tenant'],
      map['bill'],
      map['latest_bill'],
      map['latestBill'],
    ];

    for (final candidate in nestedCandidates) {
      final nestedList = _extractList(candidate, primaryKey);

      if (nestedList.isNotEmpty) {
        return nestedList;
      }
    }

    return [];
  }

  Map<String, dynamic> _extractMap(
      dynamic data,
      String fallbackMessage,
      ) {
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

  Future<http.Response> _get(
      String url,
      String token,
      ) async {
    return await http
        .get(
      Uri.parse(url),
      headers: _headers(token),
    )
        .timeout(_timeoutDuration);
  }

  Future<http.Response> _post(
      String url,
      String token,
      Map<String, dynamic> body,
      ) async {
    return await http
        .post(
      Uri.parse(url),
      headers: _headers(token),
      body: jsonEncode(body),
    )
        .timeout(_timeoutDuration);
  }

  Future<http.Response> _delete(
      String url,
      String token, {
        Map<String, dynamic>? body,
      }) async {
    return await http
        .delete(
      Uri.parse(url),
      headers: _headers(token),
      body: body == null ? null : jsonEncode(body),
    )
        .timeout(_timeoutDuration);
  }

  Future<List<dynamic>> _getFirstSuccessfulList({
    required String token,
    required List<String> urls,
    required String primaryKey,
    required String fallbackMessage,
  }) async {
    Object? lastError;

    for (final url in urls) {
      try {
        final response = await _get(
          url,
          token,
        );

        final data = _decodeResponse(response.body);

        if (_isSuccessStatus(response.statusCode)) {
          final list = _extractList(
            data,
            primaryKey,
          );

          if (list.isNotEmpty) {
            return list;
          }

          /*
            Kalau status sukses tapi list kosong, return kosong.
            Ini penting supaya tenant yang memang belum punya add-ons
            tidak dianggap error.
          */
          return [];
        }

        lastError = Exception(
          _extractErrorMessage(
            data,
            fallbackMessage,
          ),
        );
      } catch (e) {
        lastError = e;
      }
    }

    if (lastError != null) {
      throw lastError;
    }

    return [];
  }

  Future<List<dynamic>> getKosAddons(
      String token,
      int kosId,
      ) async {
    try {
      if (kosId <= 0) {
        throw Exception('Invalid kos selected');
      }

      return await _getFirstSuccessfulList(
        token: token,
        urls: [
          '${ApiConfig.baseUrl}/addons/$kosId',
          '${ApiConfig.baseUrl}/addons/kos/$kosId',
          '${ApiConfig.baseUrl}/kos/$kosId/addons',
        ],
        primaryKey: 'addons',
        fallbackMessage: 'Failed to fetch add-ons',
      );
    } catch (e) {
      throw _handleError(
        e,
        'Failed to fetch add-ons',
      );
    }
  }

  Future<Map<String, dynamic>> createAddon(
      String token,
      int kosId,
      String name,
      double price,
      ) async {
    try {
      if (kosId <= 0) {
        throw Exception('Invalid kos selected');
      }

      if (name.trim().isEmpty) {
        throw Exception('Add-on name is required');
      }

      if (price <= 0) {
        throw Exception('Add-on price must be greater than zero');
      }

      final response = await _post(
        '${ApiConfig.baseUrl}/addons',
        token,
        {
          'kos_id': kosId,
          'name': name.trim(),
          'price': price,
        },
      );

      final data = _decodeResponse(response.body);

      if (_isSuccessStatus(response.statusCode)) {
        return _extractMap(
          data,
          'Add-on created successfully',
        );
      }

      throw Exception(
        _extractErrorMessage(
          data,
          'Failed to create add-on',
        ),
      );
    } catch (e) {
      throw _handleError(
        e,
        'Failed to create add-on',
      );
    }
  }

  Future<Map<String, dynamic>> deleteAddon(
      String token,
      int addonId,
      ) async {
    try {
      if (addonId <= 0) {
        throw Exception('Invalid add-on selected');
      }

      final response = await _delete(
        '${ApiConfig.baseUrl}/addons/$addonId',
        token,
      );

      final data = _decodeResponse(response.body);

      if (_isSuccessStatus(response.statusCode)) {
        return _extractMap(
          data,
          'Add-on deleted successfully',
        );
      }

      throw Exception(
        _extractErrorMessage(
          data,
          'Failed to delete add-on',
        ),
      );
    } catch (e) {
      throw _handleError(
        e,
        'Failed to delete add-on',
      );
    }
  }

  Future<Map<String, dynamic>> clearKosAddons(
      String token,
      int kosId,
      ) async {
    try {
      if (kosId <= 0) {
        throw Exception('Invalid kos selected');
      }

      final response = await _delete(
        '${ApiConfig.baseUrl}/addons/kos/$kosId/clear',
        token,
      );

      final data = _decodeResponse(response.body);

      if (_isSuccessStatus(response.statusCode)) {
        return _extractMap(
          data,
          'All add-ons cleared successfully',
        );
      }

      throw Exception(
        _extractErrorMessage(
          data,
          'Failed to clear add-ons',
        ),
      );
    } catch (e) {
      throw _handleError(
        e,
        'Failed to clear add-ons',
      );
    }
  }

  Future<List<dynamic>> getTenantsByKosForAddon(
      String token,
      int kosId,
      ) async {
    try {
      if (kosId <= 0) {
        throw Exception('Invalid kos selected');
      }

      return await _getFirstSuccessfulList(
        token: token,
        urls: [
          '${ApiConfig.baseUrl}/addons/tenants/$kosId',
          '${ApiConfig.baseUrl}/kos/$kosId/tenants/addons',
          '${ApiConfig.baseUrl}/kos/$kosId/tenants',
        ],
        primaryKey: 'tenants',
        fallbackMessage: 'Failed to fetch tenants',
      );
    } catch (e) {
      throw _handleError(
        e,
        'Failed to fetch tenants',
      );
    }
  }

  Future<Map<String, dynamic>> addAddonsToBill({
    required String token,
    required int kosId,
    required int tenantId,
    required List<int> addonIds,
  }) async {
    try {
      final validAddonIds = addonIds.where((id) => id > 0).toSet().toList();

      if (kosId <= 0) {
        throw Exception('Invalid kos selected');
      }

      if (tenantId <= 0) {
        throw Exception('Invalid tenant selected');
      }

      if (validAddonIds.isEmpty) {
        throw Exception('No valid add-ons selected');
      }

      final response = await _post(
        '${ApiConfig.baseUrl}/addons/add-to-bill',
        token,
        {
          'kos_id': kosId,
          'tenant_id': tenantId,
          'addon_ids': validAddonIds,
        },
      );

      final data = _decodeResponse(response.body);

      if (_isSuccessStatus(response.statusCode)) {
        return _extractMap(
          data,
          'Add-ons added to bill successfully',
        );
      }

      throw Exception(
        _extractErrorMessage(
          data,
          'Failed to add add-ons to bill',
        ),
      );
    } catch (e) {
      throw _handleError(
        e,
        'Failed to add add-ons to bill',
      );
    }
  }

  Future<List<dynamic>> fetchTenantAddons(
      String token,
      int tenantId,
      ) async {
    try {
      if (tenantId <= 0) {
        throw Exception('Invalid tenant selected');
      }

      /*
        Endpoint utama kamu sebelumnya:
        /addons/tenant/{tenantId}

        Aku tambahkan fallback agar kalau backend kamu pakai nama endpoint lain,
        page Tenant Add-on tetap punya kesempatan membaca data.
      */
      return await _getFirstSuccessfulList(
        token: token,
        urls: [
          '${ApiConfig.baseUrl}/addons/tenant/$tenantId',
          '${ApiConfig.baseUrl}/tenants/$tenantId/addons',
          '${ApiConfig.baseUrl}/rooms/tenants/$tenantId/addons',
          '${ApiConfig.baseUrl}/tenant/$tenantId/addons',
          '${ApiConfig.baseUrl}/addons/tenant/$tenantId/active',
          '${ApiConfig.baseUrl}/bills/tenant/$tenantId/addons',
        ],
        primaryKey: 'addons',
        fallbackMessage: 'Failed to fetch tenant add-ons',
      );
    } catch (e) {
      throw _handleError(
        e,
        'Failed to fetch tenant add-ons',
      );
    }
  }

  Future<Map<String, dynamic>> assignAddon(
      String token,
      int tenantId,
      int addonId,
      ) async {
    try {
      if (tenantId <= 0) {
        throw Exception('Invalid tenant selected');
      }

      if (addonId <= 0) {
        throw Exception('Invalid add-on selected');
      }

      final response = await _post(
        '${ApiConfig.baseUrl}/addons/assign',
        token,
        {
          'tenant_id': tenantId,
          'addon_id': addonId,
        },
      );

      final data = _decodeResponse(response.body);

      if (_isSuccessStatus(response.statusCode)) {
        return _extractMap(
          data,
          'Add-on assigned successfully',
        );
      }

      throw Exception(
        _extractErrorMessage(
          data,
          'Failed to assign add-on',
        ),
      );
    } catch (e) {
      throw _handleError(
        e,
        'Failed to assign add-on',
      );
    }
  }

  Future<Map<String, dynamic>> removeAddon(
      String token,
      int tenantId,
      int addonId,
      ) async {
    try {
      if (tenantId <= 0) {
        throw Exception('Invalid tenant selected');
      }

      if (addonId <= 0) {
        throw Exception('Invalid add-on selected');
      }

      /*
        Primary: endpoint lama kamu.
        Fallback: beberapa format umum kalau backend tidak menerima DELETE body.
      */
      final attempts = [
            () => _delete(
          '${ApiConfig.baseUrl}/addons/remove',
          token,
          body: {
            'tenant_id': tenantId,
            'addon_id': addonId,
          },
        ),
            () => _delete(
          '${ApiConfig.baseUrl}/addons/tenant/$tenantId/$addonId',
          token,
        ),
            () => _delete(
          '${ApiConfig.baseUrl}/tenants/$tenantId/addons/$addonId',
          token,
        ),
            () => _delete(
          '${ApiConfig.baseUrl}/rooms/tenants/$tenantId/addons/$addonId',
          token,
        ),
      ];

      Object? lastError;

      for (final attempt in attempts) {
        try {
          final response = await attempt();
          final data = _decodeResponse(response.body);

          if (_isSuccessStatus(response.statusCode)) {
            return _extractMap(
              data,
              'Add-on removed successfully',
            );
          }

          lastError = Exception(
            _extractErrorMessage(
              data,
              'Failed to remove add-on',
            ),
          );
        } catch (e) {
          lastError = e;
        }
      }

      if (lastError != null) {
        throw lastError;
      }

      throw Exception('Failed to remove add-on');
    } catch (e) {
      throw _handleError(
        e,
        'Failed to remove add-on',
      );
    }
  }
}