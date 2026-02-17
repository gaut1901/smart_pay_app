import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/ui_constants.dart';
import '../../core/widgets/date_picker_field.dart';
import '../../data/services/compoff_service.dart';

class LeaveCompensationScreen extends StatefulWidget {
  const LeaveCompensationScreen({super.key});

  @override
  State<LeaveCompensationScreen> createState() => _LeaveCompensationScreenState();
}

class _LeaveCompensationScreenState extends State<LeaveCompensationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CompOffService _compOffService = CompOffService();
  
  List<CompOffRequest> _history = [];
  bool _isLoadingHistory = true;
  String? _historyError;

  // Form data
  List<dynamic> _leaveNames = [];
  List<dynamic> _reasons = [];
  bool _isLoadingLookups = true;

  // Form fields
  DateTime _selectedDate = DateTime.now();
  String? _selectedLeaveName;
  String? _selectedReason;
  final TextEditingController _remarksController = TextEditingController();
  bool _isSubmitting = false;

  // Actions State
  String _currentAction = 'Create'; // Create, Modify, View, Delete
  String? _editId;
  Map<String, dynamic>? _editDetails;

  // Table & Search State
  final TextEditingController _searchController = TextEditingController();
  int _rowsPerPage = 10;
  int _currentPage = 0;
  List<CompOffRequest> _dateFilteredHistory = [];
  List<CompOffRequest> _filteredHistory = [];

  // Date Filters
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = now;

    _loadData();
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
          request.empName.toLowerCase().contains(query)
        ).toList();
      }
      _currentPage = 0;
    });
  }

  Future<void> _selectDate(bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
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

  void _applyDateFilter() {
    setState(() {
      _dateFilteredHistory = _history.where((item) {
        try {
          DateTime itemDate = DateFormat('dd-MM-yyyy').parse(item.sDate);
          DateTime start = DateTime(_fromDate.year, _fromDate.month, _fromDate.day);
          DateTime end = DateTime(_toDate.year, _toDate.month, _toDate.day).add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
          return itemDate.isAfter(start.subtract(const Duration(seconds: 1))) && itemDate.isBefore(end.add(const Duration(seconds: 1)));
        } catch (e) {
          return false;
        }
      }).toList();
      _onSearchChanged();
    });
  }

  void _resetForm() {
    setState(() {
      _currentAction = 'Create';
      _editId = null;
      _editDetails = null;
      _selectedDate = DateTime.now();
      if (_leaveNames.isNotEmpty) {
        _selectedLeaveName = _leaveNames[0]['Status'];
      }
      if (_reasons.isNotEmpty) {
        _selectedReason = _reasons[0]['LRName'];
      }
      _remarksController.clear();
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      _fetchHistory(),
      _fetchLookups(),
    ]);
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });
    try {
      final history = await _compOffService.getLeaveCompensationHistory();
      setState(() {
        _history = history;
        _dateFilteredHistory = history;
        _filteredHistory = history;
        _isLoadingHistory = false;
        _applyDateFilter(); // Apply default date filter
      });
    } catch (e) {
      setState(() {
        _historyError = e.toString().replaceAll('Exception: ', '');
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _fetchLookups() async {
    setState(() => _isLoadingLookups = true);
    try {
      final lookupData = await _compOffService.getLeaveCompensationLookup();
      setState(() {
        _leaveNames = lookupData['dtStatus'] ?? [];
        _reasons = lookupData['dtReason'] ?? [];
        
        // Default values
        if (_reasons.isNotEmpty) {
          _selectedReason = _reasons[0]['LRName'];
        }
        
        if (lookupData['SDate'] != null && lookupData['SDate'] != "") {
           try {
             _selectedDate = DateFormat('dd-MM-yyyy').parse(lookupData['SDate']);
           } catch (_) {}
        }
        
        _isLoadingLookups = false;
      });
    } catch (e) {
      setState(() => _isLoadingLookups = false);
      if (mounted) {
        UIConstants.showErrorSnackBar(context, 'Failed to load lookups: $e');
      }
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedReason == null) {
      UIConstants.showErrorSnackBar(context, 'Please select Reason');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dateFormat = DateFormat('dd-MM-yyyy');
      final Map<String, dynamic> postData = _editDetails != null 
          ? Map<String, dynamic>.from(_editDetails!) 
          : {};

      postData["SDate"] = dateFormat.format(_selectedDate);
      postData["Status"] = _selectedLeaveName ?? "";
      postData["LRName"] = _selectedReason!;
      postData["Remarks"] = _remarksController.text.trim();
      postData["Actions"] = _currentAction;
      postData["EditId"] = _editId ?? '';
      
      // Ensure App field is present (required by backend)
      if (!postData.containsKey("App") || postData["App"] == null) {
        postData["App"] = "";
      }

      await _compOffService.submitLeaveCompensation(postData);
      
      if (mounted) {
        UIConstants.showSuccessSnackBar(
          context, 
          'Compensation request ${_currentAction == 'Create' ? 'submitted' : 'updated'} successfully'
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

  void _handleAction(CompOffRequest item, String action) async {
    if (action == 'View') {
      _showViewDialog(item);
    } else if (action == 'Modify') {
      _loadEditData(item, action);
    } else if (action == 'Delete') {
      _confirmDelete(item, action);
    }
  }

  Future<void> _loadEditData(CompOffRequest item, String action) async {
    setState(() => _isLoadingHistory = true);
    try {
      final details = await _compOffService.getLeaveCompensationDetails(item.id, action);
      setState(() {
        _currentAction = action;
        _editId = item.id;
        _editDetails = details;
        
        // Populate form
        try {
          _selectedDate = DateFormat('dd-MM-yyyy').parse(details['SDate']);
        } catch (_) {}
        
        _selectedLeaveName = details['Status'];
        _selectedReason = details['LRName'];
        _remarksController.text = details['Remarks'] ?? '';
        
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

  void _showViewDialog(CompOffRequest item) async {
    UIConstants.showViewModal(
      context: context,
      title: 'Leave Compensation Details',
      body: FutureBuilder<Map<String, dynamic>>(
        future: _compOffService.getLeaveCompensationDetails(item.id, 'View'),
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
                UIConstants.buildDetailItem('Ticket No', d['TicketNo'] ?? ''),
                UIConstants.buildDetailItem('Employee', d['EmpName'] ?? ''),
                UIConstants.buildDetailItem('Worked Date', d['SDate'] ?? ''),
                UIConstants.buildDetailItem('Days', (d['Days'] ?? 0).toString()),
                UIConstants.buildDetailItem('Leave Name', d['Status'] ?? ''),
                UIConstants.buildDetailItem('Reason', d['LRName'] ?? ''),
                UIConstants.buildDetailItem('Remarks', d['Remarks'] ?? ''),
                UIConstants.buildDetailItem('Status', d['App'] ?? ''),
                UIConstants.buildDetailItem('Approved By', d['AppBy'] ?? ''),
              ],
            ),
          );
        },
      ),
    );
  }



  void _confirmDelete(CompOffRequest item, String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action Request'),
        content: Text('Are you sure you want to $action this compensation request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoadingHistory = true);
              try {
                // Fetch details first to get necessary fields for delete payload
                final details = await _compOffService.getLeaveCompensationDetails(item.id, action);
                await _compOffService.submitLeaveCompensation(details);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Leave Compensation', style: TextStyle(color: Colors.white, fontSize: 18)),
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
    if (_isLoadingLookups) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppStyles.modernCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    Text(
                      _currentAction == 'Create' ? 'Request Leave Compensation' : 'Update Leave Compensation', 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                const SizedBox(height: 20),
                _buildDatePickerField('Worked Date', _selectedDate, (date) => setState(() => _selectedDate = date)),
                const SizedBox(height: 15),
                _buildDropdownField(
                  'Leave Name', 
                  _leaveNames.map((e) => e['Status']?.toString() ?? '').toList(), 
                  _selectedLeaveName, 
                  (val) => setState(() => _selectedLeaveName = val)
                ),
                const SizedBox(height: 15),
                _buildDropdownField(
                  'Reason', 
                  _reasons.map((e) => e['LRName']?.toString() ?? '').toList(), 
                  _selectedReason, 
                  (val) => setState(() => _selectedReason = val)
                ),
                const SizedBox(height: 15),
                _buildTextField('Remarks', 'Enter remarks', _remarksController, maxLines: 2),
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
          const SizedBox(height: 20),
          const Card(
            color: Color(0xFFFFF4DE),
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFFFA800)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Use this form to claim compensation (Comp-off) for working on holidays or weekly offs.',
                      style: TextStyle(fontSize: 13, color: Color(0xFFFFA800), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
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
                  const Text('Compensation History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    List<CompOffRequest> displayedItems = _filteredHistory.sublist(start, end);

    return Column(
      children: displayedItems.map((item) => _buildHistoryCard(item)).toList(),
    );
  }

  Widget _buildHistoryCard(CompOffRequest item) {
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
              _buildCardItem('EMP NAME', item.empName, flex: 2),
              _buildActions(item),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
                  _buildCardItem('REQ. DATE', item.sDate, flex: 1),
              _buildCardItem('STATUS', item.status, flex: 1),
              _buildCardItem('DAYS', item.days.toString(), flex: 1, isHighlight: true),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildCardItem('APP. BY', item.appBy, flex: 1),
               // Placeholder for alignment
              Expanded(flex: 2, child: SizedBox()),
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

  Widget _buildActions(CompOffRequest item) {
    bool canEdit = item.app == "-";

    return UIConstants.buildActionButtons(
      onView: () => _handleAction(item, 'View'),
      onEdit: () => _handleAction(item, 'Modify'),
      onDelete: () => _handleAction(item, 'Delete'),
      editTooltip: 'Modify',
      deleteTooltip: 'Delete',
    );
  }

  Widget _buildTableActionsRow() {
    return Column(
      children: [
        _buildDateFilterRow(),
        const SizedBox(height: 16),
        _buildSearchAndRowsRow(),
      ],
    );
  }

  Widget _buildDateFilterRow() {
    return DateFilterRow(
      fromDate: _fromDate,
      toDate: _toDate,
      onFromDateTap: () => _selectDate(true),
      onToDateTap: () => _selectDate(false),
      onSearch: _applyDateFilter,
    );
  }

  Widget _buildSearchAndRowsRow() {
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

  Widget _buildHistoryItem(CompOffRequest item) {
    final status = item.app;
    final Color statusColor = status == 'Approved' ? Colors.green : (status == 'Rejected' ? Colors.red : Colors.orange);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.sDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.status, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
                Text('${item.days} Day(s)', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Ticket No: ${item.ticketNo}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            if (item.appBy.isNotEmpty && item.appBy != "-") ...[
              const SizedBox(height: 4),
              Text('Approved By: ${item.appBy}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ],
          ],
        ),
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
              firstDate: DateTime.now().subtract(const Duration(days: 90)),
              lastDate: DateTime.now().add(const Duration(days: 30)),
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
              hint: const Text('Select option'),
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
}
