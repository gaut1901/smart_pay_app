class TeamMember {
  final String empCode;
  final String empName;
  final String ticketNo;
  final String? photoBase64;
  final String? deptName;
  final String? desName;
  final String? locName;

  TeamMember({
    required this.empCode,
    required this.empName,
    required this.ticketNo,
    this.photoBase64,
    this.deptName,
    this.desName,
    this.locName,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      empCode: json['Empcode']?.toString() ?? json['EmpCode']?.toString() ?? '',
      empName: json['EmpName']?.toString() ?? '',
      ticketNo: json['TicketNo']?.toString() ?? '',
      photoBase64: json['Base64']?.toString() ?? json['PhotoBase64']?.toString(),
      deptName: json['DeptName']?.toString(),
      desName: json['DesName']?.toString(),
      locName: json['LocName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Empcode': empCode,
      'EmpName': empName,
      'TicketNo': ticketNo,
      'Base64': photoBase64,
      'DeptName': deptName,
      'DesName': desName,
      'LocName': locName,
    };
  }

  // Helper method to get display name (remove prefixes if exist)
  String get displayName {
    final parts = empName.split(' - ');
    if (parts.length >= 3) return parts.last;
    if (parts.length == 2) return parts[1];
    return empName;
  }
}

class TeamMemberApprovals {
  final int attnReq;
  final int lgReq;
  final int advReq;
  final int aarReq;
  final int permissionReq;
  final int shiftDev;

  TeamMemberApprovals({
    this.attnReq = 0,
    this.lgReq = 0,
    this.advReq = 0,
    this.aarReq = 0,
    this.permissionReq = 0,
    this.shiftDev = 0,
  });

  factory TeamMemberApprovals.fromJson(Map<String, dynamic> json) {
    return TeamMemberApprovals(
      attnReq: int.tryParse(json['AttnReq']?.toString() ?? '0') ?? 0,
      lgReq: int.tryParse(json['LGReq']?.toString() ?? '0') ?? 0,
      advReq: int.tryParse(json['AdvReq']?.toString() ?? '0') ?? 0,
      aarReq: int.tryParse(json['AARReq']?.toString() ?? '0') ?? 0,
      permissionReq: int.tryParse(json['PermissionReq']?.toString() ?? '0') ?? 0,
      shiftDev: int.tryParse(json['ShiftDev']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'AttnReq': attnReq,
      'LGReq': lgReq,
      'AdvReq': advReq,
      'AARReq': aarReq,
      'PermissionReq': permissionReq,
      'ShiftDev': shiftDev,
    };
  }
}
