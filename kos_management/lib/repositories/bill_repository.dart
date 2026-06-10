import '../services/bill_service.dart';

class BillRepository {
  final BillService _service = BillService();

  //FETCH ALL BILLS
  Future<List<dynamic>> getBillsByKos(String token, int kosId) async {
    try {
      return await _service.getBillsByKos(token, kosId);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  //FETCH OVERDUE BILLS
  Future<List<dynamic>> getOverdueBills(String token, int kosId) async {
    try {
      return await _service.getOverdueBills(token, kosId);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  //MARK BILL AS PAID
  Future<void> markPaid(String token, int billId) async {
    try {
      await _service.markPaid(token, billId);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  //FIXED GENERATE BILLS
  Future<bool> generateBills(String token, int kosId) async {
    try {
      await _service.generateBills(token, kosId);
      return true; //return manual, bukan dari service
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}