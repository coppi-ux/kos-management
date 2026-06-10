import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  String? get token => _user?.token;

  final AuthRepository _repo = AuthRepository();

  //LOAD TOKEN SAAT APP START
  Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token');
      final name = prefs.getString('name');
      final email = prefs.getString('email');
      final userId = prefs.getInt('userId');

      if (token != null && name != null && email != null && userId != null) {
        _user = UserModel(
          id: userId,
          name: name,
          email: email,
          token: token,
        );

        print("✅ TOKEN LOADED FROM PREFS");
      }

    } catch (e) {
      print("❌ LOAD PREFS ERROR: $e");
    }

    notifyListeners();
  }

  //LOGIN
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("🚀 LOGIN START");

      _user = await _repo.login(email, password);

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('token', _user!.token);
      await prefs.setString('name', _user!.name);
      await prefs.setString('email', _user!.email);
      await prefs.setInt('userId', _user!.id);

      print("✅ LOGIN SUCCESS");
      print("TOKEN SAVE: ${_user!.token}");

      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      print("❌ LOGIN ERROR: $e");

      _errorMessage = e.toString().replaceAll('Exception: ', '');

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  //REGISTER
  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("🚀 REGISTER START");

      await _repo.register(name, email, password);

      print("✅ REGISTER SUCCESS");

      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      print("❌ REGISTER ERROR: $e");

      _errorMessage = e.toString().replaceAll('Exception: ', '');

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  //LOGOUT (AUTO HANDLE TOKEN INVALID)
  Future<void> logout() async {
    print("🚪 LOGOUT TRIGGERED");

    _user = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }

  //HANDLE TOKEN EXPIRED
  Future<void> handleUnauthorized() async {
    print("⚠️ TOKEN EXPIRED - AUTO LOGOUT");
    await logout();
  }
}