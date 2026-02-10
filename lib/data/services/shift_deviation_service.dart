import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import 'auth_service.dart';

class ShiftDeviationRequest {
  final String devNo;
  final String sDate;
  final String startDate;
  final String endDate;
  final String groupName;
  final String shiftName;

  ShiftDeviationRequest({
    required this.devNo,
    required this.sDate,
    required this.startDate,
    required this.endDate,
    required this.groupName,
    required this.shiftName,
  });

  factory ShiftDeviationRequest.fromJson(Map<String, dynamic> json) {
    return ShiftDeviationRequest(
      devNo: (json['DevNo'] ?? '').toString(),
      sDate: json['SDate'] ?? '',
      startDate: json['StartDate'] ?? '',
      endDate: json['EndDate'] ?? '',
      groupName: json['GroupName'] ?? '',
      shiftName: json['ShiftName'] ?? '',
    );
  }
}

class ShiftDeviationService {
  Future<List<ShiftDeviationRequest>> getShiftDeviationHistory() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/essshiftdev/getlist/');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = jsonDecode(data['response']);
        final List<dynamic> list = responseData['dtList'] ?? [];
        return list.map((e) => ShiftDeviationRequest.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load shift deviation history: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> getGroupNames(String fDate, String tDate) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/essshiftDev/getgroupname/?fdate=$fDate&tdate=$tDate');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = jsonDecode(data['response']);
        return list.map((e) => e['GroupName']?.toString() ?? '').toList();
      } else {
        throw Exception('Failed to load group names: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> getShifts() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Often there's a getshiftname endpoint or similar
    final url = Uri.parse('${ApiConfig.baseUrl}api/essshiftDev/getshiftname/');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = jsonDecode(data['response']);
        return list.map((e) => e['ShiftName']?.toString() ?? '').toList();
      } else {
        // Fallback or retry with different endpoint if needed
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<void> submitShiftDeviation({
    required String sDate,
    required String groupName,
    required String shiftName,
    required String startDate,
    required String endDate,
    String actions = 'Add',
    String editId = '',
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/essshiftdev/submit/');
    
    final postData = {
      "SDate": sDate,
      "GroupName": groupName,
      "DShiftName": shiftName,
      "StartDate": startDate,
      "EndDate": endDate,
      "EmpNames": "", // Usually for multiple emps, but in ESS it might be empty or auto-filled
      "App": "Pending",
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
        if (responseData['JSONResult'] != 0) {
          throw Exception(responseData['error'] ?? 'Failed to submit shift deviation');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
