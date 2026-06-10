import 'package:flutter/material.dart';
import '../repositories/kos_repository.dart';
import '../repositories/room_repository.dart';

class KosProvider extends ChangeNotifier {
  final KosRepository _kosRepo = KosRepository();
  final RoomRepository _roomRepo = RoomRepository();

  List<dynamic> _kosList = [];
  dynamic _selectedKos;
  List<dynamic> _roomTypes = [];
  List<dynamic> _rooms = [];
  List<dynamic> _tenants = [];

  bool _isFetchingKos = false;
  bool _isCreatingKos = false;
  bool _isUpdatingKos = false;
  bool _isDeletingKos = false;

  bool _isFetchingRoomTypes = false;
  bool _isMutatingRoomType = false;

  bool _isFetchingRooms = false;
  bool _isMutatingRoom = false;

  bool _isFetchingTenants = false;
  bool _isMutatingTenant = false;

  String? _errorMessage;

  List<dynamic> get kosList => _kosList;
  dynamic get selectedKos => _selectedKos;
  List<dynamic> get roomTypes => _roomTypes;
  List<dynamic> get rooms => _rooms;
  List<dynamic> get tenants => _tenants;

  bool get isFetchingKos => _isFetchingKos;
  bool get isCreatingKos => _isCreatingKos;
  bool get isUpdatingKos => _isUpdatingKos;
  bool get isDeletingKos => _isDeletingKos;

  bool get isFetchingRoomTypes => _isFetchingRoomTypes;
  bool get isMutatingRoomType => _isMutatingRoomType;

  bool get isFetchingRooms => _isFetchingRooms;
  bool get isMutatingRoom => _isMutatingRoom;

  bool get isFetchingTenants => _isFetchingTenants;
  bool get isMutatingTenant => _isMutatingTenant;

  bool get isLoading {
    return _isCreatingKos ||
        _isUpdatingKos ||
        _isDeletingKos ||
        _isMutatingRoomType ||
        _isMutatingRoom ||
        _isMutatingTenant;
  }

  bool get isFetching {
    return _isFetchingKos ||
        _isFetchingRoomTypes ||
        _isFetchingRooms ||
        _isFetchingTenants;
  }

  String? get errorMessage => _errorMessage;

