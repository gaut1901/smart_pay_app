import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import 'auth_service.dart';

class CompOffRequest {
  final String id;
  final String ticketNo;
  final String empName;
  final String sDate;
  final String status;
  final double days;
  final String app;
  final String appBy;

  CompOffRequest({
    required this.id,
    required this.ticketNo,
    required this.empName,
    required this.sDate,
    required this.status,
    required this.days,
    required this.app,
    required this.appBy,
  });

  factory CompOffRequest.fromJson(Map<String, dynamic> json) {
    return CompOffRequest(
      id: json['id']?.toString() ?? '',
      ticketNo: json['TicketNo']?.toString() ?? '',
      empName: json['EmpName']?.toString() ?? '',
      sDate: json['SDate']?.toString() ?? '',
      status: json['Status']?.toString() ?? '',
      days: (json['Days'] is num) ? (json['Days'] as num).toDouble() : 0.0,
      app: json['App']?.toString() ?? '',
      appBy: json['AppBy']?.toString() ?? '',
    );
  }
}

class CompOffService {
  Future<List<CompOffRequest>> getCompOffHistory() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/emplgreq/getlist/');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = jsonDecode(data['response']);
        final List<dynamic> list = responseData['dtList'] ?? [];
        return list.map((item) => CompOffRequest.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load compensation history: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCompOffLookup() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/emplgreq/clear/?action=Create');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to load compensation lookup: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> submitCompOffRequest({
    required String sDate,
    required String remarks,
    required String status,
    required String lrName,
    String actions = "Add",
    String editId = "",
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/emplgreq/submit/');
    
    final postData = {
      "SDate": sDate,
      "Remarks": remarks,
      "Status": status,
      "LRName": lrName,
      "App": "-",
      "Actions": actions,
      "EditId": editId
    };

    try {
      final response = await http.post(
        url,
        headers: user.toHeaders(),
        body: jsonEncode(postData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = jsonDecode(data['response']);
        if (responseData['JSONResult'] != 0) {
          throw Exception(responseData['error'] ?? 'Failed to submit compensation request');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
