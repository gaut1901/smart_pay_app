import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import 'auth_service.dart';

class DashboardService {
  Future<Map<String, dynamic>> getDashboardData(DateTime date) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final dateStr = date.toIso8601String().substring(0, 10);
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.dashboard}?sdate=$dateStr');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to load dashboard: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
