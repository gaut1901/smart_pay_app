import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import '../models/shift_model.dart';
import 'auth_service.dart';

class ShiftService {
  Future<ShiftResponse> getShiftSchedule() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.shiftSchedule}/');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = jsonDecode(data['response']);
        return ShiftResponse.fromJson(responseData);
      } else {
        throw Exception('Failed to load shift schedule: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
