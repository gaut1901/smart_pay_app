import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/ui_constants.dart';
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
  List<AdvanceAdjustmentRequest> _filteredHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredHistory = _history;
      } else {
        _filteredHistory = _history.where((request) => 
          (request.ticketNo.toLowerCase().contains(_searchController.text.toLowerCase())) ||
          (request.empName.toLowerCase().contains(_searchController.text.toLowerCase())) ||
          (request.salaryName.toLowerCase().contains(_searchController.text.toLowerCase()))
        ).toList();
      }
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
      final history = await _advanceService.getAARHistory();
      setState(() {
        _history = history;
        _filteredHistory = history;
        _isLoadingHistory = false;
        _onSearchChanged();
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
      final lookupData = await _advanceService.getAARLookup();
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
      setState(() => _isLoadingLookups = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load lookups: $e')),
        );
      }
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Deduction Type')));
      return;
    }
    if (_selectedSalaryMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Salary Month')));
      return;
    }
    if (_selectedAdvNo == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Advance No')));
      return;
    }
    if (_selectedApprovalType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Approval Type')));
      return;
    }
    
    final amount = double.tryParse(_adjAmountController.text) ?? 0;
    
    // Only validate > 0 for Create or Modify
    if (_currentAction != 'Delete' && _currentAction != 'Cancel') {
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid adjustment amount')));
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final dateFormat = DateFormat('dd-MM-yyyy');
      final postData = {
        "ReqDate": dateFormat.format(_selectedDate),
        "DedName": _selectedDeduction,
        "SalaryMonth": _selectedSalaryMonth,
        "AARReason": _selectedApprovalType,
        "Remarks": _remarksController.text.trim(),
        "AdvNo": _selectedAdvNo,
        "AdjAmount": amount,
        "Actions": _currentAction,
        "EditId": _editId ?? "",
      };

      await _advanceService.submitAARRequest(postData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Advance adjustment request ${_currentAction == 'Create' ? 'submitted' : 'updated'} successfully')),
        );
        _resetForm();
        _fetchHistory();
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
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
      final details = await _advanceService.getAARDetails(item.id, action);
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading details: $e')));
    }
  }

  void _showViewDialog(AdvanceAdjustmentRequest item) async {
    UIConstants.showViewModal(
      context: context,
      title: 'Advance Adjustment Details',
      body: FutureBuilder<Map<String, dynamic>>(
        future: _advanceService.getAARDetails(item.id, 'View'),
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
                UIConstants.buildDetailItem('Reason', d['AARReason'] ?? ''),
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
                final dateFormat = DateFormat('dd-MM-yyyy');
                // Fetch details first to get necessary fields for delete payload
                final details = await _advanceService.getAARDetails(item.id, 'Delete');
                
                final postData = {
                  "ReqDate": details['ReqDate'],
                  "DedName": details['DedName'], 
                  "SalaryMonth": details['SalaryMonth'],
                  "AARReason": details['AARReason'], 
                  "Remarks": details['Remarks'] ?? "",
                  "AdvNo": details['AdvNo'], 
                  "AdjAmount": details['AdjAmount'],
                  "Actions": action,
                  "EditId": item.id,
                };
                await _advanceService.submitAARRequest(postData);
                _fetchHistory();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request $action successfully')));
                }
              } catch (e) {
                setState(() => _isLoadingHistory = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        title: const Text('Advance Adjustment', style: TextStyle(color: Colors.white, fontSize: 18)),
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
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
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Advance Adjustment History', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(8), 
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTableActionsRow(),
                  const SizedBox(height: 12),
                  if (_filteredHistory.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No history found')))
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(UIConstants.tableHeaderBg),
                        columns: [
                          DataColumn(label: Text('TICKET NO', style: UIConstants.tableHeaderStyle)),
                          DataColumn(label: Text('EMP NAME', style: UIConstants.tableHeaderStyle)),
                          DataColumn(label: Text('REQ DATE', style: UIConstants.tableHeaderStyle)),
                          DataColumn(label: Text('SALARY MONTH', style: UIConstants.tableHeaderStyle)),
                          DataColumn(label: Text('AMOUNT', style: UIConstants.tableHeaderStyle)),
                          DataColumn(label: Text('STATUS', style: UIConstants.tableHeaderStyle)),
                          DataColumn(label: Text('APP.BY', style: UIConstants.tableHeaderStyle)),
                          DataColumn(label: Text('ACTIONS', style: UIConstants.tableHeaderStyle)),
                        ],
                        rows: _filteredHistory.map((item) {
                          return DataRow(cells: [
                            DataCell(Text(item.ticketNo)),
                            DataCell(Text(item.empName)),
                            DataCell(Text(item.reqDate)),
                            DataCell(Text(item.salaryName)),
                            DataCell(Text(item.adjAmount.toStringAsFixed(2))),
                            DataCell(Text(item.app)),
                            DataCell(Text(item.appBy)),
                            DataCell(_buildActions(item)),
                          ]);
                        }).toList(),
                      ),
                    ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Row Per Page', style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
              child: Row(
                children: [
                  Text('$_rowsPerPage', style: const TextStyle(fontSize: 12)),
                  const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.blue),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 40,
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search by Ticket No, Name or Salary Month',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: InputBorder.none,
              suffixIcon: Icon(Icons.search, size: 20, color: Colors.grey),
            ),
          ),
        ),
      ],
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
