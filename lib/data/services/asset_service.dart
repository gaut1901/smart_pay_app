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
  final String app;
  final String appBy;
  final String appOn;

  AssetRequestModel({
    required this.id,
    required this.ticketNo,
    required this.empName,
    required this.aGroupName,
    required this.rDate,
    this.app = '',
    this.appBy = '',
    this.appOn = '',
  });

  factory AssetRequestModel.fromJson(Map<String, dynamic> json) {
    return AssetRequestModel(
      id: (json['Id'] ?? json['id'] ?? '').toString(),
      ticketNo: (json['TicketNo'] ?? '').toString(),
      empName: json['EmpName']?.toString() ?? '',
      aGroupName: json['AGroupName']?.toString() ?? '',
      rDate: json['RDate']?.toString() ?? '',
      app: json['App']?.toString() ?? '',
      appBy: json['AppBy']?.toString() ?? '',
      appOn: (json['On'] ?? json['AppOn'] ?? '').toString(),
    );
  }
}

class AssetReturnModel {
  final String id;
  final String ticketNo;
  final String empName;
  final String assetName;
  final String rDate;
  final String app;
  final String appBy;
  final String appOn;

  AssetReturnModel({
    required this.id,
    required this.ticketNo,
    required this.empName,
    required this.assetName,
    required this.rDate,
    this.app = '',
    this.appBy = '',
    this.appOn = '',
  });

  factory AssetReturnModel.fromJson(Map<String, dynamic> json) {
    return AssetReturnModel(
      id: (json['Id'] ?? json['id'] ?? '').toString(),
      ticketNo: (json['TicketNo'] ?? '').toString(),
      empName: json['EmpName']?.toString() ?? '',
      assetName: json['AssetName']?.toString() ?? '',
      rDate: json['RDate']?.toString() ?? '',
      app: json['App']?.toString() ?? '',
      appBy: json['AppBy']?.toString() ?? '',
      appOn: (json['On'] ?? json['AppOn'] ?? '').toString(),
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

  Future<Map<String, dynamic>> getAssetRequestLookup({String action = 'Create'}) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empassetrequest/clear/?action=$action');
    
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

  Future<Map<String, dynamic>> getAssetRequestDetails(String id, String action) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empassetrequest/display/?id=$id&action=$action');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to load asset request details: ${response.statusCode}');
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
        if (responseData['JSONResult'].toString() != '0') {
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

  Future<Map<String, dynamic>> getAssetReturnLookup({String action = 'Create'}) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empassetreturn/clear/?action=$action');
    
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

  Future<Map<String, dynamic>> getAssetReturnDetails(String id, String action) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empassetreturn/display/?id=$id&action=$action');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to load asset return details: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getAssetsToReturn(String empName) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empassetreturn/GetAssetDetail/')
        .replace(queryParameters: {'empname': empName});
    
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
        if (responseData['JSONResult'].toString() != '0') {
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
