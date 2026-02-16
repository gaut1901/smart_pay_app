import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import 'auth_service.dart';

class ReimbursementRequest {
  final String id;
  final String ticketNo;
  final String empName;
  final String edName;
  final String sDate;
  final double amount;
  final String app;
  final String appBy;
  final String payDate;

  ReimbursementRequest({
    required this.id,
    required this.ticketNo,
    required this.empName,
    required this.edName,
    required this.sDate,
    required this.amount,
    required this.app,
    required this.appBy,
    required this.payDate,
  });

  factory ReimbursementRequest.fromJson(Map<String, dynamic> json) {
    return ReimbursementRequest(
      id: json['id']?.toString() ?? '',
      ticketNo: json['TicketNo']?.toString() ?? '',
      empName: json['EmpName']?.toString() ?? '',
      edName: json['EDName']?.toString() ?? '',
      sDate: json['SDate']?.toString() ?? '',
      amount: (json['Amount'] is num) ? (json['Amount'] as num).toDouble() : 0.0,
      app: json['App']?.toString() ?? '',
      appBy: json['AppBy']?.toString() ?? '',
      payDate: json['PayDate']?.toString() ?? '',
    );
  }
}

class ReimbursementService {
  Future<List<ReimbursementRequest>> getReimbursementHistory() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empreim/getlist/');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = jsonDecode(data['response']);
        final List<dynamic> list = responseData['dtList'] ?? [];
        return list.map((item) => ReimbursementRequest.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load reimbursement history: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getReimbursementLookup() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empreim/clear/?action=Create');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to load reimbursement lookup: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getEDDetail(String edName) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empreim/geteddetail/?edname=$edName');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to load ED details: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getReimbursementDetail(String id, String action) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empreim/display/?id=$id&action=$action');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to load reimbursement details: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> submitReimbursementRequest({
    required String sDate,
    required double amount,
    required double maxAllowed,
    required String unlimited,
    required String empName,
    required String edName,
    File? file,
    String actions = "Add",
    String editId = "",
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empreim/submit/');
    
    var request = http.MultipartRequest('POST', url);
    
    // Add headers
    final headers = user.toHeaders();
    headers.forEach((key, value) {
      if (key != 'Content-Type') { // MultipartRequest sets its own Content-Type
        request.headers[key] = value;
      }
    });

    // Add fields
    request.fields['SDate'] = sDate;
    request.fields['Amount'] = amount.toString();
    request.fields['MaxAllowed'] = maxAllowed.toString();
    request.fields['Unlimited'] = unlimited;
    request.fields['EmpName'] = empName;
    request.fields['EDName'] = edName;
    request.fields['editid'] = editId;
    request.fields['actions'] = actions;

    // Add file if exists
    if (file != null) {
      final fileName = file.path.split('/').last;
      var multipartFile = await http.MultipartFile.fromPath(
        fileName, 
        file.path,
        filename: fileName,
      );
      request.files.add(multipartFile);
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = jsonDecode(data['response']);
        if (responseData['JSONResult'] != 0) {
          throw Exception(responseData['error'] ?? 'Failed to submit reimbursement request');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
