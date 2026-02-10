class AttendanceRecord {
  final String date;
  final String status;
  final String checkIn;
  final String lunchOut;
  final String lunchIn;
  final String checkOut;

  AttendanceRecord({
    required this.date,
    required this.status,
    required this.checkIn,
    required this.lunchOut,
    required this.lunchIn,
    required this.checkOut,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      date: json['SDate1'] ?? '',
      status: json['Status'] ?? '',
      checkIn: json['SIn'] ?? '',
      lunchOut: json['LOut'] ?? '',
      lunchIn: json['LIn'] ?? '',
      checkOut: json['SOut'] ?? '',
    );
  }
}

class AttendanceSummary {
  final String status;
  final double count;

  AttendanceSummary({
    required this.status,
    required this.count,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      status: json['Status'] ?? json['StatusType'] ?? '',
      count: double.tryParse(json['Cnt']?.toString() ?? '0') ?? 0,
    );
  }
}

class AttendanceHistoryResponse {
  final List<AttendanceRecord> attendanceRecords;
  final List<AttendanceSummary> summaryByStatus;
  final List<AttendanceSummary> summaryByType;
  final double totalDays;
  final String fromDate;
  final String toDate;

  AttendanceHistoryResponse({
    required this.attendanceRecords,
    required this.summaryByStatus,
    required this.summaryByType,
    required this.totalDays,
    required this.fromDate,
    required this.toDate,
  });

  factory AttendanceHistoryResponse.fromJson(Map<String, dynamic> json) {
    var attendanceList = json['dtAttn'] as List? ?? [];
    var statusSummaryList = json['dtAbs'] as List? ?? [];
    var typeSummaryList = json['dtAbs1'] as List? ?? [];
    var totalDaysList = json['dtAbs2'] as List? ?? [];

    double total = 0;
    if (totalDaysList.isNotEmpty) {
      total = double.tryParse(totalDaysList[0]['Cnt']?.toString() ?? '0') ?? 0;
    }

    return AttendanceHistoryResponse(
      attendanceRecords: attendanceList.map((e) => AttendanceRecord.fromJson(e)).toList(),
      summaryByStatus: statusSummaryList.map((e) => AttendanceSummary.fromJson(e)).toList(),
      summaryByType: typeSummaryList.map((e) => AttendanceSummary.fromJson(e)).toList(),
      totalDays: total,
      fromDate: json['FDate'] ?? '',
      toDate: json['TDate'] ?? '',
    );
  }
}