  void _setError(dynamic error) {
    print("PROVIDER ERROR: $error");

    final errorText = error.toString();

    if (errorText.contains("UNAUTHORIZED") ||
        errorText.contains("Unauthorized") ||
        errorText.contains("401")) {
      _errorMessage = "Session expired, please login again";
    } else {
      _errorMessage = errorText.replaceAll('Exception: ', '');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  int? getSelectedKosId() {
    if (_selectedKos == null) return null;

    final id = _selectedKos['id'];

    if (id is int) return id;
    if (id is String) return int.tryParse(id);

    return null;
  }

  void clearSelectedKos() {
    _selectedKos = null;
    _roomTypes = [];
    _rooms = [];
    _tenants = [];
    notifyListeners();
  }

  void selectKos(dynamic kos) {
    _selectedKos = kos;
    _rooms = [];
    _tenants = [];
    _roomTypes = [];
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchMyKos(String token) async {
    _isFetchingKos = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("FETCH MY KOS");

      _kosList = await _kosRepo.getMyKos(token);

      if (_kosList.isNotEmpty && _selectedKos == null) {
        _selectedKos = _kosList[0];
      }

      if (_selectedKos != null) {
        final updated = _kosList
            .where(
              (k) => k['id'].toString() == _selectedKos['id'].toString(),
        )
            .toList();

        if (updated.isNotEmpty) {
          _selectedKos = updated[0];
        } else {
          _selectedKos = _kosList.isNotEmpty ? _kosList[0] : null;
        }
      }

      if (_kosList.isEmpty) {
        _selectedKos = null;
        _roomTypes = [];
        _rooms = [];
        _tenants = [];
      }
    } catch (e) {
      print("FETCH KOS ERROR: $e");
      _setError(e);
    } finally {
      _isFetchingKos = false;
      notifyListeners();
    }
  }

  Future<bool> createKos(String token, String name, String address) async {
    _isCreatingKos = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("CREATE KOS PROVIDER");

      final result = await _kosRepo.createKos(token, name, address);

      print("CREATE KOS SUCCESS: $result");

      await fetchMyKos(token);

      final newKosId = result['kos_id'] ?? result['kos']?['id'];

      if (newKosId != null) {
        final newKos = _kosList
            .where((k) => k['id'].toString() == newKosId.toString())
            .toList();

        if (newKos.isNotEmpty) {
          _selectedKos = newKos[0];
        }
      }

      return true;
    } catch (e) {
      print("CREATE KOS ERROR: $e");
      _setError(e);
      return false;
    } finally {
      _isCreatingKos = false;
      notifyListeners();
    }
  }

  Future<bool> updateKos(
      String token,
      int kosId,
      String name,
      String address,
      ) async {
    _isUpdatingKos = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("UPDATE KOS PROVIDER");
      print("KOS ID: $kosId");

      final result = await _kosRepo.updateKos(
        token,
        kosId,
        name,
        address,
      );

      print("UPDATE KOS SUCCESS: $result");

      await fetchMyKos(token);

      final updatedKos = _kosList
          .where((k) => k['id'].toString() == kosId.toString())
          .toList();

      if (updatedKos.isNotEmpty) {
        _selectedKos = updatedKos[0];
      }

      return true;
    } catch (e) {
      print("UPDATE KOS ERROR: $e");
      _setError(e);
      return false;
    } finally {
      _isUpdatingKos = false;
      notifyListeners();
    }
  }

