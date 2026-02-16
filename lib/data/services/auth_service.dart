import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  static User? _currentUser;
  static User? get currentUser => _currentUser;
  
  static String _memberEmpCode = "0";
  static String get memberEmpCode => _memberEmpCode;
  static set memberEmpCode(String value) => _memberEmpCode = value;

  static String _memberName = "";
  static String get memberName => _memberName;
  static set memberName(String value) => _memberName = value;

  Future<User?> login(String username, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}');
    
    try {
      final response = await http.post(
        url,
        body: jsonEncode({
          "userName": username,
          "password": password,
          "Module": ""
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = jsonDecode(data['response']);
        if (responseData['success'] == "OK") {
          _currentUser = User.fromJson(responseData);
          return _currentUser;
        } else {
          throw Exception(responseData['error'] ?? 'Login failed');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on SocketException catch (_) {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      rethrow;
    }
  }

  void logout() {
    _currentUser = null;
    _memberEmpCode = "0";
  }
}
