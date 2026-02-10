import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'package:intl/intl.dart';
import '../../data/models/attendance_model.dart';
import '../../data/services/attendance_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  bool _isLoading = false;
  String? _error;
  AttendanceHistoryResponse? _historyResponse;
  
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadInitialDates();
  }

  Future<void> _loadInitialDates() async {
    try {
      final dates = await _attendanceService.getAttendanceDates();
      if (dates['fromDate']!.isNotEmpty && dates['toDate']!.isNotEmpty) {
        setState(() {
          _fromDate = DateFormat('dd-MM-yyyy').parse(dates['fromDate']!);
          _toDate = DateFormat('dd-MM-yyyy').parse(dates['toDate']!);
        });
      }
    } catch (e) {
      // Use default dates if API fails
    }
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fromStr = DateFormat('dd-MM-yyyy').format(_fromDate);
      final toStr = DateFormat('dd-MM-yyyy').format(_toDate);
      final data = await _attendanceService.getAttendanceHistory(fromStr, toStr);
      setState(() {
        _historyResponse = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Attendance History',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // White card container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'Attendance History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // From Date Picker
                    _buildDatePicker(
                      context,
                      'From Date',
                      _fromDate,
                      true,
                    ),
                    const SizedBox(height: 16),
                    
                    // To Date Picker
                    _buildDatePicker(
                      context,
                      'To Date',
                      _toDate,
                      false,
                    ),
                    const SizedBox(height: 20),
                    
                    // Search Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 60,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _loadAttendance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.zero,
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(
                                  Icons.search,
                                  color: Colors.white,
                                  size: 22,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Table Header
                    _buildTableHeader(),
                    const SizedBox(height: 12),
                    
                    // Attendance Records Table
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Error: $_error',
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    else if (_historyResponse != null && 
                             _historyResponse!.attendanceRecords.isNotEmpty)
                      ..._buildAttendanceRows()
                    else if (!_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'No records found. Click search to load data.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Summary Section
                    if (_historyResponse != null) ...[
                      _buildSummaryTable('Status', _historyResponse!.summaryByStatus),
                      const SizedBox(height: 16),
                      _buildSummaryTable('Status Type', _historyResponse!.summaryByType),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, String label, DateTime date, bool isFromDate) {
    return InkWell(
      onTap: () => _selectDate(context, isFromDate),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 18,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Text(
              DateFormat('dd-MM-yyyy').format(date),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'DATE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'STATUS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'IN',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'LOUT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'LIN',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'OUT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAttendanceRows() {
    return _historyResponse!.attendanceRecords.map((record) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                record.date,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                record.status,
                style: TextStyle(
                  fontSize: 12,
                  color: _getStatusColor(record.status),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                record.checkIn.isEmpty ? '--' : record.checkIn,
                style: const TextStyle(fontSize: 11, color: Colors.black87),
              ),
            ),
            Expanded(
              child: Text(
                record.lunchOut.isEmpty ? '--' : record.lunchOut,
                style: const TextStyle(fontSize: 11, color: Colors.black87),
              ),
            ),
            Expanded(
              child: Text(
                record.lunchIn.isEmpty ? '--' : record.lunchIn,
                style: const TextStyle(fontSize: 11, color: Colors.black87),
              ),
            ),
            Expanded(
              child: Text(
                record.checkOut.isEmpty ? '--' : record.checkOut,
                style: const TextStyle(fontSize: 11, color: Colors.black87),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildSummaryTable(String title, List<AttendanceSummary> summaries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 100),
              Expanded(
                child: Text(
                  'Days',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Summary Rows
        ...summaries.map((summary) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    summary.status,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 100),
                Expanded(
                  child: Text(
                    summary.count % 1 == 0 
                        ? summary.count.toInt().toString() 
                        : summary.count.toString(),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        
        // Total Row
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 100),
              Expanded(
                child: Text(
                  summaries.fold<double>(0, (sum, item) => sum + item.count)
                      .toInt()
                      .toString(),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    status = status.toUpperCase();
    if (status.contains('PRESENT') || status == 'P') return Colors.green;
    if (status.contains('ABSENT') || status == 'A') return Colors.red;
    if (status.contains('LEAVE') || status == 'L') return Colors.orange;
    if (status.contains('HOLIDAY') || status == 'H') return Colors.blue;
    if (status.contains('WEEKOFF') || status == 'W') return Colors.grey;
    return AppColors.primary;
  }
}