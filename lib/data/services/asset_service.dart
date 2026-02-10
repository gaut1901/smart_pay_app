import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import 'auth_service.dart';

class AssetRequestModel {
  final String id;
  final String ticketNo;
  final String empName;
  final String aGroupName;
  final String rDate;

  AssetRequestModel({
    required this.id,
    required this.ticketNo,
    required this.empName,
    required this.aGroupName,
    required this.rDate,
  });

  factory AssetRequestModel.fromJson(Map<String, dynamic> json) {
    return AssetRequestModel(
      id: json['Id']?.toString() ?? '',
      ticketNo: json['TicketNo']?.toString() ?? '',
      empName: json['EmpName']?.toString() ?? '',
      aGroupName: json['AGroupName']?.toString() ?? '',
      rDate: json['RDate']?.toString() ?? '',
    );
  }
}

class AssetReturnModel {
  final String id;
  final String ticketNo;
  final String empName;
  final String assetName;
  final String rDate;

  AssetReturnModel({
    required this.id,
    required this.ticketNo,
    required this.empName,
    required this.assetName,
    required this.rDate,
  });

  factory AssetReturnModel.fromJson(Map<String, dynamic> json) {
    return AssetReturnModel(
      id: json['Id']?.toString() ?? '',
      ticketNo: json['TicketNo']?.toString() ?? '',
      empName: json['EmpName']?.toString() ?? '',
      assetName: json['AssetName']?.toString() ?? '',
      rDate: json['RDate']?.toString() ?? '',
    );
  }
}

class AssetService {
  // Asset Request Methods
  Future<List<AssetRequestModel>> getAssetRequestHistory() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empassetrequest/getlist/');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = jsonDecode(data['response']);
        final List<dynamic> list = responseData['dtList'] ?? [];
        return list.map((item) => AssetRequestModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load asset request history: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAssetRequestLookup() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empassetrequest/clear/?action=Create');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to load asset request lookup: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> submitAssetRequest(Map<String, dynamic> postData) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empassetrequest/submit/');
    
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
          throw Exception(responseData['error'] ?? 'Failed to submit asset request');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Asset Return Methods
  Future<List<AssetReturnModel>> getAssetReturnHistory() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empassetreturn/getlist/');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = jsonDecode(data['response']);
        final List<dynamic> list = responseData['dtList'] ?? [];
        return list.map((item) => AssetReturnModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load asset return history: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAssetReturnLookup() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empassetreturn/clear/?action=Create');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to load asset return lookup: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getAssetsToReturn(String empName) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empassetreturn/GetAssetDetail/?empname=$empName');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = jsonDecode(data['response']);
        return responseData['dtAsset'] ?? [];
      } else {
        throw Exception('Failed to load assets: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> submitAssetReturn(Map<String, dynamic> postData) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empassetreturn/submit/');
    
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
          throw Exception(responseData['error'] ?? 'Failed to submit asset return');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
