import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import 'auth_service.dart';

class ShiftDeviationRequest {
  final String id;
  final String devNo;
  final String sDate;
  final String startDate;
  final String endDate;
  final String groupName;
  final String shiftName;
  final String app;
  final String appBy;
  final String appOn;

  ShiftDeviationRequest({
    required this.id,
    required this.devNo,
    required this.sDate,
    required this.startDate,
    required this.endDate,
    required this.groupName,
    required this.shiftName,
    this.app = '',
    this.appBy = '',
    this.appOn = '',
  });

  factory ShiftDeviationRequest.fromJson(Map<String, dynamic> json) {
    return ShiftDeviationRequest(
      id: (json['DevNo'] ?? json['id'] ?? json['Id'] ?? '').toString(),
      devNo: (json['DevNo'] ?? '').toString(),
      sDate: json['SDate'] ?? '',
      startDate: json['StartDate'] ?? '',
      endDate: json['EndDate'] ?? '',
      groupName: json['GroupName'] ?? '',
      shiftName: json['ShiftName'] ?? json['DShiftName'] ?? '',
      app: json['App'] ?? '',
      appBy: json['AppBy'] ?? '',
      appOn: json['On'] ?? json['AppOn'] ?? '',
    );
  }

  static String _parseDate(dynamic date) {
    if (date == null || date.toString().isEmpty) return '';
    String dateStr = date.toString();
    try {
      // If it's already in dd-MM-yyyy format, keep it
      if (RegExp(r'^\d{2}-\d{2}-\d{4}').hasMatch(dateStr)) {
        return dateStr.substring(0, 10);
      }
      // Try to parse as DateTime and format
      DateTime dt = DateTime.parse(dateStr);
      return "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";
    } catch (_) {
      return dateStr;
    }
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
        return list.map((e) {
          final req = ShiftDeviationRequest.fromJson(e);
          return ShiftDeviationRequest(
            id: req.id,
            devNo: req.devNo,
            sDate: ShiftDeviationRequest._parseDate(req.sDate),
            startDate: ShiftDeviationRequest._parseDate(req.startDate),
            endDate: ShiftDeviationRequest._parseDate(req.endDate),
            groupName: req.groupName,
            shiftName: req.shiftName,
            app: req.app,
            appBy: req.appBy,
            appOn: ShiftDeviationRequest._parseDate(req.appOn),
          );
        }).toList();
      } else {
        throw Exception('Failed to load shift deviation history: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getShiftDeviationLookup({String action = 'Create'}) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/essshiftdev/clear/?action=$action');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to load shift deviation lookup: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getShiftDeviationDetails(String id, String action) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/essshiftdev/display/')
        .replace(queryParameters: {'id': id, 'action': action});
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to load shift deviation details: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> getGroupNames(String fDate, String tDate) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/essshiftDev/getgroupname/').replace(queryParameters: {
      'fdate': fDate,
      'tdate': tDate,
    });
    
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


  Future<void> submitShiftDeviation(Map<String, dynamic> postData) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/essshiftdev/submit/');
    
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
