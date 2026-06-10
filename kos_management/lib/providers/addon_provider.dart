import 'package:flutter/material.dart';

import '../repositories/addon_repository.dart';

class AddonProvider extends ChangeNotifier {
  final AddonRepository _repo = AddonRepository();

  List<dynamic> _kosAddons = [];
  List<dynamic> _addonTenants = [];
  List<dynamic> _tenantAddons = [];

  bool _isLoading = false;

  bool _isFetchingAddons = false;
  bool _isCreatingAddon = false;
  bool _isDeletingAddon = false;
  bool _isClearingAddons = false;

  bool _isFetchingTenants = false;
  bool _isAddingToBill = false;

  bool _isFetchingTenantAddons = false;
  bool _isAssigningAddon = false;
  bool _isRemovingAddon = false;

  String? _errorMessage;

  List<dynamic> get kosAddons => _kosAddons;
  List<dynamic> get addonTenants => _addonTenants;
  List<dynamic> get tenantAddons => _tenantAddons;

  bool get isLoading => _isLoading;

  bool get isFetchingAddons => _isFetchingAddons;
  bool get isCreatingAddon => _isCreatingAddon;
  bool get isDeletingAddon => _isDeletingAddon;
  bool get isClearingAddons => _isClearingAddons;

  bool get isFetchingTenants => _isFetchingTenants;
  bool get isAddingToBill => _isAddingToBill;

  bool get isFetchingTenantAddons => _isFetchingTenantAddons;
  bool get isAssigningAddon => _isAssigningAddon;
  bool get isRemovingAddon => _isRemovingAddon;

  String? get errorMessage => _errorMessage;

  double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0.0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  String _decodeText(dynamic value) {
    return value
        ?.toString()
        .replaceAll('&amp;amp;amp;', '&')
        .replaceAll('&amp;amp;', '&')
        .replaceAll('&amp;', '&')
        .replaceAll('  ', ' ')
        .trim() ??
        '';
  }

  String _normalizeName(dynamic value) {
    return _decodeText(value).toLowerCase();
  }

  bool _isSuccessStatus(dynamic value) {
    if (value == true) return true;

    final text = value?.toString().toLowerCase().trim() ?? '';

    return text == 'true' ||
        text == '1' ||
        text == 'active' ||
        text == 'success' ||
        text == 'assigned';
  }

  int getAddonId(dynamic addon) {
    if (addon is! Map) return 0;

    return _toInt(
      addon['addon_id'] ??
          addon['addonId'] ??
          addon['id'] ??
          addon['addon_master_id'] ??
          addon['master_addon_id'],
    );
  }

  int getTenantAddonId(dynamic addon) {
    if (addon is! Map) return 0;

    return _toInt(
      addon['tenant_addon_id'] ??
          addon['tenantAddonId'] ??
          addon['pivot_id'] ??
          addon['relation_id'] ??
          addon['id'],
    );
  }

  int getTenantIdFromAddon(dynamic addon) {
    if (addon is! Map) return 0;

    return _toInt(
      addon['tenant_id'] ??
          addon['tenantId'] ??
          addon['room_tenant_id'] ??
          addon['roomTenantId'],
    );
  }

  String getAddonName(dynamic addon) {
    if (addon is! Map) return 'Unknown Add-on';

    final text = _decodeText(
      addon['name'] ??
          addon['addon_name'] ??
          addon['addonName'] ??
          addon['item_name'] ??
          addon['title'],
    );

    if (text.isEmpty || text == 'null') {
      return 'Unknown Add-on';
    }

    return text;
  }

  double getAddonPrice(dynamic addon) {
    if (addon is! Map) return 0.0;

    return _toDouble(
      addon['price'] ??
          addon['addon_price'] ??
          addon['amount'] ??
          addon['monthly_price'] ??
          addon['subtotal'] ??
          0,
    );
  }

  int getAddonQuantity(dynamic addon) {
    if (addon is! Map) return 1;

    final quantity = _toInt(
      addon['quantity'] ??
          addon['qty'] ??
          addon['addon_quantity'] ??
          addon['addon_qty'] ??
          1,
    );

    if (quantity <= 0) return 1;
    return quantity;
  }

  double getAddonTotal(dynamic addon) {
    final explicitTotal = _toDouble(
      addon is Map
          ? addon['total'] ??
          addon['total_price'] ??
          addon['line_total'] ??
          addon['subtotal']
          : null,
    );

    if (explicitTotal > 0) {
      return explicitTotal;
    }

    return getAddonPrice(addon) * getAddonQuantity(addon);
  }

