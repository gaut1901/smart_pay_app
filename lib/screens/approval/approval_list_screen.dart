import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/services/approval_service.dart';
import '../../core/constants.dart';
import '../../core/widgets/date_picker_field.dart';
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
        case 'AdvAdj':
          data = await _approvalService.getAdvanceAdjustmentApprovals();
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
        case 'AdvAdj':
          data = await _approvalService.getCompletedAdvanceAdjustmentApprovals(fDate: fDate, tDate: tDate);
          break;
        default:
          break;
      }

      final list = data['dtLapp'] ?? data['dtList'] ?? [];
      
      // Client-side filtering
      final filteredList = list.where((item) {
        if (_fromDate == null || _toDate == null) return true;
        
        final sDateStr = item['SDate'] ?? item['sdate'] ?? item['RequestDate'] ?? item['date'];
        if (sDateStr == null) return true; // Default keep if no date found, or filter out? Keep for safety.

        try {
           final parts = sDateStr.toString().split('-');
           if (parts.length == 3) {
             final day = int.parse(parts[0]);
             final month = int.parse(parts[1]);
             final year = int.parse(parts[2]);
             final itemDate = DateTime(year, month, day);

             // Inclusive range check
             final from = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
             final to = DateTime(_toDate!.year, _toDate!.month, _toDate!.day).add(const Duration(days: 1)).subtract(const Duration(seconds: 1));

             return itemDate.isAfter(from.subtract(const Duration(days: 1))) && itemDate.isBefore(to.add(const Duration(days: 1)));
           }
        } catch (_) {}
        return true;
      }).toList();

      if (mounted) {
        setState(() {
          _completedList = filteredList; // Use filtered list
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
    if (_pendingError != null) return _buildError(_pendingError!, _loadPendingData);

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
    if (_completedError != null) return _buildError(_completedError!, _loadCompletedData);

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
      child: DateFilterRow(
        fromDate: _fromDate ?? DateTime.now(),
        toDate: _toDate ?? DateTime.now(),
        onFromDateTap: () => _selectDate(true),
        onToDateTap: () => _selectDate(false),
        onSearch: _loadCompletedData,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text(
            'No Data Found',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no records to display at the moment.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, size: 64, color: Colors.red),
            ),
            const SizedBox(height: 20),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.replaceAll('Exception: ', ''),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCard(dynamic item) {
    if (widget.type == 'AdvAdj') {
      return _buildAdvAdjPendingCard(item);
    }

    final ticketNo = item['ticketno'] ?? item['TicketNo'] ?? '-';
    final date = item['sdate'] ?? item['SDate'] ?? '-';
    final empName = item['empname'] ?? item['EmpName'] ?? '-';
    final fromDate = item['fdate'] ?? item['FDate'] ?? '-';
    final toDate = item['tdate'] ?? item['TDate'] ?? '-';
    final status = item['status'] ?? item['Status'] ?? '-';
    final reason = item['Remarks'] ?? item['remarks'] ?? '-';
    final empCode = item['empcode'] ?? item['EmpCode'] ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 40, 16), // Extra padding for edit icon
                child: Row(
                  children: [
                    Expanded(child: _headerItem('TKT.NO', ticketNo)),
                    Expanded(child: _headerItem('EmpCode', empCode)),
                    Expanded(child: _headerItem('Date', date)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _rowItem('Employee Name', empName, boldValue: true),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _rowItem('From Date', fromDate)),
                        Expanded(child: _rowItem('To Date', toDate)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _rowItem('Status', status, color: Colors.blue),
                    const SizedBox(height: 8),
                    _rowItem('Reason', reason),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () => _openDetail(item),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvAdjPendingCard(dynamic item) {
    // Fields: TicketNo, EmpName, ReqDate, SalaryMonth, DedName, AdjAmount
    final ticketNo = item['TicketNo'] ?? item['ticketno'] ?? '-';
    final empName = item['EmpName'] ?? item['empname'] ?? '-';
    final reqDate = item['ReqDate'] ?? item['date'] ?? item['SDate'] ?? '-';
    final salaryMonth = item['SalaryMonth'] ?? '-';
    final dedName = item['DedName'] ?? '-';
    final adjAmount = item['AdjAmount'] ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TKT.NO', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(ticketNo.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('REQ. DATE', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(reqDate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('EMPLOYEE NAME', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(empName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SALARY PERIOD', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(salaryMonth, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ADJ. AMOUNT', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(adjAmount.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('DEDUCTION', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(dedName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const Divider(height: 1),
          // Footer Actions
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                 TextButton.icon(
                  onPressed: () => _openDetail(item),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Review'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(dynamic item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApprovalDetailScreen(
          type: widget.type,
          id: (item['id'] ?? item['Id'] ?? '').toString(),
          title: widget.title,
        ),
      ),
    ).then((refresh) {
      if (refresh == true) {
        _loadPendingData();
      }
    });
  }

  Widget _buildCompletedCard(dynamic item) {
    if (widget.type == 'AdvAdj') {
      return _buildAdvAdjCompletedCard(item);
    }

    final ticketNo = item['ticketno'] ?? item['TicketNo'] ?? '-';
    final date = item['sdate'] ?? item['SDate'] ?? '-';
    
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 _headerItem('TKT.NO', ticketNo),
                 _headerItem('Date', date),
               ],
             ),
             const Divider(height: 24),
             Wrap(
               runSpacing: 12,
               spacing: 0, 
               children: displayItems.map((e) {
                 final double itemWidth = (MediaQuery.of(context).size.width - 64) / 2;
                 return SizedBox(
                   width: itemWidth,
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         e.key.toUpperCase(),
                         style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold),
                         overflow: TextOverflow.ellipsis,
                         maxLines: 1,
                       ),
                       const SizedBox(height: 4),
                       Text(
                         e.value,
                         style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
                         overflow: TextOverflow.ellipsis,
                         maxLines: 2,
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

  Widget _buildAdvAdjCompletedCard(dynamic item) {
    final ticketNo = item['TicketNo'] ?? item['ticketno'] ?? '-';
    final empName = item['EmpName'] ?? item['empname'] ?? '-';
    final reqDate = item['ReqDate'] ?? item['date'] ?? item['SDate'] ?? '-';
    final salaryMonth = item['SalaryMonth'] ?? '-';
    final dedName = item['DedName'] ?? '-';
    final adjAmount = item['AdjAmount'] ?? '-';
    final status = item['App'] ?? '-';
    final appBy = item['AppBy'] ?? '-';
    final appOn = item['AppOn'] ?? '-';

    bool isApproved = status.toString().toLowerCase() == 'approved';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _headerItem('TKT.NO', ticketNo),
                _headerItem('REQ. DATE', reqDate),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isApproved ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toString().toUpperCase(),
                    style: TextStyle(
                      color: isApproved ? Colors.green : Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _rowItem('Employee Name', empName.toString(), boldValue: true),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _rowItem('Salary Period', salaryMonth.toString())),
                    Expanded(child: _rowItem('Adj. Amount', adjAmount.toString(), color: Colors.blue.shade700, boldValue: true)),
                  ],
                ),
                const SizedBox(height: 12),
                _rowItem('Deduction', dedName.toString()),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _headerItem('APPROVED BY', appBy)),
                    Expanded(child: _headerItem('APPROVED ON', appOn)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerItem(String label, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold)),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _rowItem(String label, String value, {bool boldValue = false, Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text('$label:', style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: boldValue ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}


