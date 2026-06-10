import '../services/addon_service.dart';

class AddonRepository {
  final AddonService _service = AddonService();

  String _cleanError(Object error) {
    final message = error.toString().replaceAll('Exception: ', '').trim();

    if (message.isEmpty) {
      return 'Something went wrong';
    }

    return message;
  }

  bool _isTokenInvalid(String token) {
    return token.trim().isEmpty;
  }

  List<dynamic> _normalizeList(dynamic data) {
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

    final directListKeys = [
      'addons',
      'kos_addons',
      'tenant_addons',
      'tenantAddons',
      'assigned_addons',
      'assignedAddons',
      'bill_addons',
      'billAddons',
      'items',
      'tenants',
      'data',
      'result',
      'results',
    ];

    for (final key in directListKeys) {
      if (map[key] is List) {
        return map[key];
      }
    }

    /*
      Bagian ini penting:
      Kadang response API bentuknya:
      {
        "success": true,
        "data": {
          "tenant_addons": [...]
        }
      }

      Kalau cuma cek data['data'] is List, hasilnya kosong.
      Jadi kalau data/result/results berupa Map, kita cek lagi isi dalamnya.
    */
    final nestedCandidates = [
      map['data'],
      map['result'],
      map['results'],
      map['payload'],
      map['response'],
    ];

    for (final candidate in nestedCandidates) {
      if (candidate is List) {
        return candidate;
      }

      if (candidate is Map) {
        final nestedMap = Map<String, dynamic>.from(candidate);

        for (final key in directListKeys) {
          if (nestedMap[key] is List) {
            return nestedMap[key];
          }
        }

        /*
          Kadang backend balikin:
          {
            "data": {
              "tenant": {...},
              "addons": [...]
            }
          }
        */
        final deeperCandidates = [
          nestedMap['data'],
          nestedMap['result'],
          nestedMap['results'],
          nestedMap['payload'],
        ];

        for (final deeper in deeperCandidates) {
          if (deeper is List) {
            return deeper;
          }

          if (deeper is Map) {
            final deeperMap = Map<String, dynamic>.from(deeper);

            for (final key in directListKeys) {
              if (deeperMap[key] is List) {
                return deeperMap[key];
              }
            }
          }
        }
      }
    }

    return [];
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

  List<int> _normalizeAddonIds(List<int> addonIds) {
    return addonIds.where((id) => id > 0).toSet().toList();
  }

  Future<List<dynamic>> getKosAddons(
      String token,
      int kosId,
      ) async {
    try {
      if (_isTokenInvalid(token)) {
        throw Exception('Session expired, please login again');
      }

      if (kosId <= 0) {
        throw Exception('Invalid kos selected');
      }

      final data = await _service.getKosAddons(
        token,
        kosId,
      );

      return _normalizeList(data);
    } catch (e) {
      throw Exception(_cleanError(e));
    }
  }

  Future<Map<String, dynamic>> createAddon(
      String token,
      int kosId,
      String name,
      double price,
      ) async {
    try {
      if (_isTokenInvalid(token)) {
        throw Exception('Session expired, please login again');
      }

      if (kosId <= 0) {
        throw Exception('Invalid kos selected');
      }

      final cleanName = name.trim();

      if (cleanName.isEmpty) {
        throw Exception('Add-on name is required');
      }

      if (price <= 0) {
        throw Exception('Add-on price must be greater than zero');
      }

      final data = await _service.createAddon(
        token,
        kosId,
        cleanName,
        price,
      );

      return _normalizeMap(data);
    } catch (e) {
      throw Exception(_cleanError(e));
    }
  }

  Future<Map<String, dynamic>> deleteAddon(
      String token,
      int addonId,
      ) async {
    try {
      if (_isTokenInvalid(token)) {
        throw Exception('Session expired, please login again');
      }

      if (addonId <= 0) {
        throw Exception('Invalid add-on selected');
      }

      final data = await _service.deleteAddon(
        token,
        addonId,
      );

      return _normalizeMap(data);
    } catch (e) {
      throw Exception(_cleanError(e));
    }
  }

  Future<Map<String, dynamic>> clearKosAddons(
      String token,
      int kosId,
      ) async {
    try {
      if (_isTokenInvalid(token)) {
        throw Exception('Session expired, please login again');
      }

      if (kosId <= 0) {
        throw Exception('Invalid kos selected');
      }

      final data = await _service.clearKosAddons(
        token,
        kosId,
      );

      return _normalizeMap(data);
    } catch (e) {
      throw Exception(_cleanError(e));
    }
  }

  Future<List<dynamic>> getTenantsByKosForAddon(
      String token,
      int kosId,
      ) async {
    try {
      if (_isTokenInvalid(token)) {
        throw Exception('Session expired, please login again');
      }

      if (kosId <= 0) {
        throw Exception('Invalid kos selected');
      }

      final data = await _service.getTenantsByKosForAddon(
        token,
        kosId,
      );

      return _normalizeList(data);
    } catch (e) {
      throw Exception(_cleanError(e));
    }
  }

  Future<Map<String, dynamic>> addAddonsToBill({
    required String token,
    required int kosId,
    required int tenantId,
    required List<int> addonIds,
  }) async {
    try {
      if (_isTokenInvalid(token)) {
        throw Exception('Session expired, please login again');
      }

      if (kosId <= 0) {
        throw Exception('Invalid kos selected');
      }

      if (tenantId <= 0) {
        throw Exception('Invalid tenant selected');
      }

      final validAddonIds = _normalizeAddonIds(addonIds);

      if (validAddonIds.isEmpty) {
        throw Exception('No valid add-ons selected');
      }

      final data = await _service.addAddonsToBill(
        token: token,
        kosId: kosId,
        tenantId: tenantId,
        addonIds: validAddonIds,
      );

      return _normalizeMap(data);
    } catch (e) {
      throw Exception(_cleanError(e));
    }
  }

  Future<List<dynamic>> fetchTenantAddons(
      String token,
      int tenantId,
      ) async {
    try {
      if (_isTokenInvalid(token)) {
        throw Exception('Session expired, please login again');
      }

      if (tenantId <= 0) {
        throw Exception('Invalid tenant selected');
      }

      final data = await _service.fetchTenantAddons(
        token,
        tenantId,
      );

      return _normalizeList(data);
    } catch (e) {
      throw Exception(_cleanError(e));
    }
  }

  Future<Map<String, dynamic>> assignAddon(
      String token,
      int tenantId,
      int addonId,
      ) async {
    try {
      if (_isTokenInvalid(token)) {
        throw Exception('Session expired, please login again');
      }

      if (tenantId <= 0) {
        throw Exception('Invalid tenant selected');
      }

      if (addonId <= 0) {
        throw Exception('Invalid add-on selected');
      }

      final data = await _service.assignAddon(
        token,
        tenantId,
        addonId,
      );

      return _normalizeMap(data);
    } catch (e) {
      throw Exception(_cleanError(e));
    }
  }

  Future<Map<String, dynamic>> removeAddon(
      String token,
      int tenantId,
      int addonId,
      ) async {
    try {
      if (_isTokenInvalid(token)) {
        throw Exception('Session expired, please login again');
      }

      if (tenantId <= 0) {
        throw Exception('Invalid tenant selected');
      }

      if (addonId <= 0) {
        throw Exception('Invalid add-on selected');
      }

      final data = await _service.removeAddon(
        token,
        tenantId,
        addonId,
      );

      return _normalizeMap(data);
    } catch (e) {
      throw Exception(_cleanError(e));
    }
  }
}