  bool _belongsToTenant(dynamic addon, int tenantId) {
    final addonTenantId = getTenantIdFromAddon(addon);

    /*
      Kalau response API memang endpoint-nya sudah spesifik tenant,
      biasanya data tidak membawa tenant_id. Dalam kasus itu, tetap anggap valid.
    */
    if (addonTenantId == 0) {
      return true;
    }

    return addonTenantId == tenantId;
  }

  List<dynamic> _filterAddonsByTenant(
      List<dynamic> data,
      int tenantId,
      ) {
    return data.where((addon) {
      return _belongsToTenant(addon, tenantId);
    }).toList();
  }

  double get totalAddonAmount {
    return _kosAddons.fold(0.0, (sum, addon) {
      return sum + getAddonPrice(addon);
    });
  }

  double get totalTenantAddonAmount {
    return _tenantAddons.fold(0.0, (sum, addon) {
      return sum + getAddonTotal(addon);
    });
  }

  int get assignedTenantAddonCount {
    return _tenantAddons.length;
  }

  List<int> get kosAddonIds {
    return _kosAddons
        .map<int>((addon) => getAddonId(addon))
        .where((id) => id > 0)
        .toList();
  }

  List<dynamic> get displayAddonsForTenantScreen {
    if (_tenantAddons.isNotEmpty) {
      return _tenantAddons;
    }

    if (_kosAddons.isNotEmpty) {
      return _kosAddons;
    }

    return [];
  }

  bool get hasAvailableAddons {
    return _kosAddons.isNotEmpty;
  }

  bool get hasAssignedTenantAddons {
    return _tenantAddons.isNotEmpty;
  }

  void _refreshGlobalLoading() {
    _isLoading = _isFetchingAddons ||
        _isCreatingAddon ||
        _isDeletingAddon ||
        _isClearingAddons ||
        _isFetchingTenants ||
        _isAddingToBill ||
        _isFetchingTenantAddons ||
        _isAssigningAddon ||
        _isRemovingAddon;
  }

