import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class BillService {

  //GET ALL BILLS BY KOS
  Future<List<dynamic>> getBillsByKos(String token, int kosId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/bills/$kosId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    //DEBUG (penting kalau kosong)
    //print("GET BILLS RESPONSE: $data");

    if (response.statusCode == 200) {
      if (data is List) return data;
      if (data['bills'] != null) return data['bills'];
      if (data['data'] != null) return data['data'];
      return [];
    }

    throw Exception(data['message'] ?? 'Failed to fetch bills');
  }


  //GET OVERDUE BILLS
  Future<List<dynamic>> getOverdueBills(String token, int kosId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/bills/overdue/$kosId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    // print("OVERDUE RESPONSE: $data");
    if (response.statusCode == 200) {
      if (data is List) return data;
      if (data['overdue_bills'] != null) return data['overdue_bills'];
      if (data['bills'] != null) return data['bills'];
      return [];
    }

    throw Exception(data['message'] ?? 'Failed to fetch overdue bills');
  }

  //MARK BILL AS PAID
  Future<void> markPaid(String token, int billId) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/bills/$billId/pay'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    // print("PAY RESPONSE: $data");

    if (response.statusCode == 200) {
      return;
    }

    throw Exception(data['message'] ?? 'Failed to mark bill as paid');
  }


  //GENERATE BILLS (FIXED FINAL)
  Future<void> generateBills(String token, int kosId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/bills/generate/$kosId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    //DEBUG WAJIB (lihat ini di console)
    print("GENERATE RESPONSE STATUS: ${response.statusCode}");
    print("GENERATE RESPONSE BODY: $data");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    throw Exception(
        data['message'] ?? 'Failed to generate bills from server');
  }
}