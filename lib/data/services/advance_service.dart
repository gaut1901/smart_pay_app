import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import 'auth_service.dart';

class AdvanceRequest {
  final String id;
  final String ticketNo;
  final String empName;
  final String edName;
  final String sDate;
  final double advAmount;
  final String app;
  final String appBy;

  AdvanceRequest({
    required this.id,
    required this.ticketNo,
    required this.empName,
    required this.edName,
    required this.sDate,
    required this.advAmount,
    required this.app,
    required this.appBy,
  });

  factory AdvanceRequest.fromJson(Map<String, dynamic> json) {
    return AdvanceRequest(
      id: json['id']?.toString() ?? '',
      ticketNo: json['TicketNo']?.toString() ?? '',
      empName: json['EmpName']?.toString() ?? '',
      edName: json['EDName']?.toString() ?? '',
      sDate: json['SDate']?.toString() ?? '',
      advAmount: (json['AdvAmount'] is num) ? (json['AdvAmount'] as num).toDouble() : 0.0,
      app: json['App']?.toString() ?? '',
      appBy: json['AppBy']?.toString() ?? '',
    );
  }
}

class AdvanceAdjustmentRequest {
  final String id;
  final String ticketNo;
  final String empName;
  final String reqDate;
  final String salaryName;
  final double adjAmount;
  final String app;
  final String appBy;

  AdvanceAdjustmentRequest({
    required this.id,
    required this.ticketNo,
    required this.empName,
    required this.reqDate,
    required this.salaryName,
    required this.adjAmount,
    required this.app,
    required this.appBy,
  });

  factory AdvanceAdjustmentRequest.fromJson(Map<String, dynamic> json) {
    return AdvanceAdjustmentRequest(
      id: json['id']?.toString() ?? '',
      ticketNo: json['TicketNo']?.toString() ?? '',
      empName: json['EmpName']?.toString() ?? '',
      reqDate: json['ReqDate']?.toString() ?? '',
      salaryName: json['SalaryName']?.toString() ?? '',
      adjAmount: (json['AdjAmount'] is num) ? (json['AdjAmount'] as num).toDouble() : 0.0,
      app: json['App']?.toString() ?? '',
      appBy: json['AppBy']?.toString() ?? '',
    );
  }
}

class AdvanceService {
  // Advance Request Methods
  Future<List<AdvanceRequest>> getAdvanceHistory() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empadv/getlist/');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = jsonDecode(data['response']);
        final List<dynamic> list = responseData['dtList'] ?? [];
        return list.map((item) => AdvanceRequest.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load advance history: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAdvanceLookup({String action = 'Create'}) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empadv/clear/?action=$action');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to load advance lookup: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAdvanceDetails(String id, String action) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empadv/display/?id=$id&action=$action');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to load advance details: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> submitAdvanceRequest(Map<String, dynamic> postData) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empadv/submit/');
    
    try {
      final response = await http.post(
        url,
        headers: user.toHeaders(),
        body: jsonEncode(postData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = jsonDecode(data['response']);
        if (responseData['JSONResult'].toString() != '0') {
          throw Exception(responseData['error'] ?? 'Failed to submit advance request');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Advance Adjustment Request (AAR) Methods
  Future<List<AdvanceAdjustmentRequest>> getAARHistory() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empaar/getlist/');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = jsonDecode(data['response']);
        final List<dynamic> list = responseData['dtList'] ?? [];
        return list.map((item) => AdvanceAdjustmentRequest.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load AAR history: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAARLookup({String action = 'Create'}) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empaar/clear/?action=$action');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to load AAR lookup: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAARDetails(String id, String action) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empaar/display/?id=$id&action=$action');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to load AAR details: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getAdvanceNos() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empaar/getadvnos/');
    
    // The legacy code sends it as FormData but POST
    // We can try sending empty empname as per legacy
    var request = http.MultipartRequest('POST', url);
    final headers = user.toHeaders();
    headers.forEach((key, value) {
      if (key != 'Content-Type') request.headers[key] = value;
    });
    request.fields['empname'] = "";

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = jsonDecode(data['response']);
        return responseData['dtAdvNo'] ?? [];
      } else {
        throw Exception('Failed to load advance numbers: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> submitAARRequest(Map<String, dynamic> postData) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empaar/submit/');
    
    try {
      final response = await http.post(
        url,
        headers: user.toHeaders(),
        body: jsonEncode(postData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = jsonDecode(data['response']);
        if (responseData['JSONResult'].toString() != '0') {
          throw Exception(responseData['error'] ?? 'Failed to submit AAR request');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