  void _setError(dynamic error) {
    final text = error.toString().replaceAll('Exception: ', '').trim();

    if (text.isEmpty) {
      _errorMessage = 'Something went wrong';
      return;
    }

    final lowerText = text.toLowerCase();

    if (text.contains('401') ||
        lowerText.contains('unauthorized') ||
        lowerText.contains('token')) {
      _errorMessage = 'Session expired, please login again';
      return;
    }

    if (lowerText.contains('socket') ||
        lowerText.contains('network') ||
        lowerText.contains('connection')) {
      _errorMessage = 'Network error, please try again';
      return;
    }

    _errorMessage = text;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearAddonData() {
    _kosAddons = [];
    _addonTenants = [];
    _tenantAddons = [];
    _errorMessage = null;

    _isLoading = false;
    _isFetchingAddons = false;
    _isCreatingAddon = false;
    _isDeletingAddon = false;
    _isClearingAddons = false;
    _isFetchingTenants = false;
    _isAddingToBill = false;
    _isFetchingTenantAddons = false;
    _isAssigningAddon = false;
    _isRemovingAddon = false;

    notifyListeners();
  }

  void clearTenantAddonData() {
    _tenantAddons = [];
    _errorMessage = null;

    _isFetchingTenantAddons = false;
    _isAssigningAddon = false;
    _isRemovingAddon = false;

    _refreshGlobalLoading();
    notifyListeners();
  }

  bool isAddonAlreadyAdded(String name) {
    final targetName = _normalizeName(name);

    return _kosAddons.any((addon) {
      return _normalizeName(
        addon['name'] ?? addon['addon_name'],
      ) ==
          targetName;
    });
  }

  bool isTenantAddonAssigned(int addonId) {
    if (addonId <= 0) return false;

    return _tenantAddons.any((addon) {
      final currentAddonId = getAddonId(addon);
      return currentAddonId == addonId;
    });
  }

  bool isTenantAddonAssignedByName(String addonName) {
    final targetName = _normalizeName(addonName);

    if (targetName.isEmpty) return false;

    return _tenantAddons.any((addon) {
      final currentName = _normalizeName(
        addon['name'] ??
            addon['addon_name'] ??
            addon['addonName'] ??
            addon['item_name'] ??
            addon['title'],
      );

      return currentName == targetName;
    });
  }

  bool isTenantAddonAssignedFlexible({
    required int addonId,
    required String addonName,
  }) {
    if (addonId > 0 && isTenantAddonAssigned(addonId)) {
      return true;
    }

    return isTenantAddonAssignedByName(addonName);
  }

  Future<void> fetchKosAddons(
      String token,
      int kosId,
      ) async {
    _isFetchingAddons = true;
    _errorMessage = null;
    _refreshGlobalLoading();
    notifyListeners();

    try {
      if (token.isEmpty) {
        throw Exception('Session expired, please login again');
      }

      if (kosId <= 0) {
        throw Exception('Invalid kos selected');
      }

      final data = await _repo.getKosAddons(
        token,
        kosId,
      );

      _kosAddons = data;
    } catch (e) {
      _setError(e);

      /*
        Jangan langsung hapus _kosAddons kalau fetch gagal.
        Kalau sebelumnya sudah ada data di memory, biarkan tetap ada supaya UI
        tidak langsung kosong hanya karena request gagal.
      */
      if (_kosAddons.isEmpty) {
        _kosAddons = [];
      }
    } finally {
      _isFetchingAddons = false;
      _refreshGlobalLoading();
      notifyListeners();
    }
  }

  Future<bool> createAddon(
      String token,
      int kosId,
      String name,
      double price,
      ) async {
    _isCreatingAddon = true;
    _errorMessage = null;
    _refreshGlobalLoading();
    notifyListeners();

    try {
      final cleanName = name.trim();

      if (token.isEmpty) {
        throw Exception('Session expired, please login again');
      }

      if (kosId <= 0) {
        throw Exception('Invalid kos selected');
      }

      if (cleanName.isEmpty) {
        throw Exception('Add-on name is required');
      }

      if (price <= 0) {
        throw Exception('Add-on price must be greater than zero');
      }

      await _repo.createAddon(
        token,
        kosId,
        cleanName,
        price,
      );

      await fetchKosAddons(
        token,
        kosId,
      );

      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _isCreatingAddon = false;
      _refreshGlobalLoading();
      notifyListeners();
    }
  }

  Future<bool> deleteAddon(
      String token,
      int addonId,
      int kosId,
      ) async {
    _isDeletingAddon = true;
    _errorMessage = null;
    _refreshGlobalLoading();
    notifyListeners();

    try {
      if (token.isEmpty) {
        throw Exception('Session expired, please login again');
      }

      if (addonId <= 0) {
        throw Exception('Invalid add-on selected');
      }

      await _repo.deleteAddon(
        token,
        addonId,
      );

      await fetchKosAddons(
        token,
        kosId,
      );

      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _isDeletingAddon = false;
      _refreshGlobalLoading();
      notifyListeners();
    }
  }

  Future<bool> clearKosAddons(
      String token,
      int kosId,
      ) async {
    _isClearingAddons = true;
    _errorMessage = null;
    _refreshGlobalLoading();
    notifyListeners();

    try {
      if (token.isEmpty) {
        throw Exception('Session expired, please login again');
      }

      if (kosId <= 0) {
        throw Exception('Invalid kos selected');
      }

      await _repo.clearKosAddons(
        token,
        kosId,
      );

      _kosAddons = [];
      _tenantAddons = [];

      await fetchKosAddons(
        token,
        kosId,
      );

      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _isClearingAddons = false;
      _refreshGlobalLoading();
      notifyListeners();
    }
  }

  Future<void> fetchTenantsForAddon(
      String token,
      int kosId,
      ) async {
    _isFetchingTenants = true;
    _errorMessage = null;
    _refreshGlobalLoading();
    notifyListeners();

    try {
      if (token.isEmpty) {
        throw Exception('Session expired, please login again');
      }

      if (kosId <= 0) {
        throw Exception('Invalid kos selected');
      }

      _addonTenants = await _repo.getTenantsByKosForAddon(
        token,
        kosId,
      );
    } catch (e) {
      _setError(e);
      _addonTenants = [];
    } finally {
      _isFetchingTenants = false;
      _refreshGlobalLoading();
      notifyListeners();
    }
  }

  Future<bool> addAddonsToBill({
    required String token,
    required int kosId,
    required int tenantId,
    required List<int> addonIds,
  }) async {
    _isAddingToBill = true;
    _errorMessage = null;
    _refreshGlobalLoading();
    notifyListeners();

    try {
      final validAddonIds = addonIds.where((id) => id > 0).toSet().toList();

      if (token.isEmpty) {
        throw Exception('Session expired, please login again');
      }

      if (kosId <= 0) {
        throw Exception('Invalid kos selected');
      }

      if (tenantId <= 0) {
        throw Exception('Invalid tenant selected');
      }

      if (validAddonIds.isEmpty) {
        throw Exception('No valid add-ons selected');
      }

      await _repo.addAddonsToBill(
        token: token,
        kosId: kosId,
        tenantId: tenantId,
        addonIds: validAddonIds,
      );

      await fetchKosAddons(
        token,
        kosId,
      );

      await fetchTenantsForAddon(
        token,
        kosId,
      );

      await fetchTenantAddons(
        token,
        tenantId,
      );

      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _isAddingToBill = false;
      _refreshGlobalLoading();
      notifyListeners();
    }
  }

  Future<void> fetchTenantAddons(
      String token,
      int tenantId,
      ) async {
    _isFetchingTenantAddons = true;
    _errorMessage = null;
    _refreshGlobalLoading();
    notifyListeners();

    try {
      if (token.isEmpty) {
        throw Exception('Session expired, please login again');
      }

      if (tenantId <= 0) {
        throw Exception('Invalid tenant selected');
      }

      final data = await _repo.fetchTenantAddons(
        token,
        tenantId,
      );

      /*
        Ini penting:
        Kalau backend sudah benar mengembalikan add-ons khusus tenant tersebut,
        data akan langsung masuk.
        Kalau backend ternyata mengembalikan add-ons campuran dan ada field tenant_id,
        data akan difilter agar hanya punya tenantId yang sedang dibuka.
      */
      _tenantAddons = _filterAddonsByTenant(
        data,
        tenantId,
      );
    } catch (e) {
      _setError(e);

      if (_tenantAddons.isEmpty) {
        _tenantAddons = [];
      }
    } finally {
      _isFetchingTenantAddons = false;
      _refreshGlobalLoading();
      notifyListeners();
    }
  }

  Future<bool> assignAddon(
      String token,
      int tenantId,
      int addonId,
      ) async {
    _isAssigningAddon = true;
    _errorMessage = null;
    _refreshGlobalLoading();
    notifyListeners();

    try {
      if (token.isEmpty) {
        throw Exception('Session expired, please login again');
      }

      if (tenantId <= 0) {
        throw Exception('Invalid tenant selected');
      }

      if (addonId <= 0) {
        throw Exception('Invalid add-on selected');
      }

      await _repo.assignAddon(
        token,
        tenantId,
        addonId,
      );

      await fetchTenantAddons(
        token,
        tenantId,
      );

      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _isAssigningAddon = false;
      _refreshGlobalLoading();
      notifyListeners();
    }
  }

  Future<bool> removeAddon(
      String token,
      int tenantId,
      int addonId,
      ) async {
    _isRemovingAddon = true;
    _errorMessage = null;
    _refreshGlobalLoading();
    notifyListeners();

    try {
      if (token.isEmpty) {
        throw Exception('Session expired, please login again');
      }

      if (tenantId <= 0) {
        throw Exception('Invalid tenant selected');
      }

      if (addonId <= 0) {
        throw Exception('Invalid add-on selected');
      }

      await _repo.removeAddon(
        token,
        tenantId,
        addonId,
      );

      await fetchTenantAddons(
        token,
        tenantId,
      );

      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _isRemovingAddon = false;
      _refreshGlobalLoading();
      notifyListeners();
    }
  }

  Future<bool> assignAddonIfNotExists(
      String token,
      int tenantId,
      int addonId,
      String addonName,
      ) async {
    if (isTenantAddonAssignedFlexible(
      addonId: addonId,
      addonName: addonName,
    )) {
      _errorMessage = null;
      notifyListeners();
      return true;
    }

    return assignAddon(
      token,
      tenantId,
      addonId,
    );
  }

  bool isAddonActive(dynamic addon) {
    if (addon is! Map) return true;

    final rawStatus = addon['is_active'] ??
        addon['active'] ??
        addon['status'] ??
        addon['is_assigned'];

    if (rawStatus == null) return true;

    return _isSuccessStatus(rawStatus);
  }

  List<dynamic> get activeTenantAddons {
    return _tenantAddons.where(isAddonActive).toList();
  }

  List<dynamic> get activeKosAddons {
    return _kosAddons.where(isAddonActive).toList();
  }
}
