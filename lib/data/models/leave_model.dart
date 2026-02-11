class LeaveRequest {
  final String id;
  final String ticketNo;
  final String empName;
  final String sDate;
  final String fDate;
  final String tDate;
  final String status;
  final String remarks;
  final String app;
  final String appBy;
  final String appOn;
  final String appRemarks;
  final String app1;
  final String appBy1;
  final String appOn1;
  final String appRemarks1;
  final bool cancel;

  LeaveRequest({
    required this.id,
    required this.ticketNo,
    required this.empName,
    required this.sDate,
    required this.fDate,
    required this.tDate,
    required this.status,
    required this.remarks,
    required this.app,
    required this.appBy,
    required this.appOn,
    required this.appRemarks,
    required this.app1,
    required this.appBy1,
    required this.appOn1,
    required this.appRemarks1,
    required this.cancel,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id']?.toString() ?? '',
      ticketNo: json['TicketNo']?.toString() ?? '',
      empName: json['EmpName']?.toString() ?? '',
      sDate: json['SDate']?.toString() ?? '',
      fDate: json['FDate']?.toString() ?? '',
      tDate: json['TDate']?.toString() ?? '',
      status: json['Status']?.toString() ?? '',
      remarks: json['Remarks']?.toString() ?? '',
      app: json['App']?.toString() ?? '',
      appBy: json['AppBy']?.toString() ?? '',
      appOn: json['AppOn']?.toString() ?? '',
      appRemarks: json['AppRemarks']?.toString() ?? '',
      app1: json['app1']?.toString() ?? '',
      appBy1: json['appby1']?.toString() ?? '',
      appOn1: json['appon1']?.toString() ?? '',
      appRemarks1: json['appremarks1']?.toString() ?? '',
      cancel: json['Cancel'] == true || json['Cancel'] == 'true',
    );
  }
}

class LeaveBalance {
  final String leaveType;
  final double yearOpen;
  final double yearCredit;
  final double yearLaps;
  final double yearTaken;
  final double pending;
  final double yearBalance;

  LeaveBalance({
    required this.leaveType,
    required this.yearOpen,
    required this.yearCredit,
    required this.yearLaps,
    required this.yearTaken,
    required this.pending,
    required this.yearBalance,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      leaveType: json['status']?.toString() ?? '',
      yearOpen: double.tryParse(json['YearOpen']?.toString() ?? '0') ?? 0,
      yearCredit: double.tryParse(json['YearCredit']?.toString() ?? '0') ?? 0,
      yearLaps: double.tryParse(json['YearLaps']?.toString() ?? '0') ?? 0,
      yearTaken: double.tryParse(json['YearTaken']?.toString() ?? '0') ?? 0,
      pending: double.tryParse(json['Pending']?.toString() ?? '0') ?? 0,
      yearBalance: double.tryParse(json['YearBalance']?.toString() ?? '0') ?? 0,
    );
  }
}
