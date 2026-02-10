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
  bool _isLoading = true;
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
      _loadAttendance();
    } catch (e) {
      _loadAttendance();
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

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
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
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _loadAttendance();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance History', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _selectDateRange(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAttendance,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadAttendance, child: const Text('Retry')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildDateRangeHeader(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadAttendance,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              _buildSummarySection(),
                              _buildLogsList(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildDateRangeHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            '${DateFormat('dd MMM yyyy').format(_fromDate)} - ${DateFormat('dd MMM yyyy').format(_toDate)}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    if (_historyResponse == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.modernCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (_historyResponse!.totalDays > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Total Days: ${_historyResponse!.totalDays}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                  ),
                ),
            ],
          ),
          const Divider(height: 24),
          if (_historyResponse!.summaryByStatus.isNotEmpty) ...[
            const Text('By Status', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _historyResponse!.summaryByStatus.map((s) => _buildSummaryChip(s)).toList(),
            ),
          ],
          if (_historyResponse!.summaryByType.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('By Type', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _historyResponse!.summaryByType.map((s) => _buildSummaryChip(s)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryChip(AttendanceSummary s) {
    final color = _getStatusColor(s.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(s.status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 6),
          Text(
            s.count % 1 == 0 ? s.count.toInt().toString() : s.count.toString(),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList() {
    if (_historyResponse == null || _historyResponse!.attendanceRecords.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No attendance records found for this period.'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _historyResponse!.attendanceRecords.length,
      itemBuilder: (context, index) {
        final record = _historyResponse!.attendanceRecords[index];
        return _buildAttendanceCard(record);
      },
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord record) {
    final statusColor = _getStatusColor(record.status);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: AppStyles.modernCardDecoration,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(record.date, style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    record.status,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeColumn('Punch In', record.checkIn, Icons.login, Colors.green),
                _buildTimeColumn('Punch Out', record.checkOut, Icons.logout, Colors.red),
              ],
            ),
          ),
          if (record.lunchIn.isNotEmpty || record.lunchOut.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTimeColumn('Lunch Out', record.lunchOut, Icons.restaurant, Colors.orange),
                  _buildTimeColumn('Lunch In', record.lunchIn, Icons.restaurant_menu, Colors.blue),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(String label, String time, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          time.isEmpty ? '--:--' : time,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