  Future<bool> deleteKos(String token, int kosId) async {
    _isDeletingKos = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("DELETE KOS PROVIDER");
      print("KOS ID: $kosId");

      final result = await _kosRepo.deleteKos(token, kosId);

      print("DELETE KOS SUCCESS: $result");

      await fetchMyKos(token);

      if (_selectedKos != null &&
          _selectedKos['id'].toString() == kosId.toString()) {
        _selectedKos = _kosList.isNotEmpty ? _kosList[0] : null;
      }

      if (_selectedKos == null) {
        _roomTypes = [];
        _rooms = [];
        _tenants = [];
      }

      return true;
    } catch (e) {
      print("DELETE KOS ERROR: $e");
      _setError(e);
      return false;
    } finally {
      _isDeletingKos = false;
      notifyListeners();
    }
  }

  Future<void> fetchRoomTypes(String token, int kosId) async {
    _isFetchingRoomTypes = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("FETCH ROOM TYPES");
      print("KOS ID: $kosId");

      _roomTypes = await _kosRepo.getRoomTypes(token, kosId);
    } catch (e) {
      print("ROOM TYPES ERROR: $e");
      _setError(e);
    } finally {
      _isFetchingRoomTypes = false;
      notifyListeners();
    }
  }

  Future<bool> createRoomType(
      String token,
      int kosId,
      String name,
      double price,
      ) async {
    _isMutatingRoomType = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("CREATE ROOM TYPE");
      print("KOS ID: $kosId");

      await _kosRepo.createRoomType(
        token,
        kosId,
        name,
        price,
      );

      print("CREATE ROOM TYPE SUCCESS");

      await fetchRoomTypes(token, kosId);

      return true;
    } catch (e) {
      print("CREATE ROOM TYPE ERROR: $e");
      _setError(e);
      return false;
    } finally {
      _isMutatingRoomType = false;
      notifyListeners();
    }
  }

  Future<bool> updateRoomType(
      String token,
      int kosId,
      int roomTypeId,
      String name,
      double price,
      ) async {
    _isMutatingRoomType = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("UPDATE ROOM TYPE");
      print("KOS ID: $kosId");
      print("ROOM TYPE ID: $roomTypeId");

      final result = await _kosRepo.updateRoomType(
        token,
        kosId,
        roomTypeId,
        name,
        price,
      );

      print("UPDATE ROOM TYPE SUCCESS: $result");

      await fetchRoomTypes(token, kosId);

      return true;
    } catch (e) {
      print("UPDATE ROOM TYPE ERROR: $e");
      _setError(e);
      return false;
    } finally {
      _isMutatingRoomType = false;
      notifyListeners();
    }
  }

  Future<bool> deleteRoomType(
      String token,
      int kosId,
      int roomTypeId,
      ) async {
    _isMutatingRoomType = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("DELETE ROOM TYPE");
      print("KOS ID: $kosId");
      print("ROOM TYPE ID: $roomTypeId");

      final result = await _kosRepo.deleteRoomType(
        token,
        kosId,
        roomTypeId,
      );

      print("DELETE ROOM TYPE SUCCESS: $result");

      await fetchRoomTypes(token, kosId);

      return true;
    } catch (e) {
      print("DELETE ROOM TYPE ERROR: $e");
      _setError(e);
      return false;
    } finally {
      _isMutatingRoomType = false;
      notifyListeners();
    }
  }

  Future<void> fetchRooms(String token, int kosId) async {
    _isFetchingRooms = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("FETCH ROOMS");
      print("KOS ID: $kosId");

      _rooms = await _roomRepo.getRooms(token, kosId);
    } catch (e) {
      print("FETCH ROOMS ERROR: $e");
      _setError(e);
    } finally {
      _isFetchingRooms = false;
      notifyListeners();
    }
  }

  Future<bool> createRoom(
      String token,
      int kosId,
      int roomTypeId,
      String roomNumber,
      ) async {
    _isMutatingRoom = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("CREATE ROOM");
      print("KOS ID: $kosId");
      print("ROOM TYPE ID: $roomTypeId");
      print("ROOM NUMBER: $roomNumber");

      await _roomRepo.createRoom(
        token,
        kosId,
        roomTypeId,
        roomNumber,
      );

      print("CREATE ROOM SUCCESS");

      await fetchRooms(token, kosId);

      return true;
    } catch (e) {
      print("CREATE ROOM ERROR: $e");
      _setError(e);
      return false;
    } finally {
      _isMutatingRoom = false;
      notifyListeners();
    }
  }

  Future<void> fetchTenants(
      String token,
      int kosId, {
        bool activeOnly = true,
      }) async {
    _isFetchingTenants = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("FETCH TENANTS");
      print("KOS ID: $kosId");

      _tenants = await _roomRepo.getTenants(
        token,
        kosId,
        activeOnly: activeOnly,
      );
    } catch (e) {
      print("FETCH TENANTS ERROR: $e");
      _setError(e);
    } finally {
      _isFetchingTenants = false;
      notifyListeners();
    }
  }

  Future<bool> addTenant(
      String token,
      String name,
      String email,
      String phone,
      int roomId,
      String startDate,
      ) async {
    _isMutatingTenant = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("ADD TENANT");
      print("ROOM ID: $roomId");

      await _roomRepo.addTenant(
        token,
        name,
        email,
        phone,
        roomId,
        startDate,
      );

      print("ADD TENANT SUCCESS");

      final kosId = getSelectedKosId();

      if (kosId != null) {
        await fetchTenants(token, kosId);
        await fetchRooms(token, kosId);
      }

      return true;
    } catch (e) {
      print("ADD TENANT ERROR: $e");
      _setError(e);
      return false;
    } finally {
      _isMutatingTenant = false;
      notifyListeners();
    }
  }

  Future<void> refreshSelectedKosData(String token) async {
    final kosId = getSelectedKosId();

    if (kosId == null) {
      print("No selected kos to refresh");
      return;
    }

    await fetchRoomTypes(token, kosId);
    await fetchRooms(token, kosId);
    await fetchTenants(token, kosId);
  }
}
