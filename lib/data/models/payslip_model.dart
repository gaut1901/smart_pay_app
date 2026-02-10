class PayslipPeriod {
  final String salaryName;

  PayslipPeriod({required this.salaryName});

  factory PayslipPeriod.fromJson(Map<String, dynamic> json) {
    return PayslipPeriod(
      salaryName: json['SalaryName'] ?? '',
    );
  }
}

class PayslipTemplate {
  final String templateName;

  PayslipTemplate({required this.templateName});

  factory PayslipTemplate.fromJson(Map<String, dynamic> json) {
    return PayslipTemplate(
      templateName: json['payslipname'] ?? '',
    );
  }
}

class PayslipLookupResponse {
  final List<PayslipPeriod> periods;
  final List<PayslipTemplate> templates;

  PayslipLookupResponse({
    required this.periods,
    required this.templates,
  });

  factory PayslipLookupResponse.fromJson(Map<String, dynamic> json) {
    var periodList = json['dtSalaryName'] as List? ?? [];
    var templateList = json['dtTemplate'] as List? ?? [];

    return PayslipLookupResponse(
      periods: periodList.map((e) => PayslipPeriod.fromJson(e)).toList(),
      templates: templateList.map((e) => PayslipTemplate.fromJson(e)).toList(),
    );
  }
}
