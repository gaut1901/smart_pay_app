import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../../core/api_config.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/approval_service.dart';
import 'shift_deviation_modify_screen.dart';

class ShiftDeviationApprovalScreen extends StatefulWidget {
  final String type;
  final String title;

  const ShiftDeviationApprovalScreen({
    super.key,
    required this.type,
    required this.title,
  });

  @override
  State<ShiftDeviationApprovalScreen> createState() => _ShiftDeviationApprovalScreenState();
}

class _ShiftDeviationApprovalScreenState extends State<ShiftDeviationApprovalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApprovalService _approvalService = ApprovalService();
  
  // State
  List<dynamic> _pendingList = [];
  List<dynamic> _filteredPendingList = [];
  bool _isLoadingPending = true;
  String? _pendingError;
  int _rowsPerPage = 10;
  String _searchQuery = '';

  List<dynamic> _completedList = [];
  List<dynamic> _filteredCompletedList = [];
  bool _isLoadingCompleted = false;
  String? _completedError;
  int _completedRowsPerPage = 10;
  int _completedCurrentPage = 0;
  String _completedSearchQuery = '';
  
  DateTime _fDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _tDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPendingData();
    _tabController.addListener(() {
      if (_tabController.index == 1 && _completedList.isEmpty) {
        _loadCompletedData();
      }
    });
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
      final data = await _approvalService.getShiftDevApprovals();
      final list = data['dtList'] ?? data['dtLapp'] ?? [];
      
      if (mounted) {
        setState(() {
          _pendingList = list;
          _filterList();
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
      final fDateStr = DateFormat('dd-MM-yyyy').format(_fDate);
      final tDateStr = DateFormat('dd-MM-yyyy').format(_tDate);
      final data = await _approvalService.getCompletedShiftDevApprovals(fDate: fDateStr, tDate: tDateStr);
      final list = data['dtList'] ?? data['dtLapp'] ?? [];
      
      // Client-side filtering to ensure strict date range compliance
      final filteredList = list.where((item) {
        final sDateStr = item['SDate'] ?? item['sdate'];
        if (sDateStr == null) return true;
        try {
          // Parse dd-MM-yyyy
          final parts = sDateStr.split('-');
          if (parts.length == 3) {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            final itemDate = DateTime(year, month, day);
            
            // Compare dates (ignoring time)
            final from = DateTime(_fDate.year, _fDate.month, _fDate.day);
            final to = DateTime(_tDate.year, _tDate.month, _tDate.day).add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
            
            return itemDate.isAfter(from.subtract(const Duration(days: 1))) && itemDate.isBefore(to.add(const Duration(days: 1)));
          }
        } catch (_) {}
        return true; 
      }).toList();

      if (mounted) {
        setState(() {
          _completedList = filteredList;
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

  void _filterCompletedList() {
    _completedCurrentPage = 0;
    if (_completedSearchQuery.isEmpty) {
      _filteredCompletedList = List.from(_completedList);
    } else {
      _filteredCompletedList = _completedList.where((item) {
        final searchStr = item.toString().toLowerCase();
        return searchStr.contains(_completedSearchQuery.toLowerCase());
      }).toList();
    }
  }

  void _filterList() {
    if (_searchQuery.isEmpty) {
      _filteredPendingList = List.from(_pendingList);
    } else {
      _filteredPendingList = _pendingList.where((item) {
        final searchStr = item.toString().toLowerCase();
        return searchStr.contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Approval Shift Deviation'),
            Tab(text: 'Approval Completed'),
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
    return Column(
      children: [
        _buildControls(),
        Expanded(
          child: _isLoadingPending
              ? const Center(child: CircularProgressIndicator())
              : _pendingError != null
                  ? Center(child: Text('Error: $_pendingError'))
                  : _filteredPendingList.isEmpty
                      ? const Center(child: Text('No records found'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredPendingList.length,
                          itemBuilder: (context, index) {
                            return _buildApprovalCard(_filteredPendingList[index]);
                          },
                        ),
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
        _buildDateFilters(),
        _buildCompletedControls(),
        Expanded(
          child: currentItems.isEmpty
            ? const Center(child: Text('No records found'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: currentItems.length,
                itemBuilder: (context, index) {
                  return _buildApprovalCard(currentItems[index], isCompleted: true);
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

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          // Rows Dropdown
          const Text('Rows: ', style: TextStyle(fontSize: 14)),
          DropdownButton<int>(
            value: _rowsPerPage,
            items: [10, 25, 50, 100].map((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text('$value'),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _rowsPerPage = val!;
              });
            },
            underline: const SizedBox(),
          ),
          const SizedBox(width: 16),
          // Search Bar
          Expanded(
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                    _filterList();
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          const Text('Rows: ', style: TextStyle(fontSize: 14)),
          DropdownButton<int>(
            value: _completedRowsPerPage,
            items: [10, 25, 50, 100].map((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text('$value'),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _completedRowsPerPage = val!;
                _completedCurrentPage = 0;
              });
            },
            underline: const SizedBox(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                onChanged: (val) {
                  setState(() {
                    _completedSearchQuery = val;
                    _filterCompletedList();
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
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

  Widget _buildDateFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildDateField('From Date', _fDate, (date) => setState(() => _fDate = date)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildDateField('To Date', _tDate, (date) => setState(() => _tDate = date)),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: _loadCompletedData,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, DateTime date, Function(DateTime) onSelect) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onSelect(picked);
      },
      child: Container(
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(DateFormat('dd-MM-yyyy').format(date), style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalCard(dynamic item, {bool isCompleted = false}) {
    // Fields from JSON: DevNo, GroupName, StartDate, EndDate, DShiftName, SDate
    final tktNo = item['DevNo'] ?? item['devno'] ?? '-';
    final groupName = item['GroupName'] ?? item['groupname'] ?? '-';
    final fromDate = item['StartDate'] ?? item['startDate'] ?? '-';
    final toDate = item['EndDate'] ?? item['endDate'] ?? '-';
    final shift = item['DShiftName'] ?? item['dshiftname'] ?? item['ShiftName'] ?? '-';
    final date = item['SDate'] ?? item['sdate'] ?? '-';

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
      child: Column(
        children: [
          // Top Row: TKT.NO and GROUP NAME
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TKT.NO', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(tktNo.toString(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('GROUP NAME', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(groupName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                if (!isCompleted)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orangeAccent),
                    onPressed: () => _showEditDialog(item),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Middle Row: FROM DATE, TO DATE, SHIFT
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('FROM DATE', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(fromDate, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TO DATE', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(toDate, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SHIFT', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(shift, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A237E))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bottom Row: DATE
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DATE', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(date, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(dynamic item) async {
    final id = (item['DevNo'] ?? item['devno'] ?? '').toString();
    
    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final user = AuthService.currentUser;
      if (user == null) throw Exception('User not logged in');

      // 1. Fetch Details with action=Modify
      final url = Uri.parse('${ApiConfig.baseUrl}api/essshiftdev/displayapp/?id=$id&action=Modify');
      final response = await http.get(url, headers: user.toHeaders());
      
      if (!mounted) return;
      Navigator.pop(context); // Remove loading

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final details = jsonDecode(data['response']);
        
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShiftDeviationModifyScreen(details: details, id: id),
            ),
          ).then((refresh) {
            if (refresh == true) {
              _loadPendingData();
            }
          });
        }
      } else {
        throw Exception('Failed to load details');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

}
