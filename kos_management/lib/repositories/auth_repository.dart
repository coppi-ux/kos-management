import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final AuthService _service = AuthService();

  Future<String> register(String name, String email, String password) async {
    try {
      return await _service.register(name, email, password);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<UserModel> login(String email, String password) async {
    try {
      return await _service.login(email, password);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}