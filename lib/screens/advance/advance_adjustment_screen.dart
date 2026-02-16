import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/ui_constants.dart';
import '../../core/widgets/date_picker_field.dart';
import '../../data/services/advance_service.dart';

class AdvanceAdjustmentScreen extends StatefulWidget {
  const AdvanceAdjustmentScreen({super.key});

  @override
  State<AdvanceAdjustmentScreen> createState() => _AdvanceAdjustmentScreenState();
}

class _AdvanceAdjustmentScreenState extends State<AdvanceAdjustmentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdvanceService _advanceService = AdvanceService();
  
  List<AdvanceAdjustmentRequest> _history = [];
  bool _isLoadingHistory = true;
  String? _historyError;

  // Form data
  List<dynamic> _deductionTypes = [];
  List<dynamic> _salaryMonths = [];
  List<dynamic> _approvalTypes = [];
  List<dynamic> _advanceNos = [];
  bool _isLoadingLookups = true;

  // Form fields
  DateTime _selectedDate = DateTime.now();
  String? _selectedDeduction;
  String? _selectedSalaryMonth;
  String? _selectedApprovalType;
  String? _selectedAdvNo;
  final TextEditingController _adjAmountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  bool _isSubmitting = false;

  // Actions State
  String _currentAction = 'Create'; // Create, Modify, Delete, View
  String? _editId;
  Map<String, dynamic>? _editDetails;

  // Table & Search State
  final TextEditingController _searchController = TextEditingController();
  int _rowsPerPage = 10;
  List<AdvanceAdjustmentRequest> _dateFilteredHistory = [];
  List<AdvanceAdjustmentRequest> _filteredHistory = [];
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
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredHistory = List.from(_dateFilteredHistory);
      } else {
        _filteredHistory = _dateFilteredHistory.where((request) => 
          (request.ticketNo.toLowerCase().contains(_searchController.text.toLowerCase())) ||
          (request.empName.toLowerCase().contains(_searchController.text.toLowerCase())) ||
          (request.salaryName.toLowerCase().contains(_searchController.text.toLowerCase()))
        ).toList();
      }
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
          DateTime itemDate = DateFormat('dd-MM-yyyy').parse(item.reqDate);
          DateTime start = DateTime(_historyFromDate.year, _historyFromDate.month, _historyFromDate.day);
          DateTime end = DateTime(_historyToDate.year, _historyToDate.month, _historyToDate.day).add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
          return itemDate.isAfter(start.subtract(const Duration(seconds: 1))) && itemDate.isBefore(end.add(const Duration(seconds: 1)));
        } catch (e) {
          return false;
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
      _selectedDate = DateTime.now();
      _selectedDeduction = null;
      _selectedSalaryMonth = null;
      _selectedApprovalType = null;
      _selectedAdvNo = null;
      _adjAmountController.clear();
      _remarksController.clear();
    });
    _fetchLookups();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _fetchHistory(),
      _fetchLookups(),
      _fetchAdvanceNos(),
    ]);
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });
    try {
      final history = await _advanceService.getAdvanceAdjustmentHistory();
      setState(() {
        _history = history;
        _dateFilteredHistory = history;
        _applyHistoryDateFilter();
        _isLoadingHistory = false;
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
      final lookupData = await _advanceService.getAdvanceAdjustmentLookup();
      setState(() {
        _deductionTypes = lookupData['dtDed'] ?? [];
        _salaryMonths = lookupData['dtSalary'] ?? [];
        // Legacy code uses dtAAReason (missing R), handling both cases
        _approvalTypes = lookupData['dtAARReason'] ?? lookupData['dtAAReason'] ?? [];
        
        // Debug keys
        if (_deductionTypes.isNotEmpty) print('Ded keys: ${_deductionTypes.first.keys}');
        if (_salaryMonths.isNotEmpty) print('Salary keys: ${_salaryMonths.first.keys}');
        if (_approvalTypes.isNotEmpty) print('Approval keys: ${_approvalTypes.first.keys}');
        
        if (lookupData['ReqDate'] != null && lookupData['ReqDate'] != "") {
           try {
             _selectedDate = DateFormat('dd-MM-yyyy').parse(lookupData['ReqDate']);
           } catch (_) {}
        }
        
        _isLoadingLookups = false;
      });
    } catch (e) {
      if (mounted) {
        UIConstants.showErrorSnackBar(context, 'Failed to load lookups: $e');
      }
      setState(() => _isLoadingLookups = false);
    }
  }

  Future<void> _fetchAdvanceNos() async {
    try {
      final advNos = await _advanceService.getAdvanceNos();
      setState(() {
        _advanceNos = advNos;
        if (_advanceNos.isNotEmpty) print('AdvNo keys: ${_advanceNos.first.keys}');
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load advance numbers: $e')),
        );
      }
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedDeduction == null) {
      UIConstants.showErrorSnackBar(context, 'Please select Deduction Type');
      return;
    }
    if (_selectedSalaryMonth == null) {
      UIConstants.showErrorSnackBar(context, 'Please select Salary Month');
      return;
    }
    if (_selectedAdvNo == null) {
      UIConstants.showErrorSnackBar(context, 'Please select Advance No');
      return;
    }
    if (_selectedApprovalType == null) {
      UIConstants.showErrorSnackBar(context, 'Please select Approval Type');
      return;
    }
    
    final amount = double.tryParse(_adjAmountController.text) ?? 0;
    
    // Only validate > 0 for Create or Modify
    if (_currentAction != 'Delete' && _currentAction != 'Cancel') {
      if (amount <= 0) {
        UIConstants.showErrorSnackBar(context, 'Please enter valid adjustment amount');
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final dateFormat = DateFormat('dd-MM-yyyy');
      final Map<String, dynamic> postData = _editDetails != null 
          ? Map<String, dynamic>.from(_editDetails!) 
          : {};

      postData["ReqDate"] = dateFormat.format(_selectedDate);
      postData["DedName"] = _selectedDeduction;
      postData["SalaryMonth"] = _selectedSalaryMonth;
      postData["AARReason"] = _selectedApprovalType;
      postData["Remarks"] = _remarksController.text.trim();
      postData["AdvNo"] = _selectedAdvNo;
      postData["AdjAmount"] = amount;
      postData["Actions"] = _currentAction;
      postData["EditId"] = _editId ?? "";

      await _advanceService.submitAdvanceAdjustment(postData);
      
      if (mounted) {
        UIConstants.showSuccessSnackBar(
          context, 
          'Adjustment request ${_currentAction == 'Create' ? 'submitted' : 'updated'} successfully'
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

  void _handleAction(AdvanceAdjustmentRequest item, String action) async {
    if (action == 'View') {
      _showViewDialog(item);
    } else if (action == 'Modify' || action == 'Revise') {
      _loadEditData(item, action);
    } else if (action == 'Delete' || action == 'Cancel') {
      _confirmDelete(item, action);
    }
  }

  Future<void> _loadEditData(AdvanceAdjustmentRequest item, String action) async {
    setState(() => _isLoadingHistory = true);
    try {
      final details = await _advanceService.getAdvanceAdjustmentDetails(item.id, action);
      setState(() {
        _currentAction = action;
        _editId = item.id;
        _editDetails = details;
        
        // Populate form
        try {
          _selectedDate = DateFormat('dd-MM-yyyy').parse(details['ReqDate']);
        } catch (_) {}
        
        _selectedDeduction = details['DedName'];
        _selectedSalaryMonth = details['SalaryMonth'];
        _selectedApprovalType = details['AARReason'];
        _selectedAdvNo = details['AdvNo'];
        _adjAmountController.text = (details['AdjAmount'] ?? 0).toString();
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

  void _showViewDialog(AdvanceAdjustmentRequest item) async {
    UIConstants.showViewModal(
      context: context,
      title: 'Advance Adjustment Details',
      body: FutureBuilder<Map<String, dynamic>>(
        future: _advanceService.getAdvanceAdjustmentDetails(item.id, 'View'),
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
                UIConstants.buildDetailItem('Request Date', d['ReqDate'] ?? ''),
                UIConstants.buildDetailItem('Deduction', d['DedName'] ?? ''),
                UIConstants.buildDetailItem('Salary Month', d['SalaryMonth'] ?? ''),
                UIConstants.buildDetailItem('Advance No', d['AdvNo'] ?? ''),
                UIConstants.buildDetailItem('Reason', d['AAReason'] ?? ''),
                UIConstants.buildDetailItem('Amount', (d['AdjAmount'] ?? 0).toString()),
                UIConstants.buildDetailItem('Remarks', d['Remarks'] ?? ''),
                UIConstants.buildDetailItem('Status', d['App'] ?? ''),
                UIConstants.buildDetailItem('Approved By', d['AppBy'] ?? ''),
                UIConstants.buildDetailItem('Approved On', d['AppOn'] ?? ''),
              ],
            ),
          );
        },
      ),
    );
  }



  void _confirmDelete(AdvanceAdjustmentRequest item, String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action Request'),
        content: Text('Are you sure you want to $action this adjustment request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoadingHistory = true);
              try {
                final details = await _advanceService.getAdvanceAdjustmentDetails(item.id, action);
                await _advanceService.submitAdvanceAdjustment(details);
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
    _adjAmountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Advance Adjustment', style: UIConstants.pageTitleStyle),
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
    if (_isLoadingLookups) return const Center(child: CircularProgressIndicator());

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
                      _currentAction == 'Create' ? 'New Adjustment Request' : 'Update Adjustment Request', 
                      style: UIConstants.sectionHeaderStyle
                    ),
                const SizedBox(height: 20),
                _buildDatePickerField('Request Date', _selectedDate, (date) => setState(() => _selectedDate = date)),
                const SizedBox(height: 15),
                _buildDropdownField(
                  'Deduction Type', 
                  _deductionTypes.map((e) => e['EDName']?.toString() ?? '').toList(), 
                  _selectedDeduction, 
                  (val) => setState(() => _selectedDeduction = val)
                ),
                const SizedBox(height: 15),
                _buildDropdownField(
                  'Salary Month', 
                  _salaryMonths.map((e) => e['SalaryName']?.toString() ?? '').toList(), 
                  _selectedSalaryMonth, 
                  (val) => setState(() => _selectedSalaryMonth = val)
                ),
                const SizedBox(height: 15),
                _buildDropdownField(
                  'Advance No', 
                  _advanceNos.map((e) => e['AdvId']?.toString() ?? '').toList(), 
                  _selectedAdvNo, 
                  (val) => setState(() => _selectedAdvNo = val)
                ),
                const SizedBox(height: 15),
                _buildDropdownField(
                  'Approval Type', 
                  _approvalTypes.map((e) => e['AAReason']?.toString() ?? '').toList(), 
                  _selectedApprovalType, 
                  (val) => setState(() => _selectedApprovalType = val)
                ),
                const SizedBox(height: 15),
                _buildTextField('Adjustment Amount', '0.00', _adjAmountController, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
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
                  const Text('Advance Adjustment History', style: UIConstants.sectionHeaderStyle),
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
    int displayCount = _filteredHistory.length > _rowsPerPage ? _rowsPerPage : _filteredHistory.length;
    List<AdvanceAdjustmentRequest> displayedItems = _filteredHistory.take(displayCount).toList();

    return Column(
      children: displayedItems.map((item) => _buildHistoryCard(item)).toList(),
    );
  }

  Widget _buildHistoryCard(AdvanceAdjustmentRequest item) {
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
              _buildCardItem('REQ. DATE', item.reqDate, flex: 1),
              _buildCardItem('SALARY MONTH', item.salaryName, flex: 2),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildCardItem('AMOUNT', item.adjAmount.toStringAsFixed(2), flex: 1, isHighlight: true),
              _buildCardItem('STATUS', item.app, flex: 1, isHighlight: true),
              _buildCardItem('APP. BY', item.appBy, flex: 1),
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
          Text(label, style: UIConstants.tinyTextStyle),
          const SizedBox(height: 4),
          Text(
            value, 
            style: TextStyle(
              fontSize: UIConstants.fontSizeSmall, 
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

  Widget _buildActions(AdvanceAdjustmentRequest item) {
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
                if (val != null) setState(() => _rowsPerPage = val);
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Showing 1 to $count of $count entries', style: UIConstants.smallTextStyle.copyWith(color: Colors.grey.shade600)),
          const Row(
            children: [
              Icon(Icons.chevron_left, color: Colors.grey),
              SizedBox(width: 16),
              Icon(Icons.chevron_right, color: Colors.grey),
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
        Text(label, style: UIConstants.bodyTextStyle),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now().add(const Duration(days: 60)),
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
        Text(label, style: UIConstants.bodyTextStyle),
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
        Text(label, style: UIConstants.bodyTextStyle),
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
