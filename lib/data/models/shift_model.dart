class ShiftRecord {
  final String date;
  final String shiftName;
  final String colorCode;

  ShiftRecord({
    required this.date,
    required this.shiftName,
    required this.colorCode,
  });

  factory ShiftRecord.fromJson(Map<String, dynamic> json) {
    return ShiftRecord(
      date: json['SDate'] ?? '',
      shiftName: json['ShiftName'] ?? '',
      colorCode: json['ColorCode'] ?? '#1B264F',
    );
  }
}

class ShiftResponse {
  final List<ShiftRecord> shifts;
  final String fromDate;
  final String toDate;

  ShiftResponse({
    required this.shifts,
    required this.fromDate,
    required this.toDate,
  });

  factory ShiftResponse.fromJson(Map<String, dynamic> json) {
    var list = json['dtList'] as List? ?? [];
    return ShiftResponse(
      shifts: list.map((e) => ShiftRecord.fromJson(e)).toList(),
      fromDate: json['FDate'] ?? '',
      toDate: json['TDate'] ?? '',
    );
  }
}
