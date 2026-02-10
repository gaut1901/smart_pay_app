import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import '../models/payslip_model.dart';
import 'auth_service.dart';

class PayslipService {
  Future<PayslipLookupResponse> getPayslipLookup() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.payslipLookup}');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = jsonDecode(data['response']);
        return PayslipLookupResponse.fromJson(responseData);
      } else {
        throw Exception('Failed to load payslip lookup: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getPayslipHtml(String salaryName, String templateName) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.payslipView}/?salaryname=$salaryName&templatename=$templateName');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response']; // This is the data:application/html;base64,... string
      } else {
        throw Exception('Failed to load payslip: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
