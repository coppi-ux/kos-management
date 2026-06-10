import '../models/tenant_model.dart';
import '../services/tenant_auth_service.dart';

class TenantAuthRepository {
  final TenantAuthService _service = TenantAuthService();

  String _cleanError(Object error) {
    return error.toString().replaceAll('Exception: ', '').trim();
  }

  Future<String> setupPassword(
      String email,
      String password,
      ) async {
    try {
      return await _service.setupPassword(
        email,
        password,
      );
    } catch (e) {
      final message = _cleanError(e);

      if (message.isEmpty) {
        throw Exception('Failed to set password');
      }

      throw Exception(message);
    }
  }

  Future<TenantModel> login(
      String email,
      String password,
      ) async {
    try {
      return await _service.login(
        email,
        password,
      );
    } catch (e) {
      final message = _cleanError(e);

      if (message.isEmpty) {
        throw Exception('Failed to login');
      }

      throw Exception(message);
    }
  }
}
