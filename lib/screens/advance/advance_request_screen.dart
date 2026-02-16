import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/ui_constants.dart';
import '../../core/widgets/date_picker_field.dart';
import '../../data/services/advance_service.dart';

class AdvanceRequestScreen extends StatefulWidget {
  const AdvanceRequestScreen({super.key});

  @override
  State<AdvanceRequestScreen> createState() => _AdvanceRequestScreenState();
}

class _AdvanceRequestScreenState extends State<AdvanceRequestScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdvanceService _advanceService = AdvanceService();
  
  List<AdvanceRequest> _history = [];
  bool _isLoadingHistory = true;
  String? _historyError;

  // Form data
  List<dynamic> _deductionTypes = [];
  List<dynamic> _approvalTypes = [];
  bool _isLoadingLookups = true;

  // Form fields
  DateTime _selectedDate = DateTime.now();
  String? _selectedDeduction;
  String? _selectedApprovalType;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _insAmountController = TextEditingController();
  final TextEditingController _noofInsController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  bool _isSubmitting = false;

  // Actions State
  String _currentAction = 'Create'; // Create, Modify, Delete, View
  String? _editId;
  Map<String, dynamic>? _editDetails;

  // Table & Search State
  final TextEditingController _searchController = TextEditingController();
  int _rowsPerPage = 10;
  List<AdvanceRequest> _dateFilteredHistory = [];
  List<AdvanceRequest> _filteredHistory = [];
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
    
    _amountController.addListener(_calculateInstallments);
    _insAmountController.addListener(_calculateInstallments);
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
          (request.edName.toLowerCase().contains(_searchController.text.toLowerCase()))
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
          DateTime itemDate = DateFormat('dd-MM-yyyy').parse(item.sDate);
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
      _selectedApprovalType = null;
      _amountController.clear();
      _insAmountController.clear();
      _noofInsController.clear();
      _remarksController.clear();
    });
    _fetchLookups(); // Re-fetch default values if needed
  }

  void _calculateInstallments() {
    final amt = double.tryParse(_amountController.text) ?? 0;
    final ins = double.tryParse(_insAmountController.text) ?? 0;
    if (ins > 0) {
      final noofins = (amt / ins).ceil();
      _noofInsController.text = noofins.toString();
    } else {
      _noofInsController.text = "0";
    }
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
      final history = await _advanceService.getAdvanceHistory();
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
      final lookupData = await _advanceService.getAdvanceLookup();
      setState(() {
        _deductionTypes = lookupData['dtEarn'] ?? [];
        _approvalTypes = lookupData['dtReason'] ?? [];
        
        if (_deductionTypes.isNotEmpty) print('Adv Ded keys: ${_deductionTypes.first.keys}');
        if (_approvalTypes.isNotEmpty) print('Adv Reason keys: ${_approvalTypes.first.keys}');
        
        if (lookupData['SDate'] != null && lookupData['SDate'] != "") {
           try {
             _selectedDate = DateFormat('dd-MM-yyyy').parse(lookupData['SDate']);
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

  Future<void> _submitRequest() async {
    if (_selectedDeduction == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Deduction Type')));
      return;
    }
    if (_selectedApprovalType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Approval Type')));
      return;
    }
    
    final amount = double.tryParse(_amountController.text) ?? 0;
    final insAmount = double.tryParse(_insAmountController.text) ?? 0;
    
    // Only validate > 0 for Create or Modify, not Delete
    if (_currentAction != 'Delete' && _currentAction != 'Cancel') {
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid advance amount')));
        return;
      }
      if (insAmount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid installment amount')));
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final dateFormat = DateFormat('dd-MM-yyyy');
      final Map<String, dynamic> postData = _editDetails != null 
          ? Map<String, dynamic>.from(_editDetails!) 
          : {};

      postData["EDName"] = _selectedDeduction;
      postData["Reason"] = _selectedApprovalType;
      postData["SDate"] = dateFormat.format(_selectedDate);
      postData["AdvAmount"] = amount;
      postData["NoofIns"] = int.tryParse(_noofInsController.text) ?? 0;
      postData["InsAmount"] = insAmount;
      postData["Active"] = postData["Active"] ?? true;
      postData["Remarks"] = _remarksController.text.trim();
      postData["Actions"] = _currentAction;
      postData["EditId"] = _editId ?? "";

      await _advanceService.submitAdvanceRequest(postData);
      
      if (mounted) {
        UIConstants.showSuccessSnackBar(
          context, 
          'Advance request ${_currentAction == 'Create' ? 'submitted' : 'updated'} successfully'
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

  void _handleAction(AdvanceRequest item, String action) async {
    if (action == 'View') {
      _showViewDialog(item);
    } else if (action == 'Modify' || action == 'Revise') {
      _loadEditData(item, action);
    } else if (action == 'Delete' || action == 'Cancel') {
      _confirmDelete(item, action);
    }
  }

  Future<void> _loadEditData(AdvanceRequest item, String action) async {
    setState(() => _isLoadingHistory = true);
    try {
      final details = await _advanceService.getAdvanceDetails(item.id, action);
      setState(() {
        _currentAction = action;
        _editId = item.id;
        _editDetails = details;
        
        // Populate form
        try {
          _selectedDate = DateFormat('dd-MM-yyyy').parse(details['SDate']);
        } catch (_) {}
        
        _selectedDeduction = details['EDName'];
        // Ensure the value exists in lookup, otherwise it might be null if not found
        // if (!_deductionTypes.any((e) => e['EDName'] == _selectedDeduction)) _selectedDeduction = null;

        _selectedApprovalType = details['Reason'];
        
        _amountController.text = (details['AdvAmount'] ?? 0).toString();
        _insAmountController.text = (details['InsAmount'] ?? 0).toString();
        _noofInsController.text = (details['NoofIns'] ?? 0).toString();
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

  void _showViewDialog(AdvanceRequest item) async {
    UIConstants.showViewModal(
      context: context,
      title: 'Advance Request Details',
      body: FutureBuilder<Map<String, dynamic>>(
        future: _advanceService.getAdvanceDetails(item.id, 'View'),
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
                UIConstants.buildDetailItem('Date', d['SDate'] ?? ''),
                UIConstants.buildDetailItem('Deduction', d['EDName'] ?? ''),
                UIConstants.buildDetailItem('Reason', d['Reason'] ?? ''),
                UIConstants.buildDetailItem('Amount', (d['AdvAmount'] ?? 0).toString()),
                UIConstants.buildDetailItem('Installments', (d['NoofIns'] ?? 0).toString()),
                UIConstants.buildDetailItem('Inst. Amount', (d['InsAmount'] ?? 0).toString()),
                UIConstants.buildDetailItem('Remarks', d['Remarks'] ?? ''),
                UIConstants.buildDetailItem('Status', d['App'] ?? ''),
                UIConstants.buildDetailItem('Approved By', d['AppBy'] ?? ''),
                UIConstants.buildDetailItem('Approved On', d['On'] ?? ''),
              ],
            ),
          );
        },
      ),
    );
  }



  void _confirmDelete(AdvanceRequest item, String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action Request'),
        content: Text('Are you sure you want to $action this advance request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoadingHistory = true);
              try {
                final details = await _advanceService.getAdvanceDetails(item.id, action);
                await _advanceService.submitAdvanceRequest(details);
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
    _amountController.dispose();
    _insAmountController.dispose();
    _noofInsController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Advance Request', style: TextStyle(color: Colors.white, fontSize: 18)),
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
                      _currentAction == 'Create' ? 'New Advance/Loan Request' : 'Update Advance Request', 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                const SizedBox(height: 20),
                _buildDatePickerField('Requested Date', _selectedDate, (date) => setState(() => _selectedDate = date)),
                const SizedBox(height: 15),
                _buildDropdownField(
                  'Deduction Type', 
                  _deductionTypes.map((e) => e['EDName']?.toString() ?? '').toList(), 
                  _selectedDeduction, 
                  (val) => setState(() => _selectedDeduction = val)
                ),
                const SizedBox(height: 15),
                _buildDropdownField(
                  'Approval Type', 
                  _approvalTypes.map((e) => e['AAReason']?.toString() ?? '').toList(), 
                  _selectedApprovalType, 
                  (val) => setState(() => _selectedApprovalType = val)
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Adv Amount', '0.00', _amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                    const SizedBox(width: 15),
                    Expanded(child: _buildTextField('Ins Amount', '0.00', _insAmountController, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                  ],
                ),
                const SizedBox(height: 15),
                _buildTextField('No of Installments', '0', _noofInsController, enabled: false),
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
                  const Text('Advance History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    List<AdvanceRequest> displayedItems = _filteredHistory.take(displayCount).toList();

    return Column(
      children: displayedItems.map((item) => _buildHistoryCard(item)).toList(),
    );
  }

  Widget _buildHistoryCard(AdvanceRequest item) {
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
              _buildCardItem('DATE', item.sDate, flex: 1),
              _buildCardItem('DEDUCTION', item.edName, flex: 2),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildCardItem('AMOUNT', item.advAmount.toStringAsFixed(2), flex: 1, isHighlight: true),
              _buildCardItem('STATUS', item.app, flex: 1, isHighlight: true),
              _buildCardItem('BY', item.appBy, flex: 1),
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
          Text(value, style: TextStyle(
            fontSize: 13, 
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight ? AppColors.primary : const Color(0xFF1E1E1E),
          )),
        ],
      ),
    );
  }

  Widget _buildActions(AdvanceRequest item) {
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
          Text('Showing 1 to $count of $count entries', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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

  Widget _buildDropdownField(String label, List<String> items, String? value, Function(String?) onChanged, {bool isReadOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300), 
              borderRadius: BorderRadius.circular(8),
              color: isReadOnly ? Colors.grey.shade100 : null,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: const Text('Select option'),
              items: items.map((e) => DropdownMenuItem(
                  value: e, 
                  child: Text(
                      e, 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                  )
              )).toList(),
              onChanged: isReadOnly ? null : onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String placeholder, TextEditingController controller, {int maxLines = 1, TextInputType keyboardType = TextInputType.text, bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: placeholder,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.all(12),
            fillColor: enabled ? null : Colors.grey.shade100,
            filled: !enabled,
          ),
        ),
      ],
    );
  }
}
