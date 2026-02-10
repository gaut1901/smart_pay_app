import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import 'auth_service.dart';

class RequestService {
  Future<Map<String, dynamic>> getRequestRights() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.requestRights}');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to load request rights: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
