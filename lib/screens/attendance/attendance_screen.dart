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

  void _onSearchChanged() {
    setState(() {
      _currentPage = 1; // Reset to first page on search
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
        _filteredRecords = data.attendanceRecords;
        _isLoading = false;
        _onSearchChanged(); // Re-apply search/reset
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
                    
                    // Date Filters Row
                    _buildDateFilterRow(),
                    const SizedBox(height: 16),
                    
                    // Search & Rows Row
                    _buildSearchAndRowsRow(),
                    const SizedBox(height: 24),

                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Error: $_error',
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    else if (_historyResponse != null && _filteredRecords.isNotEmpty) ...[
                       _buildAttendanceCards(),
                       const SizedBox(height: 16),
                       _buildPaginationFooter(_filteredRecords.length),
                    ] else if (!_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'No records found.',
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

  Widget _buildDateFilterRow() {
    return DateFilterRow(
      fromDate: _fromDate,
      toDate: _toDate,
      onFromDateTap: () => _selectDate(context, true),
      onToDateTap: () => _selectDate(context, false),
      onSearch: _loadAttendance,
      isLoading: _isLoading,
    );
  }

  Widget _buildSearchAndRowsRow() {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          const Text('Rows: '),
          DropdownButton<int>(
            value: _rowsPerPage,
            items: [10, 25, 50, 100].map((e) => DropdownMenuItem(value: e, child: Text('$e'))).toList(),
            onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _rowsPerPage = val;
                    _currentPage = 1; // Reset page when rows per page changes
                  });
                }
            },
            underline: Container(), // Remove underline
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (_) => _onSearchChanged(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCards() {
    int startIndex = (_currentPage - 1) * _rowsPerPage;
    int endIndex = startIndex + _rowsPerPage;
    if (endIndex > _filteredRecords.length) endIndex = _filteredRecords.length;
    
    // If start index is out of bounds (can happen if list shrinks drastically), reset to page 1
    if (startIndex >= _filteredRecords.length && _filteredRecords.isNotEmpty) {
      startIndex = 0;
      endIndex = _rowsPerPage < _filteredRecords.length ? _rowsPerPage : _filteredRecords.length;
      // We should ideally update state but in build it's tricky. 
      // State reset handled in search change.
    }
    
    if (_filteredRecords.isEmpty) return const SizedBox.shrink();

    List<AttendanceRecord> displayedItems = _filteredRecords.sublist(startIndex, endIndex);

    return Column(
      children: displayedItems.map((item) => _buildAttendanceCard(item)).toList(),
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCardItem('DATE', item.date, flex: 1),
              _buildCardItem('STATUS', item.status, flex: 1, isHighlight: true, color: _getStatusColor(item.status)),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              _buildCardItem('IN', item.checkIn.isEmpty ? '--' : item.checkIn, flex: 1),
              _buildCardItem('L.OUT', item.lunchOut.isEmpty ? '--' : item.lunchOut, flex: 1),
            ],
          ),
           const SizedBox(height: 8),
          Row(
            children: [
              _buildCardItem('L.IN', item.lunchIn.isEmpty ? '--' : item.lunchIn, flex: 1),
              _buildCardItem('OUT', item.checkOut.isEmpty ? '--' : item.checkOut, flex: 1),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(String label, String value, {int flex = 1, bool isHighlight = false, Color? color}) {
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(
            fontSize: 13, 
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: color ?? (isHighlight ? AppColors.primary : const Color(0xFF1E1E1E)),
          )),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter(int totalCount) {
    int totalPages = (totalCount / _rowsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;
    
    int startIndex = (_currentPage - 1) * _rowsPerPage + 1;
    int endIndex = startIndex + _rowsPerPage - 1;
    if (endIndex > totalCount) endIndex = totalCount;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Showing $startIndex to $endIndex of $totalCount entries', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: _currentPage > 1 ? Colors.black : Colors.grey),
                onPressed: _currentPage > 1 ? () {
                  setState(() {
                    _currentPage--;
                  });
                } : null,
              ),
              const SizedBox(width: 8), // Reduced spacing
              IconButton(
                icon: Icon(Icons.chevron_right, color: _currentPage < totalPages ? Colors.black : Colors.grey),
                onPressed: _currentPage < totalPages ? () {
                  setState(() {
                    _currentPage++;
                  });
                } : null,
              ),
            ],
          )
        ],
      ),
    );
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
