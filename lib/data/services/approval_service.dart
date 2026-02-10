import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import 'auth_service.dart';

class ApprovalSummary {
  final int attendance;
  final int leave;
  final int permission;
  final int advance;
  final int advanceAdjustment;
  final int reimbursement;
  final int assetRequest;
  final int assetReturn;
  final int shiftDeviation;
  final int itFile;
  final int profileChange;

  ApprovalSummary({
    this.attendance = 0,
    this.leave = 0,
    this.permission = 0,
    this.advance = 0,
    this.advanceAdjustment = 0,
    this.reimbursement = 0,
    this.assetRequest = 0,
    this.assetReturn = 0,
    this.shiftDeviation = 0,
    this.itFile = 0,
    this.profileChange = 0,
  });

  factory ApprovalSummary.fromJson(Map<String, dynamic> json) {
    return ApprovalSummary(
      attendance: int.tryParse(json['AttnReq']?.toString() ?? '0') ?? 0,
      leave: int.tryParse(json['LGReq']?.toString() ?? '0') ?? 0,
      permission: int.tryParse(json['PermissionReq']?.toString() ?? '0') ?? 0,
      advance: int.tryParse(json['AdvReq']?.toString() ?? '0') ?? 0,
      advanceAdjustment: int.tryParse(json['AARReq']?.toString() ?? '0') ?? 0,
      reimbursement: int.tryParse(json['ReimReq']?.toString() ?? '0') ?? 0,
      assetRequest: int.tryParse(json['AssetReq']?.toString() ?? '0') ?? 0,
      assetReturn: int.tryParse(json['AssetRtn']?.toString() ?? '0') ?? 0,
      shiftDeviation: int.tryParse(json['ShiftDev']?.toString() ?? '0') ?? 0,
      itFile: int.tryParse(json['ITFile']?.toString() ?? '0') ?? 0,
      profileChange: int.tryParse(json['EmpReq']?.toString() ?? '0') ?? 0,
    );
  }
}

class ApprovalRequest {
  final String id;
  final String ticketNo;
  final String empName;
  final String date;
  final String details; // Unified field for module specific info (Leave name, Asset name etc)
  final String status;
  final String remarks;

  ApprovalRequest({
    required this.id,
    required this.ticketNo,
    required this.empName,
    required this.date,
    required this.details,
    required this.status,
    required this.remarks,
  });
}

