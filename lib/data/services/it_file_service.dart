import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import 'auth_service.dart';

class ITFileRequest {
  final String id;
  final String ticketNo;
  final String empName;
  final String finYear;
  final String sDate;
  final String itHead;
  final double amount;
  final String app;
  final String appBy;
  final String appOn;

  ITFileRequest({
    required this.id,
    required this.ticketNo,
    required this.empName,
    required this.finYear,
    required this.sDate,
    required this.itHead,
    required this.amount,
    required this.app,
    required this.appBy,
    required this.appOn,
  });

  factory ITFileRequest.fromJson(Map<String, dynamic> json) {
    return ITFileRequest(
      id: json['EntryId']?.toString() ?? '',
      ticketNo: json['TicketNo']?.toString() ?? '',
      empName: json['EmpName']?.toString() ?? '',
      finYear: json['FinYear']?.toString() ?? '',
      sDate: json['EntryDate']?.toString() ?? '',
      itHead: json['ITHead']?.toString() ?? '',
      amount: (json['AAmount'] is num) ? (json['AAmount'] as num).toDouble() : 0.0,
      app: json['App']?.toString() ?? '',
      appBy: json['AppBy']?.toString() ?? '',
      appOn: json['AppOn']?.toString() ?? '',
    );
  }
}

class ITFileService {
  Future<List<ITFileRequest>> getITFileHistory() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empitfile/getlist/');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = jsonDecode(data['response']);
        final List<dynamic> list = responseData['dtList'] ?? [];
        return list.map((item) => ITFileRequest.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load IT file history: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getITFileLookup() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empitfile/clear/?action=Create');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to load IT file lookup: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getITFileDetails({required String id, required String action}) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empitfile/display/?id=$id&action=$action');

    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to load IT file details: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getITHead({
    required String empName,
    required String itHeadType,
    required String finYear,
    required String slabName,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse(
        '${ApiConfig.baseUrl}api/empitfile/GetITHead/?empname=$empName&itheadtype=$itHeadType&finyear=$finYear&slabname=$slabName');

    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to load IT heads: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getITHeadAmount({
    required String empName,
    required String itHeadType,
    required String finYear,
    required String slabName,
    required String itHead,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse(
        '${ApiConfig.baseUrl}api/empitfile/GetITHeadAmount/?empname=$empName&itheadtype=$itHeadType&finyear=$finYear&slabname=$slabName&ithead=$itHead');

    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to load IT head amount: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> submitITFile({
    required String entryDate,
    required String slabName,
    required String finYear,
    required String itHead,
    required String itHeadType,
    required String empName,
    required double pAmount,
    required double aAmount,
    File? file,
    String actions = "Add",
    String editId = "",
    String app = "-",
    String delIds = "0",
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}api/empitfile/submit/');

    var request = http.MultipartRequest('POST', url);

    final headers = user.toHeaders();
    headers.forEach((key, value) {
      if (key != 'Content-Type') {
        request.headers[key] = value;
      }
    });

    request.fields['EntryDate'] = entryDate;
    request.fields['SlabName'] = slabName;
    request.fields['FinYear'] = finYear;
    request.fields['ITHead'] = itHead;
    request.fields['ITHeadType'] = itHeadType;
    request.fields['EmpName'] = empName;
    request.fields['PAmount'] = pAmount.toString();
    request.fields['AAmount'] = aAmount.toString();
    request.fields['editid'] = editId;
    request.fields['actions'] = actions;
    request.fields['App'] = app;
    request.fields['DelIds'] = delIds;

    if (file != null) {
      var stream = http.ByteStream(file.openRead());
      var length = await file.length();
      var multipartFile = http.MultipartFile(
        file.path.split('/').last,
        stream,
        length,
        filename: file.path.split('/').last,
      );
      request.files.add(multipartFile);
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = jsonDecode(data['response']);
        if (responseData['JSONResult'] != 0) {
          throw Exception(responseData['error'] ?? 'Failed to submit IT file');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
