import '../services/analytics_service.dart';

class AnalyticsRepository {
  final AnalyticsService _service = AnalyticsService();

  Future<Map<String, dynamic>> getDashboardStats(
      String token, int kosId) async {
    try {
      return await _service.getDashboardStats(token, kosId);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<List<dynamic>> getTenantPaymentHistory(
      String token, int tenantId) async {
    try {
      return await _service.getTenantPaymentHistory(token, tenantId);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}