class ApprovalService {
  Future<ApprovalSummary> getApprovalSummary() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/attn/GetAppStatus');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = jsonDecode(data['response']);
        return ApprovalSummary.fromJson(responseData);
      } else {
        throw Exception('Failed to load approval summary: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ApprovalRequest>> getPendingRequests(String type) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    String endpoint = '';
    switch (type) {
      case 'Attendance': endpoint = 'api/attn/lapp/'; break;
      case 'Leave': endpoint = 'api/attn/lgapp/'; break;
      case 'Permission': endpoint = 'api/attn/PermissionApp/'; break;
      case 'Advance': endpoint = 'api/attn/AdvApp/'; break;
      case 'AdvanceAdjustment': endpoint = 'api/attn/AARApp/'; break;
      case 'Reimbursement': endpoint = 'api/reimapp/getlist/'; break;
      case 'AssetRequest': endpoint = 'api/assetapp/getlist/'; break;
      case 'AssetReturn': endpoint = 'api/assetrtnapp/getlist/'; break;
      case 'ITFile': endpoint = 'api/itfileapp/getlist/'; break;
      case 'ShiftDeviation': endpoint = 'api/attn/ShiftDevApp/'; break;
      case 'ProfileChange': endpoint = 'api/attn/EmpApp/'; break;
      default: throw Exception('Invalid approval type');
    }

    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = jsonDecode(data['response']);
        final List<dynamic> list = responseData['dtList'] ?? responseData['dtLapp'] ?? [];
        
        return list.map((item) {
          // Mapping different API response structures to a unified ApprovalRequest
          String details = '';
          if (type == 'Attendance' || type == 'Leave') {
             details = item['status'] ?? '';
          } else if (type == 'Permission') {
             details = '${item['SDate'] ?? ''} (${item['FromTime'] ?? ''} - ${item['ToTime'] ?? ''})';
          } else if (type == 'Advance' || type == 'AdvanceAdjustment') {
             details = 'Amount: ${item['Amount'] ?? item['AdvAmount'] ?? ''}';
          } else if (type == 'Reimbursement') {
             details = item['EDName'] ?? '';
          } else if (type == 'AssetRequest' || type == 'AssetReturn') {
             details = item['AssetName'] ?? item['AGroupName'] ?? '';
          } else if (type == 'ITFile') {
             details = item['Section'] ?? '';
          } else if (type == 'ShiftDeviation') {
             details = 'Shift: ${item['ShiftName'] ?? ''} (${item['SDate'] ?? ''})';
          } else if (type == 'ProfileChange') {
             details = 'Field: ${item['FieldName'] ?? 'Profile Update'}';
          }

          return ApprovalRequest(
            id: (item['id'] ?? item['Id'] ?? '').toString(),
            ticketNo: (item['ticketno'] ?? item['TicketNo'] ?? '').toString(),
            empName: (item['empname'] ?? item['EmpName'] ?? '').toString(),
            date: (item['sdate'] ?? item['SDate'] ?? '').toString(),
            details: details,
            status: (item['status'] ?? '').toString(),
            remarks: (item['Remarks'] ?? '').toString(),
          );
        }).toList();
      } else {
        throw Exception('Failed to load pending requests: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> submitApproval({
    required String type,
    required String id,
    required String status, // Approved / Rejected
    required String remarks,
    Map<String, dynamic>? extraData,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    String endpoint = '';
    switch (type) {
      case 'Attendance': endpoint = 'api/attn/leaveapproval/'; break;
      case 'Leave': endpoint = 'api/attn/leavegapproval/'; break;
      case 'Permission': endpoint = 'api/attn/PermissionApproval/'; break;
      case 'Advance': endpoint = 'api/attn/AdvApproval/'; break;
      case 'AdvanceAdjustment': endpoint = 'api/attn/AARApproval/'; break;
      case 'Reimbursement': endpoint = 'api/reimapp/reimapproval/'; break;
      case 'AssetRequest': endpoint = 'api/assetapp/assetapproval/'; break;
      case 'AssetReturn': endpoint = 'api/assetrtnapp/assetrtnapproval/'; break;
      case 'ITFile': endpoint = 'api/itfileapp/itfileapproval/'; break;
      case 'ShiftDeviation': endpoint = 'api/attn/ShiftDevApproval/'; break;
      case 'ProfileChange': endpoint = 'api/attn/EmpApproval/'; break;
      default: throw Exception('Invalid approval type');
    }

    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    
    final postData = {
      "EditId": id,
      "App": status,
      "AppRemarks": remarks,
      "Actions": "Modify",
      ...?extraData,
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
          throw Exception(responseData['error'] ?? 'Failed to submit approval');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRequestDetails(String type, String id) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    String endpoint = '';
    switch (type) {
      case 'Attendance': endpoint = 'api/attn/DisplayLeaveApp/'; break;
      case 'Leave': endpoint = 'api/attn/DisplayLeaveGApp/'; break;
      case 'Permission': endpoint = 'api/attn/DisplayPerApp/'; break;
      case 'Advance': endpoint = 'api/attn/DisplayAdvApp/'; break;
      case 'AdvanceAdjustment': endpoint = 'api/attn/DisplayAARApp/'; break;
      case 'Reimbursement': endpoint = 'api/reimapp/displayapp/'; break;
      case 'AssetRequest': endpoint = 'api/assetapp/displayapp/'; break;
      case 'AssetReturn': endpoint = 'api/assetrtnapp/displayapp/'; break;
      case 'ITFile': endpoint = 'api/itfileapp/displayapp/'; break;
      case 'ShiftDeviation': endpoint = 'api/attn/DisplayShiftDevApp/'; break;
      case 'ProfileChange': endpoint = 'api/attn/DisplayEmpApp/'; break;
      default: throw Exception('Invalid approval type');
    }

    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint?id=$id&action=Modify');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to load details: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
