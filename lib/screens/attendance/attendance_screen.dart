import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/widgets/date_picker_field.dart';
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

  // Search & Pagination State
  final TextEditingController _searchController = TextEditingController();
  int _rowsPerPage = 10;
  int _currentPage = 1;
  List<AttendanceRecord> _filteredRecords = [];

  @override
  void initState() {
    super.initState();
    _loadInitialDates();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _currentPage = 1;
      if (_historyResponse == null) return;
      if (_searchController.text.isEmpty) {
        _filteredRecords = _historyResponse!.attendanceRecords;
      } else {
        final query = _searchController.text.toLowerCase();
        _filteredRecords = _historyResponse!.attendanceRecords.where((record) =>
          record.date.toLowerCase().contains(query) ||
          record.status.toLowerCase().contains(query)
        ).toList();
      }
    });
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
    } catch (_) {}
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
        _filteredRecords = data.attendanceRecords;
        _isLoading = false;
        _onSearchChanged();
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
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

  Color _getStatusColor(String status) {
    final s = status.toUpperCase();
    if (s.contains('PRESENT') || s == 'P') return Colors.green;
    if (s.contains('ABSENT') || s == 'A') return Colors.red;
    if (s.contains('LEAVE') || s == 'L') return Colors.orange;
    if (s.contains('HOLIDAY') || s == 'H') return Colors.blue;
    if (s.contains('WEEKOFF') || s == 'W' || s.contains('WEEK')) return Colors.purple;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance History', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search / date filter card ─────────────────────────────
            _buildFilterCard(),
            const SizedBox(height: 16),

            // ── Status summary cards (shown as soon as data arrives) ──
            if (_historyResponse != null) ...[
              _buildStatusSummaryRow(),
              const SizedBox(height: 16),
            ],

            // ── Attendance records table ──────────────────────────────
            _buildRecordsCard(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─── Filter card ──────────────────────────────────────────────────────────

  Widget _buildFilterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Attendance History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
          const SizedBox(height: 16),
          DateFilterRow(
            fromDate: _fromDate,
            toDate: _toDate,
            onFromDateTap: () => _selectDate(context, true),
            onToDateTap: () => _selectDate(context, false),
            onSearch: _loadAttendance,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  // ─── Top summary row: two tables side by side ────────────────────────────

  Widget _buildStatusSummaryRow() {
    final resp = _historyResponse!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildSummaryCard('By Status', resp.summaryByStatus, AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _buildSummaryCard('By Type', resp.summaryByType, const Color(0xFF1F2937))),
      ],
    );
  }

  Widget _buildSummaryCard(String title, List<AttendanceSummary> summaries, Color headerColor) {
    final total = summaries.fold<double>(0, (s, e) => s + e.count);

    return Container(
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Text(title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),

          // ── Column headers ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.grey.shade100,
            child: Row(
              children: const [
                Expanded(child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54))),
                Text('Days', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
              ],
            ),
          ),

          // ── Rows ──
          if (summaries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('No data', style: TextStyle(fontSize: 12, color: Colors.grey)),
            )
          else
            ...summaries.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                color: i.isEven ? Colors.white : Colors.grey.shade50,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(s.status,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
                    ),
                    Text(
                      s.count % 1 == 0 ? s.count.toInt().toString() : s.count.toString(),
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold, color: headerColor),
                    ),
                  ],
                ),
              );
            }),

          // ── Total ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: headerColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                ),
                Text(
                  total.toInt().toString(),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: headerColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Attendance records table ────────────────────────────────────────────

  Widget _buildRecordsCard() {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Card header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1F2937),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: const Text('Attendance Records',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),

          // ── Search & rows-per-page ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: _buildSearchAndRowsRow(),
          ),

          // ── Error or empty state ──
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: $_error', style: const TextStyle(color: Colors.red, fontSize: 13)),
            )
          else if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_historyResponse == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('Select dates above and tap search',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            )
          else if (_filteredRecords.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('No records found.', style: TextStyle(color: Colors.grey))),
            )
          else ...[
            // ── Table ──
            _buildTable(),
            const Divider(height: 1),
            // ── Pagination ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: _buildPaginationFooter(_filteredRecords.length),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchAndRowsRow() {
    return Row(
      children: [
        const Text('Rows:', style: TextStyle(fontSize: 13, color: Colors.black87)),
        const SizedBox(width: 4),
        DropdownButton<int>(
          value: _rowsPerPage,
          isDense: true,
          items: [10, 25, 50, 100]
              .map((e) => DropdownMenuItem(value: e, child: Text('$e', style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() { _rowsPerPage = val; _currentPage = 1; });
          },
          underline: const SizedBox(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 38,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search date or status…',
                hintStyle: const TextStyle(fontSize: 12),
                prefixIcon: const Icon(Icons.search, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTable() {
    int startIndex = (_currentPage - 1) * _rowsPerPage;
    int endIndex = (startIndex + _rowsPerPage).clamp(0, _filteredRecords.length);
    if (startIndex >= _filteredRecords.length) startIndex = 0;
    final displayed = _filteredRecords.sublist(startIndex, endIndex);

    const headerStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white);
    const cellStyle  = TextStyle(fontSize: 12, color: Color(0xFF374151));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.resolveWith((_) => AppColors.primary),
        headingRowHeight: 38,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 44,
        columnSpacing: 16,
        horizontalMargin: 12,
        dividerThickness: 0.6,
        columns: const [
          DataColumn(label: Text('#',        style: headerStyle)),
          DataColumn(label: Text('Date',     style: headerStyle)),
          DataColumn(label: Text('In',       style: headerStyle)),
          DataColumn(label: Text('L.Out',    style: headerStyle)),
          DataColumn(label: Text('L.In',     style: headerStyle)),
          DataColumn(label: Text('Out',      style: headerStyle)),
          DataColumn(label: Text('Status',   style: headerStyle)),
        ],
        rows: displayed.asMap().entries.map((entry) {
          final rowNum = startIndex + entry.key + 1;
          final rec = entry.value;
          final isEven = entry.key.isEven;
          final statusColor = _getStatusColor(rec.status);

          return DataRow(
            color: WidgetStateProperty.resolveWith((_) => isEven ? Colors.white : Colors.grey.shade50),
            cells: [
              DataCell(Text('$rowNum', style: cellStyle.copyWith(color: Colors.grey))),
              DataCell(Text(rec.date,     style: cellStyle.copyWith(fontWeight: FontWeight.w600))),
              DataCell(Text(rec.checkIn.isEmpty  ? '--' : rec.checkIn,    style: cellStyle)),
              DataCell(Text(rec.lunchOut.isEmpty ? '--' : rec.lunchOut,   style: cellStyle)),
              DataCell(Text(rec.lunchIn.isEmpty  ? '--' : rec.lunchIn,    style: cellStyle)),
              DataCell(Text(rec.checkOut.isEmpty ? '--' : rec.checkOut,   style: cellStyle)),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    rec.status.isEmpty ? '--' : rec.status,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaginationFooter(int totalCount) {
    int totalPages = (totalCount / _rowsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;
    int startIndex = (_currentPage - 1) * _rowsPerPage + 1;
    int endIndex   = (startIndex + _rowsPerPage - 1).clamp(0, totalCount);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Showing $startIndex–$endIndex of $totalCount',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Row(
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.chevron_left,
                  color: _currentPage > 1 ? Colors.black87 : Colors.grey),
              onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('$_currentPage / $totalPages',
                  style: const TextStyle(fontSize: 12, color: Colors.black87)),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.chevron_right,
                  color: _currentPage < totalPages ? Colors.black87 : Colors.grey),
              onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
            ),
          ],
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}
