import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/ui_constants.dart';
import '../../core/widgets/date_picker_field.dart';
import '../../data/services/leave_service.dart';
import '../../data/models/leave_model.dart';

class SupplementaryRequestScreen extends StatefulWidget {
  const SupplementaryRequestScreen({super.key});

  @override
  State<SupplementaryRequestScreen> createState() => _SupplementaryRequestScreenState();
}

class _SupplementaryRequestScreenState extends State<SupplementaryRequestScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LeaveService _leaveService = LeaveService();
  
  List<LeaveRequest> _history = [];
  bool _isLoadingHistory = true;
  String? _historyError;

  List<LeaveBalance> _balances = [];
  bool _isLoadingBalance = true;
  String? _balanceError;

  bool _isLoadingLookup = true;

  // Form fields
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String? _selectedStatus;
  String? _selectedReason;
  final TextEditingController _remarksController = TextEditingController();
  bool _isSubmitting = false;

  Map<String, dynamic>? _lookupData;

  // Actions State
  String _currentAction = 'Create'; // Create, Modify, Revise, View, Delete, Cancel
  String? _editId;
  Map<String, dynamic>? _editDetails;

  // Table & Search State
  final TextEditingController _searchController = TextEditingController();
  int _rowsPerPage = 10;
  int _currentPage = 0;
  List<LeaveRequest> _dateFilteredHistory = [];
  List<LeaveRequest> _filteredHistory = [];

  // Date Filters
  DateTime _historyFromDate = DateTime.now();
  DateTime _historyToDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final now = DateTime.now();
    _historyFromDate = DateTime(now.year, now.month, 1);
    _historyToDate = now;

    _loadData();
    _fetchLookup();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      String query = _searchController.text.toLowerCase();
      if (query.isEmpty) {
        _filteredHistory = List.from(_dateFilteredHistory);
      } else {
        _filteredHistory = _dateFilteredHistory.where((request) => 
          request.ticketNo.toLowerCase().contains(query) ||
          request.empName.toLowerCase().contains(query) ||
          request.status.toLowerCase().contains(query) ||
          request.remarks.toLowerCase().contains(query)
        ).toList();
      }
      _currentPage = 0;
    });
  }

  Future<void> _selectHistoryDate(bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _historyFromDate : _historyToDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _historyFromDate = picked;
        } else {
          _historyToDate = picked;
        }
      });
    }
  }

  void _applyHistoryDateFilter() {
    setState(() {
      _dateFilteredHistory = _history.where((item) {
        try {
          DateTime itemDate;
          if (item.fDate.contains('-')) {
            itemDate = DateFormat('dd-MM-yyyy').parse(item.fDate.split(' ')[0]);
          } else {
            // Assume ISO format
            itemDate = DateTime.parse(item.fDate);
          }
          DateTime start = DateTime(_historyFromDate.year, _historyFromDate.month, _historyFromDate.day);
          DateTime end = DateTime(_historyToDate.year, _historyToDate.month, _historyToDate.day).add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
          return itemDate.isAfter(start.subtract(const Duration(seconds: 1))) && itemDate.isBefore(end.add(const Duration(seconds: 1)));
        } catch (e) {
          debugPrint('Date parsing error for ${item.fDate}: $e');
          return true; // Don't filter out if parsing fails
        }
      }).toList();
      _onSearchChanged(); // Re-apply text search
    });
  }

  void _resetForm() {
    setState(() {
      _currentAction = 'Create';
      _editId = null;
      _editDetails = null;
      _startDate = DateTime.now();
      _endDate = DateTime.now();
      
      final dtStatus = _lookupData?['dtStatus'] as List?;
      if (dtStatus != null && dtStatus.isNotEmpty) {
        _selectedStatus = dtStatus[0]['Status'];
      }
      
      final dtLR = _lookupData?['dtLR'] as List?;
      if (dtLR != null && dtLR.isNotEmpty) {
        _selectedReason = dtLR[0]['LRName'];
      }
      
      _remarksController.clear();
    });
  }

  void _loadData() {
    _fetchHistory();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    setState(() {
      _isLoadingBalance = true;
      _balanceError = null;
    });
    try {
      final fDate = DateFormat('dd-MM-yyyy').format(_startDate);
      final balances = await _leaveService.getSupplementaryLeaveBalance(fDate);
      final uniqueBalances = <String, LeaveBalance>{};
      for (var b in balances) {
        uniqueBalances[b.leaveType] = b;
      }
      setState(() {
        _balances = uniqueBalances.values.toList();
        _isLoadingBalance = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _balanceError = e.toString().replaceAll('Exception: ', '');
          _isLoadingBalance = false;
        });
      }
    }
  }

  Future<void> _fetchLookup() async {
    setState(() => _isLoadingLookup = true);
    try {
      final lookup = await _leaveService.getLeaveLookup();
      setState(() {
        _lookupData = lookup;
        final dtStatus = lookup['dtStatus'] as List?;
        if (dtStatus != null && dtStatus.isNotEmpty) {
          _selectedStatus = dtStatus[0]['Status'];
        }
        final dtLR = lookup['dtLR'] as List?;
        if (dtLR != null && dtLR.isNotEmpty) {
          _selectedReason = dtLR[0]['LRName'];
        }
        _isLoadingLookup = false;
      });
    } catch (e) {
      setState(() => _isLoadingLookup = false);
    }
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });
    try {
      final history = await _leaveService.getSupplementaryHistory();
      setState(() {
        _history = history;
        _dateFilteredHistory = history;
        _applyHistoryDateFilter(); // Apply default date filter
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() {
        _historyError = e.toString().replaceAll('Exception: ', '');
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedStatus == null) {
      UIConstants.showErrorSnackBar(context, 'Please select status');
      return;
    }
    if (_selectedReason == null) {
      UIConstants.showErrorSnackBar(context, 'Please select reason');
      return;
    }
    if (_remarksController.text.trim().isEmpty) {
      UIConstants.showErrorSnackBar(context, 'Please enter remarks');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dateFormat = DateFormat('dd-MM-yyyy');
      await _leaveService.submitSupplementaryRequest(
        sDate: dateFormat.format(DateTime.now()),
        fDate: dateFormat.format(_startDate),
        tDate: dateFormat.format(_endDate),
        remarks: _remarksController.text.trim(),
        status: _selectedStatus!,
        lrName: _selectedReason!,
        actions: _currentAction,
        editId: _editId ?? "",
        oldDetails: _editDetails,
      );
      
      if (mounted) {
        UIConstants.showSuccessSnackBar(
          context, 
          'Supplementary request ${_currentAction == 'Create' ? 'submitted' : 'updated'} successfully'
        );
        _resetForm();
        await _fetchHistory();
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        UIConstants.showErrorSnackBar(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _handleAction(LeaveRequest item, String action) async {
    if (action == 'View') {
      _showViewDialog(item);
    } else if (action == 'Modify' || action == 'Revise') {
      _loadEditData(item, action);
    } else if (action == 'Delete' || action == 'Cancel') {
      _confirmDelete(item, action);
    }
  }

  Future<void> _loadEditData(LeaveRequest item, String action) async {
    setState(() => _isLoadingHistory = true);
    try {
      final details = await _leaveService.getSupplementaryDetails(item.id, action: action);
      setState(() {
        _currentAction = action;
        _editId = item.id;
        _editDetails = details;
        
        // Populate form
        try {
          _startDate = DateFormat('dd-MM-yyyy').parse(details['FromDate1'] ?? details['FromDate']);
          _endDate = DateFormat('dd-MM-yyyy').parse(details['ToDate1'] ?? details['ToDate']);
        } catch (_) {}
        
        _selectedStatus = details['Status1'] ?? details['Status'];
        _selectedReason = details['LRName1'] ?? details['LRName'];
        _remarksController.text = details['Remarks1'] ?? details['Remarks'] ?? '';
        
        _isLoadingHistory = false;
        _tabController.animateTo(0); // Switch to Apply tab
      });
    } catch (e) {
      setState(() => _isLoadingHistory = false);
      if (mounted) {
        UIConstants.showErrorSnackBar(context, 'Error loading details: $e');
      }
    }
  }

  void _showViewDialog(LeaveRequest item) async {
    UIConstants.showViewModal(
      context: context,
      title: 'Supplementary Request Details',
      body: FutureBuilder<Map<String, dynamic>>(
        future: _leaveService.getSupplementaryDetails(item.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) {
            return Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red))));
          }
          
          final d = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                UIConstants.buildDetailItem('Ticket No', d['TicketNo1'] ?? d['TicketNo'] ?? ''),
                UIConstants.buildDetailItem('Employee', d['EmpName1'] ?? d['EmpName'] ?? ''),
                UIConstants.buildDetailItem('Request Date', d['SDate1'] ?? d['SDate'] ?? ''),
                UIConstants.buildDetailItem('From Date', d['FromDate1'] ?? d['FromDate'] ?? ''),
                UIConstants.buildDetailItem('To Date', d['ToDate1'] ?? d['ToDate'] ?? ''),
                UIConstants.buildDetailItem('Status', d['Status1'] ?? d['Status'] ?? ''),
                UIConstants.buildDetailItem('Reason', d['Remarks1'] ?? d['Remarks'] ?? ''),
                UIConstants.buildDetailItem('Approval Status', d['App'] ?? ''),
                UIConstants.buildDetailItem('Remarks', d['AppRemarks1'] ?? d['AppRemarks'] ?? ''),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(LeaveRequest item, String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action Request'),
        content: Text('Are you sure you want to $action this supplementary request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoadingHistory = true);
              try {
                final details = await _leaveService.getSupplementaryDetails(item.id, action: action);
                // For delete, we just need to pass the status/action
                final dateFormat = DateFormat('dd-MM-yyyy');
                await _leaveService.submitSupplementaryRequest(
                  sDate: dateFormat.format(DateTime.now()),
                  fDate: details['FromDate'] ?? details['FromDate1'] ?? '',
                  tDate: details['ToDate'] ?? details['ToDate1'] ?? '',
                  remarks: details['Remarks'] ?? details['Remarks1'] ?? '',
                  status: details['Status'] ?? details['Status1'] ?? '',
                  lrName: details['LRName'] ?? details['LRName1'] ?? '',
                  actions: action,
                  editId: item.id,
                  oldDetails: details,
                );
                await _fetchHistory();
                if (mounted) {
                  UIConstants.showSuccessSnackBar(context, 'Request $action successfully');
                }
              } catch (e) {
                setState(() => _isLoadingHistory = false);
                if (mounted) {
                  UIConstants.showErrorSnackBar(context, 'Error: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _remarksController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Supplementary Request', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(text: 'Apply'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildApplyTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildApplyTab() {
    if (_isLoadingLookup) return const Center(child: CircularProgressIndicator());

    final dtStatus = (_lookupData?['dtStatus'] as List?)?.map((e) => e['Status'].toString()).toList() ?? [];
    final dtLR = (_lookupData?['dtLR'] as List?)?.map((e) => e['LRName'].toString()).toList() ?? [];

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchBalance();
        await _fetchLookup();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeaveBalanceSummary(),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppStyles.modernCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentAction == 'Create' ? 'New Supplementary Request' : 'Update Supplementary Request', 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildDatePickerField('From Date', _startDate, (date) => setState(() => _startDate = date))),
                    const SizedBox(width: 15),
                    Expanded(child: _buildDatePickerField('To Date', _endDate, (date) => setState(() => _endDate = date))),
                  ],
                ),
                const SizedBox(height: 15),
                _buildDropdownField('Status', dtStatus, _selectedStatus, (val) => setState(() => _selectedStatus = val)),
                const SizedBox(height: 15),
                _buildDropdownField('Reason', dtLR, _selectedReason, (val) => setState(() => _selectedReason = val)),
                const SizedBox(height: 15),
                _buildTextField('Remarks', 'Enter remarks', _remarksController, maxLines: 3),
                const SizedBox(height: 20),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitRequest,
                        style: _currentAction == 'Create' ? UIConstants.primaryButtonStyle : UIConstants.updateButtonStyle,
                        child: _isSubmitting 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              _currentAction == 'Create' ? 'Submit Request' : 'Update Application', 
                              style: UIConstants.buttonTextStyle
                            ),
                      ),
                    ),
                    if (_currentAction != 'Create') ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _resetForm,
                          icon: const Icon(Icons.cancel, size: 20),
                          label: const Text('Cancel Edit'),
                          style: UIConstants.cancelButtonStyle,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) return const Center(child: CircularProgressIndicator());
    if (_historyError != null) return Center(child: Text(_historyError!, style: const TextStyle(color: Colors.red)));

    return RefreshIndicator(
      onRefresh: () async => _fetchHistory(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(12), 
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Supplementary History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildTableActionsRow(),
                  const SizedBox(height: 16),
                  if (_filteredHistory.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No history found')))
                  else
                    _buildHistoryCards(),
                  const Divider(),
                  _buildPaginationFooter(_filteredHistory.length),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCards() {
    int start = _currentPage * _rowsPerPage;
    int end = start + _rowsPerPage;
    if (end > _filteredHistory.length) end = _filteredHistory.length;
    List<LeaveRequest> displayedItems = _filteredHistory.sublist(start, end);

    return Column(
      children: displayedItems.map((item) => _buildHistoryCard(item)).toList(),
    );
  }

  Widget _buildHistoryCard(LeaveRequest item) {
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
              _buildCardItem('TKT.NO', item.ticketNo, flex: 1),
              _buildCardItem('DATE', item.sDate, flex: 1),
              _buildActions(item),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              _buildCardItem('FROM', item.fDate, flex: 1),
              _buildCardItem('TO', item.tDate, flex: 1),
              _buildCardItem('STATUS', item.status, flex: 1, isHighlight: true),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildCardItem('REASON', item.remarks, flex: 2),
              _buildCardItem('APP. STATUS', item.app, flex: 1, isHighlight: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(String label, String value, {int flex = 1, bool isHighlight = false}) {
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(
            value, 
            style: TextStyle(
              fontSize: 12, 
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight ? AppColors.primary : const Color(0xFF1E1E1E),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(LeaveRequest item) {
    bool canEdit = (item.app == "-" || item.app == "Pending");
    
    return UIConstants.buildActionButtons(
      onView: () => _handleAction(item, 'View'),
      onEdit: () => _handleAction(item, canEdit ? 'Modify' : 'Revise'),
      onDelete: () => _handleAction(item, canEdit ? 'Delete' : 'Cancel'),
      editTooltip: canEdit ? 'Modify' : 'Revise',
      deleteTooltip: canEdit ? 'Delete' : 'Cancel',
    );
  }

  Widget _buildTableActionsRow() {
    return Column(
      children: [
        _buildHistoryDateFilterRow(),
        const SizedBox(height: 16),
        _buildHistorySearchAndRowsRow(),
      ],
    );
  }

  Widget _buildHistoryDateFilterRow() {
    return DateFilterRow(
      fromDate: _historyFromDate,
      toDate: _historyToDate,
      onFromDateTap: () => _selectHistoryDate(true),
      onToDateTap: () => _selectHistoryDate(false),
      onSearch: _applyHistoryDateFilter,
    );
  }

  Widget _buildHistorySearchAndRowsRow() {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          // Row per page
          const Text('Rows: '),
          DropdownButton<int>(
            value: _rowsPerPage,
            items: [10, 25, 50, 100].map((e) => DropdownMenuItem(value: e, child: Text('$e'))).toList(),
            onChanged: (val) {
                if (val != null) setState(() {
                  _rowsPerPage = val;
                  _currentPage = 0;
                });
            },
            underline: Container(), // Remove underline
          ),
          const SizedBox(width: 16),
          // Search Box
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

  Widget _buildPaginationFooter(int count) {
    int start = _currentPage * _rowsPerPage;
    int end = start + _rowsPerPage;
    if (end > count) end = count;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Showing ${count == 0 ? 0 : start + 1} to $end of $count entries', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Row(
            children: [
              IconButton(
                onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                icon: Icon(Icons.chevron_left, color: _currentPage > 0 ? Colors.black : Colors.grey),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: end < count ? () => setState(() => _currentPage++) : null, 
                icon: Icon(Icons.chevron_right, color: end < count ? Colors.black : Colors.grey),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDatePickerField(String label, DateTime selectedDate, Function(DateTime) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) onSelect(date);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('dd-MM-yyyy').format(selectedDate)),
                const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> items, String? value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String placeholder, TextEditingController controller, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: placeholder,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveBalanceSummary() {
    if (_isLoadingBalance) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(),
      ));
    }

    if (_balanceError != null) {
      return Center(child: Text(_balanceError!, style: const TextStyle(color: Colors.red)));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.modernCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Leave Balance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          if (_balances.isEmpty)
            const Text('No leave balances found')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _balances.map((b) => Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: _buildBalanceItem(b.leaveType, b.yearBalance.toStringAsFixed(1), AppColors.primary),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
