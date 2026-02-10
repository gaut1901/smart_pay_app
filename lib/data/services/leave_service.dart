import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import '../models/leave_model.dart';
import 'auth_service.dart';

class LeaveService {
  Future<List<LeaveRequest>> getLeaveHistory() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/emplreq/getlist/');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = jsonDecode(data['response']);
        final List<dynamic> list = responseData['dtList'] ?? [];
        return list.map((item) => LeaveRequest.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load leave history: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<LeaveBalance>> getLeaveBalance() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final url = Uri.parse('${ApiConfig.baseUrl}api/emplreq/getLeaveBalance/?fdate=$dateStr');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> responseData = jsonDecode(data['response']);
        return responseData.map((item) => LeaveBalance.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load leave balance: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getLeaveLookup() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/emplreq/clear/?action=Create');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to load leave lookup: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> statusChange({
    required String fDate,
    required String tDate,
    required String fText,
    required String tText,
    required String status,
    String actions = 'Add',
    String editId = '',
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/emplreq/statuschange');
    
    final postData = {
      'fdate': fDate,
      'tdate': tDate,
      'ftext': fText,
      'ttext': tText,
      'empname': user.empName,
      'status': status,
      'actions': actions,
      'editid': editId,
    };

    try {
      final response = await http.post(
        url,
        headers: user.toHeaders(),
        body: jsonEncode(postData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to check status: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> uploadMedicalCertificate(String fileName, List<int> bytes) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/emplreq/MCFileUpload/');
    
    try {
      var request = http.MultipartRequest('POST', url);
      request.headers.addAll(user.toHeaders());
      
      request.files.add(http.MultipartFile.fromBytes(
        fileName,
        bytes,
        filename: fileName,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to upload medical certificate: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> submitLeaveRequest({
    required String sDate,
    required String fDate,
    required String tDate,
    required String remarks,
    required String status,
    required String lrName,
    required String fText,
    required String tText,
    double days = 0,
    String filePath = "",
    bool mcReq = false,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/emplreq/submit/');
    
    final postData = {
      "SDate": sDate,
      "FromDate": fDate,
      "ToDate": tDate,
      "Remarks": remarks,
      "Status": status,
      "LRName": lrName,
      "FText": fText,
      "TText": tText,
      "Days": days,
      "Revise": false,
      "App": "-",
      "App1": "-",
      "OldFromDate": "",
      "OldToDate": "",
      "OldRemarks": "",
      "OldStatus": "",
      "OldLRName": "",
      "OldFText": "",
      "OldTText": "",
      "FilePath": filePath,
      "MCReq": mcReq,
      "OldDays": 0,
      "CoffText": "",
      "Actions": "Add",
      "EditId": ""
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
          throw Exception(responseData['error'] ?? 'Failed to submit leave request');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
