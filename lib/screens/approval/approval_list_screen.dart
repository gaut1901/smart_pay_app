import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/services/approval_service.dart';
import '../../core/constants.dart';
import 'approval_detail_screen.dart';

class ApprovalListScreen extends StatefulWidget {
  final String type;
  final String title;

  const ApprovalListScreen({
    super.key,
    required this.type,
    required this.title,
  });

  @override
  State<ApprovalListScreen> createState() => _ApprovalListScreenState();
}

class _ApprovalListScreenState extends State<ApprovalListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApprovalService _approvalService = ApprovalService();
  
  // State for Pending
  List<dynamic> _pendingList = [];
  List<dynamic> _filteredPendingList = [];
  bool _isLoadingPending = true;
  String? _pendingError;
  int _pendingRowsPerPage = 10;
  int _pendingCurrentPage = 0;
  String _pendingSearchQuery = '';

  // State for Completed
  List<dynamic> _completedList = [];
  List<dynamic> _filteredCompletedList = [];
  bool _isLoadingCompleted = false; // Will load on tab switch or init
  String? _completedError;
  int _completedRowsPerPage = 10;
  int _completedCurrentPage = 0;
  String _completedSearchQuery = '';
  
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = now;

    _loadPendingData();
    _loadCompletedData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingData() async {
    setState(() {
      _isLoadingPending = true;
      _pendingError = null;
    });
    try {
      // Assuming 'Leave' type corresponds to 'Attn' based on similar flow or generic
      // If type is 'Leave', use getLeaveApprovals.
      // We might need to switch based on widget.type
      Map<String, dynamic> data = {};
      
      switch (widget.type) {
        case 'Leave':
          data = await _approvalService.getLeaveApprovals();
          break;
        case 'LeaveComp':
          data = await _approvalService.getLeaveCompApprovals();
          break;
        case 'Advance':
          data = await _approvalService.getAdvanceApprovals();
          break;
        case 'ShiftDev':
          data = await _approvalService.getShiftDevApprovals();
          break;
        case 'Permission':
          data = await _approvalService.getPermissionApprovals();
          break;
        default:
          // Fallback or specific generic list
          // For now, let's assume getLeaveApprovals logic or empty
          break;
      }

      final list = data['dtLapp'] ?? data['dtList'] ?? [];
      
      if (mounted) {
        setState(() {
          _pendingList = list;
          _filterPendingList();
          _isLoadingPending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pendingError = e.toString();
          _isLoadingPending = false;
        });
      }
    }
  }

  Future<void> _loadCompletedData() async {
    setState(() {
      _isLoadingCompleted = true;
      _completedError = null;
    });
    try {
       String? fDate = _fromDate != null ? DateFormat('dd-MM-yyyy').format(_fromDate!) : null;
       String? tDate = _toDate != null ? DateFormat('dd-MM-yyyy').format(_toDate!) : null;

       Map<String, dynamic> data = {};
      
      switch (widget.type) {
        case 'Leave':
          data = await _approvalService.getCompletedLeaveApprovals(fDate: fDate, tDate: tDate);
          break;
        case 'LeaveComp':
          data = await _approvalService.getCompletedLeaveCompApprovals(fDate: fDate, tDate: tDate);
          break;
        case 'Advance':
          data = await _approvalService.getCompletedAdvanceApprovals(fDate: fDate, tDate: tDate);
          break;
        case 'ShiftDev':
          data = await _approvalService.getCompletedShiftDevApprovals(fDate: fDate, tDate: tDate);
          break;
        case 'Permission':
          data = await _approvalService.getCompletedPermissionApprovals(fDate: fDate, tDate: tDate);
          break;
        default:
          break;
      }

      final list = data['dtLapp'] ?? data['dtList'] ?? [];
      
      if (mounted) {
        setState(() {
          _completedList = list;
          _filterCompletedList();
          _isLoadingCompleted = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _completedError = e.toString();
          _isLoadingCompleted = false;
        });
      }
    }
  }

  void _filterPendingList() {
    _pendingCurrentPage = 0;
    if (_pendingSearchQuery.isEmpty) {
      _filteredPendingList = List.from(_pendingList);
    } else {
      _filteredPendingList = _pendingList.where((item) {
        // Implement search logic deeply
        return item.toString().toLowerCase().contains(_pendingSearchQuery.toLowerCase());
      }).toList();
    }
  }

  void _filterCompletedList() {
    _completedCurrentPage = 0;
    if (_completedSearchQuery.isEmpty) {
      _filteredCompletedList = List.from(_completedList);
    } else {
      _filteredCompletedList = _completedList.where((item) {
        return item.toString().toLowerCase().contains(_completedSearchQuery.toLowerCase());
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: widget.title), // "Attendance Approval" etc.
            const Tab(text: 'Approval Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingView(),
          _buildCompletedView(),
        ],
      ),
    );
  }

  Widget _buildPendingView() {
    if (_isLoadingPending) return const Center(child: CircularProgressIndicator());
    if (_pendingError != null) return Center(child: Text('Error: $_pendingError'));

    final startIndex = _pendingCurrentPage * _pendingRowsPerPage;
    final endIndex = (startIndex + _pendingRowsPerPage < _filteredPendingList.length) 
        ? startIndex + _pendingRowsPerPage 
        : _filteredPendingList.length;
    final currentItems = _filteredPendingList.sublist(startIndex, endIndex);

    return Column(
      children: [
        _buildControls(
          rowsPerPage: _pendingRowsPerPage,
          onRowsChanged: (val) => setState(() {
            _pendingRowsPerPage = val!;
            _pendingCurrentPage = 0;
          }),
          onSearchChanged: (val) {
            setState(() {
              _pendingSearchQuery = val;
              _filterPendingList();
            });
          },
        ),
        Expanded(
          child: currentItems.isEmpty 
            ? _buildNoData()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: currentItems.length,
                itemBuilder: (context, index) {
                  final item = currentItems[index];
                  return _buildPendingCard(item);
                },
              ),
        ),
        _buildPaginationControls(
          totalItems: _filteredPendingList.length,
          rowsPerPage: _pendingRowsPerPage,
          currentPage: _pendingCurrentPage,
          onPageChanged: (page) => setState(() => _pendingCurrentPage = page),
        ),
      ],
    );
  }

  Widget _buildCompletedView() {
    if (_isLoadingCompleted) return const Center(child: CircularProgressIndicator());
    if (_completedError != null) return Center(child: Text('Error: $_completedError'));

    final startIndex = _completedCurrentPage * _completedRowsPerPage;
    final endIndex = (startIndex + _completedRowsPerPage < _filteredCompletedList.length)
        ? startIndex + _completedRowsPerPage
        : _filteredCompletedList.length;
    final currentItems = _filteredCompletedList.sublist(startIndex, endIndex);

    return Column(
      children: [
        _buildDateFilter(),
        _buildControls(
          rowsPerPage: _completedRowsPerPage,
          onRowsChanged: (val) => setState(() {
            _completedRowsPerPage = val!;
            _completedCurrentPage = 0;
          }),
          onSearchChanged: (val) {
            setState(() {
              _completedSearchQuery = val;
              _filterCompletedList();
            });
          },
        ),
        Expanded(
          child: currentItems.isEmpty
            ? _buildNoData()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: currentItems.length,
                itemBuilder: (context, index) {
                  final item = currentItems[index];
                  return _buildCompletedCard(item);
                },
              ),
        ),
        _buildPaginationControls(
          totalItems: _filteredCompletedList.length,
          rowsPerPage: _completedRowsPerPage,
          currentPage: _completedCurrentPage,
          onPageChanged: (page) => setState(() => _completedCurrentPage = page),
        ),
      ],
    );
  }

  Widget _buildControls({
    required int rowsPerPage,
    required ValueChanged<int?> onRowsChanged,
    required ValueChanged<String> onSearchChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          // Row per page
          const Text('Rows: '),
          DropdownButton<int>(
            value: rowsPerPage,
            items: [10, 25, 50, 100].map((e) => DropdownMenuItem(value: e, child: Text('$e'))).toList(),
            onChanged: onRowsChanged,
            underline: Container(), // Remove underline
          ),
          const SizedBox(width: 16),
          // Search Box
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
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
                onChanged: onSearchChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls({
    required int totalItems,
    required int rowsPerPage,
    required int currentPage,
    required ValueChanged<int> onPageChanged,
  }) {
    final totalPages = (totalItems / rowsPerPage).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
          ),
          Text('Page ${currentPage + 1} of $totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages - 1 ? () => onPageChanged(currentPage + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _selectDate(true),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'From Date',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                  filled: true,
                  fillColor: Colors.white,
                ),
                child: Text(
                  _fromDate != null ? DateFormat('dd-MM-yyyy').format(_fromDate!) : 'Select Date',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: () => _selectDate(false),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'To Date',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                  filled: true,
                  fillColor: Colors.white,
                ),
                child: Text(
                  _toDate != null ? DateFormat('dd-MM-yyyy').format(_toDate!) : 'Select Date',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE53935), // Red color matches attached image
              borderRadius: BorderRadius.circular(4),
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: _loadCompletedData,
              tooltip: 'Filter',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_fromDate ?? DateTime.now()) : (_toDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Widget _buildNoData() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('No Data Found', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildPendingCard(dynamic item) {
    // Fields: TKT.NO, date, Employee name, from date, to date, status, reason, action edit and delete icon.
    // Mapping from typical API response (e.g. key names might vary, using safe access)
    // Common keys: ticketno, TicketNo, sdate, SDate, empname, EmpName, fdate, FDate, tdate, TDate, status, Status, Remarks, remarks
    
    final ticketNo = item['ticketno'] ?? item['TicketNo'] ?? '-';
    // 'date' in prompt usually refers to Request Date, often sdate or just 'Date'
    final date = item['sdate'] ?? item['SDate'] ?? '-'; 
    final empName = item['empname'] ?? item['EmpName'] ?? '-';
    final fromDate = item['fdate'] ?? item['FDate'] ?? '-';
    final toDate = item['tdate'] ?? item['TDate'] ?? '-';
    final status = item['status'] ?? item['Status'] ?? '-';
    final reason = item['Remarks'] ?? item['remarks'] ?? '-';
    final empCode = item['empcode'] ?? item['EmpCode'] ?? '-'; // Added empcode for consistancy

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
             // Optimized Header: TKT.NO | EmpCode | Date
            Row(
              children: [
                Expanded(child: _headerItem('TKT.NO', ticketNo)),
                Expanded(child: _headerItem('EmpCode', empCode)),
                Expanded(child: _headerItem('Date', date)),
              ],
            ),
            const Divider(height: 16),
            // Body rows
            _rowItem('Employee Name', empName, boldValue: true),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: _rowItem('From Date', fromDate)),
                Expanded(child: _rowItem('To Date', toDate)),
              ],
            ),
            const SizedBox(height: 4),
            _rowItem('Status', status, color: Colors.blue),
            const SizedBox(height: 4),
            _rowItem('Reason', reason),
            
            const Divider(height: 16),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ApprovalDetailScreen(
                          type: widget.type,
                          id: (item['id'] ?? item['Id'] ?? '').toString(),
                          title: widget.title,
                        ),
                      ),
                    ).then((_) {
                      // Refresh pending list on return
                      _loadPendingData();
                    });
                  },
                  tooltip: 'Edit',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    // TODO: Implement Delete
                  },
                  tooltip: 'Delete',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedCard(dynamic item) {
    // Prompt: "if no,empcode,date possible to set in a single row."
    
    final ticketNo = item['ticketno'] ?? item['TicketNo'] ?? '-';
    // final empCode = item['empcode'] ?? item['EmpCode'] ?? '-'; // Removed as per request
    final date = item['sdate'] ?? item['SDate'] ?? '-';
    
    // Filter out internal keys or raw objects
    final excludedKeys = {
      'id', 'Id', 'ticketno', 'TicketNo', 'sdate', 'SDate', 
      'empcode', 'EmpCode', 'cancel', 'revise', 
      'app1', 'appon1', 'appby1', 'appremarks1'
    };

    final labelMap = {
      'status': 'Leave Name',
      'remarks': 'Reason',
      'app': 'Status',
      'appby': 'By',
      'appon': 'On',
    };

    final displayItems = (item as Map<String, dynamic>).entries.where((e) {
      if (excludedKeys.contains(e.key.toLowerCase())) return false;
      if (e.value == null) return false;
      if (e.value is! String && e.value is! num && e.value is! bool) return false;
      return true;
    }).map((e) {
      String key = e.key;
      String label = labelMap[key.toLowerCase()] ?? key;
      String value = e.value.toString();

      // Simple date formatting check
      // e.g. 2026-02-13T11:06:14.8
      if (value.contains('T') && value.length > 10 && value.contains('-') && value.contains(':')) {
        try {
          final dt = DateTime.parse(value);
          value = DateFormat('dd-MM-yyyy HH:mm').format(dt);
        } catch (_) {}
      } else if (value.contains('1900-01-01')) {
         value = '-';
      }

      return MapEntry(label, value);
    }).toList();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), // Tighter padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             // Header: TicketNo, Date (2 cols now since empCode removed)
             Row(
               children: [
                 Expanded(child: _headerItem('TKT.NO', ticketNo)),
                 Expanded(child: _headerItem('Date', date)),
                 // Expanded(child: _headerItem('EmpCode', empCode)), // Removed
               ],
             ),
             const Divider(height: 12),
             Wrap(
               runSpacing: 4, // Tighter spacing
               spacing: 4, 
               children: displayItems.map((e) {
                 // Calculate width for 3 items per row roughly, or 2 if screen is very small
                 // Screen width - card margin (approx 32) - card padding (20) = available width
                 // If we want max 3 items, width is approx available / 3.
                 // We subtract a bit for spacing.
                 final double itemWidth = (MediaQuery.of(context).size.width - 60) / 3;
                 
                 return SizedBox(
                   width: itemWidth,
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         e.key,
                         style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                         overflow: TextOverflow.ellipsis,
                         maxLines: 1,
                       ),
                       Text(
                         e.value,
                         style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                         overflow: TextOverflow.ellipsis,
                         maxLines: 1,
                       )
                     ],
                   ),
                 );
               }).toList(),
             )
          ],
        ),
      ),
    );
  }

  Widget _headerItem(String label, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold)),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _rowItem(String label, String value, {bool boldValue = false, Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text('$label:', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: boldValue ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
