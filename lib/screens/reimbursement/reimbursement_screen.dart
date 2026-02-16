import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants.dart';
import '../../core/ui_constants.dart';
import '../../core/widgets/date_picker_field.dart';
import '../../data/services/reimbursement_service.dart';
import '../../data/services/auth_service.dart';

class ReimbursementScreen extends StatefulWidget {
  const ReimbursementScreen({super.key});

  @override
  State<ReimbursementScreen> createState() => _ReimbursementScreenState();
}

class _ReimbursementScreenState extends State<ReimbursementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReimbursementService _reimbursementService = ReimbursementService();
  
  List<ReimbursementRequest> _history = [];
  bool _isLoadingHistory = true;
  String? _historyError;

  // Form data
  List<dynamic> _edNames = [];
  bool _isLoadingLookups = true;
  String? _empName;

  // Form fields
  DateTime _selectedDate = DateTime.now();
  String? _selectedEDName;
  final TextEditingController _amountController = TextEditingController();
  File? _selectedFile;
  String _unlimited = "false";
  double _maxAllowed = 0;
  bool _isSubmitting = false;

  // Table & Search State
  final TextEditingController _searchController = TextEditingController();
  int _rowsPerPage = 10;
  int _currentPage = 0;
  List<ReimbursementRequest> _dateFilteredHistory = [];
  List<ReimbursementRequest> _filteredHistory = [];

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
    
    // Check if we have member info from the TeamDetailScreen
    if (AuthService.memberEmpCode != "0" && AuthService.memberEmpCode != "") {
       // We can perhaps show the name in the title
    }
    
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
          (request.ticketNo.toLowerCase().contains(query)) ||
          (request.edName.toLowerCase().contains(query))
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
      final history = await _reimbursementService.getReimbursementHistory();
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

  Future<void> _fetchLookups() async {
    setState(() => _isLoadingLookups = true);
    try {
      final lookupData = await _reimbursementService.getReimbursementLookup();
      setState(() {
        _edNames = lookupData['dtEarn'] ?? [];
        _empName = lookupData['EmpName'];
        
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load lookups: $e')),
        );
      }
    }
  }

  Future<void> _onEDNameChanged(String? val) async {
    if (val == null) return;
    setState(() {
      _selectedEDName = val;
      _isLoadingLookups = true;
    });

    try {
      final detail = await _reimbursementService.getEDDetail(val);
      final earnList = detail['dtEarn'] as List;
      if (earnList.isNotEmpty) {
        setState(() {
          _unlimited = earnList[0]['Unlimited']?.toString() ?? "false";
          _maxAllowed = (earnList[0]['MaxAllowed'] is num) ? (earnList[0]['MaxAllowed'] as num).toDouble() : 0.0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load detail: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingLookups = false);
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedEDName == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Reimbursement Type')));
      return;
    }
    if (_amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter amount')));
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid amount')));
      return;
    }

    if (_unlimited != "true" && amount > _maxAllowed) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Amount exceeds maximum allowed limit of $_maxAllowed')));
       return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dateFormat = DateFormat('dd-MM-yyyy');
      await _reimbursementService.submitReimbursementRequest(
        sDate: dateFormat.format(_selectedDate),
        amount: amount,
        maxAllowed: _maxAllowed,
        unlimited: _unlimited,
        empName: _empName ?? '',
        edName: _selectedEDName!,
        file: _selectedFile,
        actions: _isEditing ? "Modify" : "Add",
        editId: _editId ?? "",
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reimbursement request submitted successfully')),
        );
        _amountController.clear();
        setState(() {
          _selectedFile = null;
          _selectedEDName = null;
          _maxAllowed = 0;
          _unlimited = "false";
          _isEditing = false;
          _editId = null;
        });
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

  bool _isEditing = false;
  String? _editId;

  Future<void> _editRequest(ReimbursementRequest request) async {
    setState(() => _isLoadingLookups = true);
    try {
      final detail = await _reimbursementService.getReimbursementDetail(request.id, "Modify");
      setState(() {
        _isEditing = true;
        _editId = request.id;
        
        if (detail['SDate'] != null && detail['SDate'] != "") {
           try {
             _selectedDate = DateFormat('dd-MM-yyyy').parse(detail['SDate']);
           } catch (_) {}
        }
        
        _selectedEDName = detail['EDName'];
        _amountController.text = detail['Amount']?.toString() ?? "";
        _maxAllowed = (detail['MaxAllowed'] is num) ? (detail['MaxAllowed'] as num).toDouble() : 0.0;
        _unlimited = detail['Unlimited']?.toString() ?? "false";
        
        _tabController.animateTo(0);
        _isLoadingLookups = false;
      });
    } catch (e) {
      setState(() => _isLoadingLookups = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load request for editing: $e')),
        );
      }
    }
  }

  Future<void> _deleteRequest(ReimbursementRequest request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this reimbursement request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    try {
      await _reimbursementService.submitReimbursementRequest(
        sDate: request.sDate,
        amount: request.amount,
        maxAllowed: 0,
        unlimited: "false",
        empName: "",
        edName: request.edName,
        actions: "Delete",
        editId: request.id,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reimbursement deleted successfully')));
        _fetchHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AuthService.memberName.isNotEmpty 
            ? 'Reimbursement - ${AuthService.memberName}' 
            : 'Reimbursement', 
          style: const TextStyle(color: Colors.white, fontSize: 18)
        ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppStyles.modernCardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('New Reimbursement Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    _buildDatePickerField('Expense Date', _selectedDate, (date) => setState(() => _selectedDate = date)),
                    const SizedBox(height: 15),
                    _buildDropdownField(
                      'Reimbursement Type', 
                      _edNames.map((e) => e['EDName']?.toString() ?? '').toList(), 
                      _selectedEDName, 
                      _onEDNameChanged
                    ),
                    if (_selectedEDName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _unlimited == "true" ? 'Limit: Unlimited' : 'Limit: Max $_maxAllowed',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                    const SizedBox(height: 15),
                    _buildTextField('Amount', 'Enter amount', _amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                    const SizedBox(height: 15),
                    const Text('Attachment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickFile,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_file, size: 20, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _selectedFile == null ? 'Select file/receipt' : _selectedFile!.path.split('/').last,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: _selectedFile == null ? Colors.grey : Colors.black),
                              ),
                            ),
                            if (_selectedFile != null)
                              IconButton(
                                icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                onPressed: () => setState(() => _selectedFile = null),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isSubmitting 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(_isEditing ? 'Update Request' : 'Submit Request', style: const TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                              _editId = null;
                              _amountController.clear();
                              _selectedFile = null;
                              _selectedEDName = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Cancel Edit', style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (_isLoadingLookups)
            Positioned.fill(
              child: Container(
                color: Colors.white.withValues(alpha: 0.5),
                child: const Center(child: CircularProgressIndicator()),
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
                  const Text('Reimbursement History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    List<ReimbursementRequest> displayedItems = _filteredHistory.take(displayCount).toList();

    return Column(
      children: displayedItems.map((item) => _buildHistoryItem(item)).toList(),
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

  Widget _buildHistoryItem(ReimbursementRequest item) {
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
              _buildCardItem('TYPE', item.edName, flex: 2),
              _buildActions(item),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              _buildCardItem('DATE', item.sDate, flex: 1),
              _buildCardItem('AMOUNT', '₹${item.amount.toStringAsFixed(2)}', flex: 1, isHighlight: true),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildCardItem('STATUS', item.app, flex: 1, isHighlight: true),
              if (item.payDate.isNotEmpty && item.payDate != "-")
                _buildCardItem('PAID ON', item.payDate, flex: 1)
              else
                Expanded(flex: 1, child: SizedBox()),
            ],
          ),
          if (item.appBy.isNotEmpty && item.appBy != "-") ...[
            const SizedBox(height: 8),
            _buildCardItem('APP. BY', item.appBy, flex: 1),
          ],
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

  Widget _buildActions(ReimbursementRequest item) {
    bool canEdit = (item.app != 'Approved' && item.app != 'Rejected');
    
    if (!canEdit) {
      return const SizedBox.shrink(); // Return empty widget if no actions available
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
          onPressed: () => _editRequest(item),
          tooltip: 'Edit',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
          onPressed: () => _deleteRequest(item),
          tooltip: 'Delete',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
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
              firstDate: DateTime.now().subtract(const Duration(days: 180)),
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
              hint: const Text('Select reimbursement type'),
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
