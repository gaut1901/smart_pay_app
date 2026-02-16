import '../services/auth_service.dart';

class User {
  final String userid;
  final String token;
  final String empCode;
  final String ticketNo;
  final String empName;
  final String loginType;
  final String dbName;
  final String companyName;
  final String essGroupCode;
  final String essGroupName;
  final String locIds;
  final String groupType;
  final String domainName;
  final String fDate;
  final String tDate;
  final String eUserName;

  User({
    required this.userid,
    required this.token,
    required this.empCode,
    required this.ticketNo,
    required this.empName,
    required this.loginType,
    required this.dbName,
    required this.companyName,
    required this.essGroupCode,
    required this.essGroupName,
    required this.locIds,
    required this.groupType,
    required this.domainName,
    required this.fDate,
    required this.tDate,
    required this.eUserName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userid: json['userid']?.toString() ?? '',
      token: json['atoken']?.toString() ?? '',
      empCode: json['EmpCode']?.toString() ?? '',
      ticketNo: json['TicketNo']?.toString() ?? '',
      empName: json['EmpName']?.toString() ?? '',
      loginType: json['logintype']?.toString() ?? '',
      dbName: json['dbname']?.toString() ?? '',
      companyName: json['companyname']?.toString() ?? '',
      essGroupCode: json['ESSGroupCode']?.toString() ?? '',
      essGroupName: json['ESSGroupName']?.toString() ?? '',
      locIds: json['LocIds']?.toString() ?? '',
      groupType: json['GroupType']?.toString() ?? '',
      domainName: json['DomainName']?.toString() ?? '',
      fDate: json['FDate']?.toString() ?? '',
      tDate: json['TDate']?.toString() ?? '',
      eUserName: json['EUserName']?.toString() ?? '',
    );
  }

  Map<String, String> toHeaders() {
    return {
      'Authorization': 'Bearer $token',
      'UserData_empcode': empCode,
      'UserData_ticketno': ticketNo,
      'UserData_empname': empName,
      'UserData_logintype': loginType,
      'UserData_dbname': dbName,
      'UserData_companyname': companyName,
      'UserData_memberempcode': AuthService.memberEmpCode,
      'UserData_essgroupcode': essGroupCode,
      'UserData_essgroupname': essGroupName,
      'UserData_LocIds': locIds,
      'UserData_GroupType': groupType,
      'UserData_DomainName': domainName,
      'UserData_FDate': fDate,
      'UserData_TDate': tDate,
      'UserData_module': "HRMS",
      'Content-Type': 'application/json',
    };
  }
}
