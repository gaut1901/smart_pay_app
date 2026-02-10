class WagesModel {
  final List<IncrementDate> dtIncDate;
  final List<WageComponent> dtEarn;
  final List<Reimbursement> dtDed;
  final List<dynamic> dtCTC;
  final String? otWage;
  final String? salaryType;
  final String? incDate;
  final String? ctc;

  WagesModel({
    required this.dtIncDate,
    required this.dtEarn,
    required this.dtDed,
    required this.dtCTC,
    this.otWage,
    this.salaryType,
    this.incDate,
    this.ctc,
  });

  factory WagesModel.fromJson(Map<String, dynamic> json) {
    return WagesModel(
      dtIncDate: (json['dtIncDate'] as List? ?? [])
          .map((e) => IncrementDate.fromJson(e))
          .toList(),
      dtEarn: (json['dtEarn'] as List? ?? [])
          .map((e) => WageComponent.fromJson(e))
          .toList(),
      dtDed: (json['dtDed'] as List? ?? [])
          .map((e) => Reimbursement.fromJson(e))
          .toList(),
      dtCTC: json['dtCTC'] as List? ?? [],
      otWage: json['OTWage']?.toString(),
      salaryType: json['SalaryType'],
      incDate: json['IncDate'],
      ctc: json['CTC']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dtIncDate': dtIncDate.map((e) => e.toJson()).toList(),
      'dtEarn': dtEarn.map((e) => e.toJson()).toList(),
      'dtDed': dtDed.map((e) => e.toJson()).toList(),
      'dtCTC': dtCTC,
      'OTWage': otWage,
      'SalaryType': salaryType,
      'IncDate': incDate,
      'CTC': ctc,
    };
  }
}

class IncrementDate {
  final String? incdate;
  final String? incdate1;

  IncrementDate({this.incdate, this.incdate1});

  factory IncrementDate.fromJson(Map<String, dynamic> json) {
    return IncrementDate(
      incdate: json['incdate'],
      incdate1: json['incdate1'],
    );
  }

  Map<String, dynamic> toJson() => {
        'incdate': incdate,
        'incdate1': incdate1,
      };
}

class WageComponent {
  final String? edcode;
  final String? edname;
  final String? etype;
  final double? p;
  double? camount;
  double? yamount;
  final String? edtype;

  WageComponent({
    this.edcode,
    this.edname,
    this.etype,
    this.p,
    this.camount,
    this.yamount,
    this.edtype,
  });

  factory WageComponent.fromJson(Map<String, dynamic> json) {
    return WageComponent(
      edcode: json['edcode']?.toString(),
      edname: json['edname'],
      etype: json['etype'],
      p: double.tryParse(json['p']?.toString() ?? '0'),
      camount: double.tryParse(json['camount']?.toString() ?? '0'),
      yamount: double.tryParse(json['yamount']?.toString() ?? '0'),
      edtype: json['edtype'],
    );
  }

  Map<String, dynamic> toJson() => {
        'edcode': edcode,
        'edname': edname,
        'etype': etype,
        'p': p,
        'camount': camount,
        'yamount': yamount,
        'edtype': edtype,
      };
}

class Reimbursement {
  final String? edcode;
  final String? edname;
  bool unlimited;
  double? maxAllowed;
  bool salaryPay;

  Reimbursement({
    this.edcode,
    this.edname,
    this.unlimited = false,
    this.maxAllowed,
    this.salaryPay = false,
  });

  factory Reimbursement.fromJson(Map<String, dynamic> json) {
    return Reimbursement(
      edcode: json['edcode']?.toString(),
      edname: json['edname'],
      unlimited: json['Unlimited'] == true || json['Unlimited'] == 1,
      maxAllowed: double.tryParse(json['MaxAllowed']?.toString() ?? '0'),
      salaryPay: json['SalaryPay'] == true || json['SalaryPay'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'edcode': edcode,
        'edname': edname,
        'Unlimited': unlimited,
        'MaxAllowed': maxAllowed,
        'SalaryPay': salaryPay,
      };
}
