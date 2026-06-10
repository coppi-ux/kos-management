import '../services/sheets_service.dart';

class SheetsRepository {
  final SheetsService _service = SheetsService();

  Future<Map<String, dynamic>> sync(String token, int kosId) async {
    try {
      return await _service.sync(token, kosId);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}