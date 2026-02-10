import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import '../models/attendance_model.dart';
import 'auth_service.dart';

class AttendanceService {
  Future<AttendanceHistoryResponse> getAttendanceHistory(String fromDate, String toDate) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.attendanceHistory}/?fdate=$fromDate&tdate=$toDate');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = jsonDecode(data['response']);
        // The API might return FDate and TDate at the top level of the parsed response
        responseData['FDate'] = fromDate;
        responseData['TDate'] = toDate;
        return AttendanceHistoryResponse.fromJson(responseData);
      } else {
        throw Exception('Failed to load attendance history: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, String>> getAttendanceDates() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.attendanceDates}');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = jsonDecode(data['response']);
        return {
          'fromDate': responseData['FDate'] ?? '',
          'toDate': responseData['TDate'] ?? '',
        };
      } else {
        throw Exception('Failed to load attendance dates: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> punchIn() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.punchIn}/');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to punch in: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
