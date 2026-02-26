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

  Future<List<LeaveRequest>> getSupplementaryHistory() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

      final url = Uri.parse('${ApiConfig.baseUrl}api/empsappreq/getlist/');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = jsonDecode(data['response']);
        final List<dynamic> list = responseData['dtList'] ?? responseData['dtLapp'] ?? [];
        return list.map((item) => LeaveRequest.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load supplementary history: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<LeaveBalance>> getLeaveBalance({DateTime? date}) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final targetDate = date ?? DateTime.now();
    final dateStr = '${targetDate.day.toString().padLeft(2, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.year}';
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

  Future<Map<String, dynamic>> getLeaveRequestDetails(String id, String action) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/emplreq/display/?id=$id&action=$action');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to load leave details: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSupplementaryDetails(String id, {String action = 'View'}) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empsappreq/display/?id=$id&action=$action');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to load supplementary details: ${response.statusCode}');
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
    required String sDate, // Req date
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
    String actions = "Add",
    String editId = "",
    bool revise = false,
    Map<String, dynamic>? oldDetails,
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
      "Revise": revise,
      "App": "-",
      "App1": "-",
      "OldFromDate": oldDetails?['OldFromDate'] ?? oldDetails?['FromDate'] ?? "",
      "OldToDate": oldDetails?['OldToDate'] ?? oldDetails?['ToDate'] ?? "",
      "OldRemarks": oldDetails?['OldRemarks'] ?? oldDetails?['Remarks'] ?? "",
      "OldStatus": oldDetails?['OldStatus'] ?? oldDetails?['Status'] ?? "",
      "OldLRName": oldDetails?['OldLRName'] ?? oldDetails?['LRName'] ?? "",
      "OldFText": oldDetails?['OldFText'] ?? oldDetails?['FText'] ?? "",
      "OldTText": oldDetails?['OldTText'] ?? oldDetails?['TText'] ?? "",
      "FilePath": filePath,
      "MCReq": mcReq,
      "OldDays": oldDetails?['OldDays'] ?? oldDetails?['Days'] ?? 0,
      "CoffText": "",
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
        if (responseData['JSONResult'].toString() != '0') {
          throw Exception(responseData['error'] ?? 'Failed to submit leave request');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
  Future<List<String>> getEmployeeLeaveHeaders() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empleavebalance/getlist');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = jsonDecode(data['response']);
        final List<dynamic> heads = responseData['dtSalaryName'] ?? [];
        return heads.map((e) => e['LeaveHead'].toString()).toList();
      } else {
        throw Exception('Failed to load leave headers: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, List<dynamic>>> getLeaveBalanceDetails({
    required String fDate,
    required String tDate,
    required String salaryName,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empleavebalance/view/?fdate=$fDate&tdate=$tDate&salaryname=$salaryName');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = jsonDecode(data['response']);
        return {
          'dt': List<dynamic>.from(responseData['dt'] ?? []),
          'dt1': List<dynamic>.from(responseData['dt1'] ?? []),
          'dt2': List<dynamic>.from(responseData['dt2'] ?? []),
          'dt3': List<dynamic>.from(responseData['dt3'] ?? []),
        };
      } else {
        throw Exception('Failed to load leave balance details: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> submitSupplementaryRequest({
    required String sDate,
    required String fDate,
    required String tDate,
    required String remarks,
    required String status,
    required String lrName,
    String fText = "Full Day",
    String tText = "Full Day",
    String actions = "Create",
    String editId = "",
    Map<String, dynamic>? oldDetails,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empsappreq/submit/');
    
    final postData = {
      "SDate": sDate,
      "FromDate": fDate,
      "ToDate": tDate,
      "Remarks": remarks,
      "Status": status,
      "LRName": lrName,
      "FText": fText,
      "TText": tText,
      "Days": 0,
      "Revise": actions == "Revise",
      "App": oldDetails?['App'] ?? "-",
      "App1": oldDetails?['App1'] ?? "-",
      "OldFromDate": oldDetails?['FromDate'] ?? fDate,
      "OldToDate": oldDetails?['ToDate'] ?? tDate,
      "OldRemarks": oldDetails?['Remarks'] ?? remarks,
      "OldStatus": oldDetails?['Status'] ?? status,
      "OldLRName": oldDetails?['LRName'] ?? lrName,
      "OldFText": oldDetails?['FText'] ?? fText,
      "OldTText": oldDetails?['TText'] ?? tText,
      "FilePath": "",
      "MCReq": false,
      "OldDays": 0,
      "CoffText": "",
      "Actions": actions,
      "EditId": editId,
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
        if (responseData['JSONResult'] == 1) {
          throw Exception(responseData['error'] ?? 'Failed to submit supplementary request');
        }
      } else {
        throw Exception('Failed to submit supplementary request: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<LeaveBalance>> getSupplementaryLeaveBalance(String fDate) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empsappreq/getLeaveBalance/?fdate=$fDate');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = jsonDecode(data['response']);
        return list.map((item) => LeaveBalance.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load supplementary leave balance: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
