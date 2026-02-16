import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import '../models/profile_model.dart';
import '../models/wages_model.dart';
import 'auth_service.dart';

class ProfileService {
  Future<ProfileModel> getProfileData({String action = 'View'}) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    // For ESS, id is usually the empCode and action is 'View' or 'Modify'
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profile}/?id=${user.empCode}&action=$action');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ProfileModel.fromJson(jsonDecode(data['response']));
      } else {
        throw Exception('Failed to load profile data: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getLookupData({
    String? ctc,
    String? salaryType,
    List<dynamic>? dtEarn,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profileLookup}');
    
    final body = {
      "EmpCode": user.empCode,
      "CTC": ctc ?? "0",
      "SalaryType": salaryType ?? "",
      "dtEarn": dtEarn ?? [],
    };

    try {
      final response = await http.post(
        url,
        headers: user.toHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to load lookup data: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitProfile(ProfileModel profile) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profileSubmit}');
    
    try {
      final response = await http.post(
        url,
        headers: user.toHeaders(),
        body: jsonEncode(profile.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to submit profile: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> uploadProfileDocument({
    required String type, // 'Photo', 'Pan', 'Adhar', 'DL', 'Passport', 'Card'
    required File file,
    String? idNumber,
    String? insuranceNo,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    String endpoint;
    switch (type) {
      case 'Photo': endpoint = ApiConfig.profilePhotoUpload; break;
      case 'Pan': endpoint = ApiConfig.profilePanUpload; break;
      case 'Adhar': endpoint = ApiConfig.profileAdharUpload; break;
      case 'DL': endpoint = ApiConfig.profileDLUpload; break;
      case 'Passport': endpoint = ApiConfig.profilePassportUpload; break;
      case 'Card': endpoint = ApiConfig.profileCardUpload; break;
      default: throw Exception('Invalid document type');
    }

    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint/?empcode=${user.empCode}');
    var request = http.MultipartRequest('POST', url);
    
    final headers = user.toHeaders();
    headers.forEach((key, value) {
      if (key != 'Content-Type') {
        request.headers[key] = value;
      }
    });

    if (idNumber != null && type != 'Card' && type != 'Photo') {
      request.fields['IDNumber'] = idNumber;
    }

    if (type == 'Card') {
      request.fields['empcode'] = user.empCode;
      if (insuranceNo != null) {
        request.fields['insuranceno'] = insuranceNo;
      }
    }

    final fileName = file.path.split('/').last;
    var multipartFile = await http.MultipartFile.fromPath(
      fileName, 
      file.path,
      filename: fileName,
    );
    request.files.add(multipartFile);

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response']; // Returns the path to the uploaded file
      } else {
        throw Exception('Failed to upload $type: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadFamilyPhoto({
    required String empCode,
    required String slno,
    required String name,
    required String relation,
    required String bloodGroup,
    required String mobileNo,
    required String dob,
    required String adharNo,
    required String eduDetail,
    required String occDetail,
    File? photoFile,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.familyPhotoUpload}/');
    var request = http.MultipartRequest('POST', url);
    
    final headers = user.toHeaders();
    headers.forEach((key, value) {
      if (key != 'Content-Type') {
        request.headers[key] = value;
      }
    });

    request.fields['empcode'] = empCode;
    request.fields['slno'] = slno;
    request.fields['name'] = name;
    request.fields['relation'] = relation;
    request.fields['bloodgroup'] = bloodGroup;
    request.fields['mobileno'] = mobileNo;
    request.fields['dob'] = dob;
    request.fields['adharno'] = adharNo;
    request.fields['EduDetail'] = eduDetail;
    request.fields['OccDetail'] = occDetail;
    request.fields['filepath'] = 'undefined'; // Will be set by server

    if (photoFile != null) {
      final fileName = photoFile.path.split('/').last;
      var multipartFile = await http.MultipartFile.fromPath(
        fileName,
        photoFile.path,
        filename: fileName,
      );
      request.files.add(multipartFile);
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to upload family photo: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadEduPhoto({
    required String empCode,
    required String slno,
    required String degreeType,
    required String degree,
    required String institution,
    required String subject,
    required String passDate,
    File? eduFile,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.eduPhotoUpload}/');
    var request = http.MultipartRequest('POST', url);
    
    final headers = user.toHeaders();
    headers.forEach((key, value) {
      if (key != 'Content-Type') {
        request.headers[key] = value;
      }
    });

    request.fields['empcode'] = empCode;
    request.fields['slno'] = slno;
    request.fields['degreetype'] = degreeType;
    request.fields['degree'] = degree;
    request.fields['institution'] = institution;
    request.fields['subject'] = subject;
    request.fields['passdate'] = passDate;
    request.fields['passyear'] = 'undefined'; // Not needed
    request.fields['edufilepath'] = 'undefined'; // Will be set by server

    if (eduFile != null) {
      final fileName = eduFile.path.split('/').last;
      var multipartFile = await http.MultipartFile.fromPath(
        fileName,
        eduFile.path,
        filename: fileName,
      );
      request.files.add(multipartFile);
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to upload education photo: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadExpPhoto({
    required String empCode,
    required String slno,
    required String companyName,
    required String role,
    required String duration,
    required String expFrom,
    required String expTo,
    File? expFile,
    File? relFile,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.expPhotoUpload}/');
    var request = http.MultipartRequest('POST', url);
    
    final headers = user.toHeaders();
    headers.forEach((key, value) {
      if (key != 'Content-Type') {
        request.headers[key] = value;
      }
    });

    request.fields['empcode'] = empCode;
    request.fields['slno'] = slno;
    request.fields['companyname'] = companyName;
    request.fields['role'] = role;
    request.fields['duration'] = duration;
    request.fields['ExpFrom'] = expFrom;
    request.fields['ExpTo'] = expTo;
    request.fields['expfilepath'] = 'undefined'; // Will be set by server

    if (expFile != null) {
      final fileName = expFile.path.split('/').last;
      var multipartFile = await http.MultipartFile.fromPath(
        'Exp_$fileName',
        expFile.path,
        filename: 'Exp_$fileName',
      );
      request.files.add(multipartFile);
    }

    if (relFile != null) {
      final fileName = relFile.path.split('/').last;
      var multipartFile = await http.MultipartFile.fromPath(
        'Rel_$fileName',
        relFile.path,
        filename: 'Rel_$fileName',
      );
      request.files.add(multipartFile);
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to upload experience photo: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadInsPhoto({
    required String empCode,
    required String slno,
    required String insType,
    required String insName,
    required String insCmpName,
    required String insNo,
    required String insFor,
    required String insAmount,
    required String startDate,
    required String endDate,
    File? insFile,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.insPhotoUpload}/');
    var request = http.MultipartRequest('POST', url);
    
    final headers = user.toHeaders();
    headers.forEach((key, value) {
      if (key != 'Content-Type') {
        request.headers[key] = value;
      }
    });

    request.fields['EmpCode'] = empCode;
    request.fields['SlNo'] = slno;
    request.fields['InsType'] = insType;
    request.fields['InsName'] = insName;
    request.fields['InsCmpName'] = insCmpName;
    request.fields['InsNo'] = insNo;
    request.fields['InsFor'] = insFor;
    request.fields['InsAmount'] = insAmount;
    request.fields['StartDate'] = startDate;
    request.fields['EndDate'] = endDate;
    request.fields['FilePath'] = 'undefined'; // Will be set by server

    if (insFile != null) {
      final fileName = insFile.path.split('/').last;
      var multipartFile = await http.MultipartFile.fromPath(
        fileName,
        insFile.path,
        filename: fileName,
      );
      request.files.add(multipartFile);
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to upload insurance photo: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<WagesModel> getWagesData() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.wagesLookup}/?empcode=${user.empCode}');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WagesModel.fromJson(jsonDecode(data['response']));
      } else {
        throw Exception('Failed to load wages data: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<WagesModel> addNewSalary() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.wagesAddNewSalary}/?empcode=${user.empCode}');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WagesModel.fromJson(jsonDecode(data['response']));
      } else {
        throw Exception('Failed to add new salary: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitWages(WagesModel wages, {String action = 'Modify'}) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.wagesSubmit}');
    
    final body = wages.toJson();
    body['Actions'] = action;
    body['EmpCode'] = user.empCode;
    body['EditId'] = user.empCode;

    try {
      final response = await http.post(
        url,
        headers: user.toHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to submit wages: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getChangePassData() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.changePassDisplay}/?id=${user.empCode}&action=Modify');
    
    try {
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['response']);
      } else {
        throw Exception('Failed to load change password data: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> changePassword(String username, String password) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.changePassSubmit}/');
    
    final body = {
      "UserName": username,
      "Password": password,
      "Actions": "Modify",
      "EditId": user.empCode,
    };

    try {
      final response = await http.post(
        url,
        headers: user.toHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = jsonDecode(data['response']);
        if (result['JSONResult']?.toString() != "0") {
          throw Exception(result['error'] ?? 'Failed to change password');
        }
      } else {
        throw Exception('Failed to change password: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
