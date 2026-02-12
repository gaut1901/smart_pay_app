import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/ui_constants.dart';
import '../../data/services/permission_service.dart';

class PermissionRequestScreen extends StatefulWidget {
  const PermissionRequestScreen({super.key});

  @override
  State<PermissionRequestScreen> createState() => _PermissionRequestScreenState();
}

class _PermissionRequestScreenState extends State<PermissionRequestScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PermissionService _permissionService = PermissionService();
  
  List<dynamic> _history = [];
  bool _isLoadingHistory = true;
  String? _historyError;
  bool _isLoadingLookup = true;

  // Form fields
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'PERMISSION';
  String _selectedSession = 'MORNING';
  final TextEditingController _minsController = TextEditingController(text: '0');
  final TextEditingController _remarksController = TextEditingController();
  bool _isSubmitting = false;
  String? _empName;

  // Actions State
  String _currentAction = 'Create'; // Create, Modify, Revise, View, Delete, Cancel
  String? _editId;
  Map<String, dynamic>? _editDetails;

  // Table & Search State
  final TextEditingController _searchController = TextEditingController();
  int _rowsPerPage = 10;
  int _currentPage = 0;
  List<dynamic> _filteredHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _fetchLookup();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredHistory = _history;
      } else {
        _filteredHistory = _history.where((request) => 
          (request['TicketNo']?.toString().toLowerCase().contains(_searchController.text.toLowerCase()) ?? false) ||
          (request['EmpName']?.toString().toLowerCase().contains(_searchController.text.toLowerCase()) ?? false)
        ).toList();
      }
      _currentPage = 0;
    });
  }

  void _resetForm() {
    setState(() {
      _currentAction = 'Create';
      _editId = null;
      _editDetails = null;
      _selectedDate = DateTime.now();
      _selectedType = 'PERMISSION';
      _selectedSession = 'MORNING';
      _minsController.text = '0';
      _remarksController.clear();
    });
    _fetchLookup(); // Re-fetch to get default date/mins if any
  }

  void _loadData() {
    _fetchHistory();
  }

  Future<void> _fetchLookup() async {
    setState(() => _isLoadingLookup = true);
    try {
      final lookup = await _permissionService.getPermissionLookup();
      setState(() {
        if (lookup['SDate'] != null && lookup['SDate'] != "") {
          try {
            _selectedDate = DateFormat('dd-MM-yyyy').parse(lookup['SDate']);
          } catch (_) {}
        }
        if (lookup['PType'] != null) _selectedType = lookup['PType'];
        if (lookup['Session'] != null) _selectedSession = lookup['Session'];
        if (lookup['PerMins'] != null) _minsController.text = lookup['PerMins'].toString();
        _empName = lookup['EmpName'];
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
      final history = await _permissionService.getPermissionHistory();
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

  Future<void> _submitRequest() async {
    if (_minsController.text.trim().isEmpty || _minsController.text == '0') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter permission minutes')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dateFormat = DateFormat('dd-MM-yyyy');
      final postData = {
        "SDate": dateFormat.format(_selectedDate),
        "PType": _selectedType,
        "Session": _selectedSession,
        "Remarks": _remarksController.text.trim(),
        "PerMins": int.tryParse(_minsController.text) ?? 0,
        "EmpName": _empName ?? "",
        "Actions": _currentAction,
        "EditId": _editId ?? "",
        "App": _currentAction == 'Create' ? '-' : (_editDetails?['App'] ?? '-'),
        "App1": _currentAction == 'Create' ? '-' : (_editDetails?['App1'] ?? '-'),
        
        // Include old values for update tracking as per legacy ngEmpPermission.js
        "oldSDate": _editDetails?['oldSDate'] ?? _editDetails?['SDate'] ?? "",
        "oldPType": _editDetails?['oldPType'] ?? _editDetails?['PType'] ?? "",
        "oldSession": _editDetails?['oldSession'] ?? _editDetails?['Session'] ?? "",
        "oldRemarks": _editDetails?['oldRemarks'] ?? _editDetails?['Remarks'] ?? "",
        "oldPerMins": _editDetails?['oldPerMins'] ?? _editDetails?['PMin'] ?? 0,
      };

      await _permissionService.submitPermissionRequest(postData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permission request ${_currentAction == 'Create' ? 'submitted' : 'updated'} successfully')),
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

  void _handleAction(dynamic item, String action) async {
    if (action == 'View') {
      _showViewDialog(item);
    } else if (action == 'Modify' || action == 'Revise') {
      _loadEditData(item, action);
    } else if (action == 'Delete' || action == 'Cancel') {
      _confirmDelete(item, action);
    }
  }

  Future<void> _loadEditData(dynamic item, String action) async {
    setState(() => _isLoadingHistory = true);
    try {
      final details = await _permissionService.getPermissionDetails(item['id'].toString(), action);
      setState(() {
        _currentAction = action;
        _editId = item['id'].toString();
        _editDetails = details;
        
        // Populate form
        try {
          _selectedDate = DateFormat('dd-MM-yyyy').parse(details['SDate']);
        } catch (_) {}
        
        _selectedType = details['PType'] ?? 'PERMISSION';
        _selectedSession = details['Session'] ?? 'MORNING';
        _minsController.text = (details['PerMins'] ?? 0).toString();
        _remarksController.text = details['Remarks'] ?? '';
        
        _isLoadingHistory = false;
        _tabController.animateTo(0); // Switch to Apply tab
      });
    } catch (e) {
      setState(() => _isLoadingHistory = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading details: $e')));
    }
  }

  void _showViewDialog(dynamic item) async {
    UIConstants.showViewModal(
      context: context,
      title: 'Permission Request Details',
      body: FutureBuilder<Map<String, dynamic>>(
        future: _permissionService.getPermissionDetails(item['id'].toString(), 'View'),
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
                UIConstants.buildDetailItem('Type', d['PType'] ?? ''),
                UIConstants.buildDetailItem('Session', d['Session'] ?? ''),
                UIConstants.buildDetailItem('Minutes', (d['PerMins'] ?? 0).toString()),
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



  void _confirmDelete(dynamic item, String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action Request'),
        content: Text('Are you sure you want to $action this permission request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoadingHistory = true);
              try {
                final dateFormat = DateFormat('dd-MM-yyyy');
                // Fetch details first to get necessary fields and old values
                final details = await _permissionService.getPermissionDetails(item['id'].toString(), 'Delete');
                
                final postData = {
                  "SDate": details['SDate'],
                  "PType": details['PType'],
                  "Session": details['Session'],
                  "Remarks": details['Remarks'] ?? "",
                  "PerMins": details['PerMins'] ?? 0,
                  "EmpName": details['EmpName'] ?? "",
                  "Actions": action,
                  "EditId": item['id'].toString(),
                  "App": details['App'] ?? "-",
                  "App1": details['App1'] ?? "-",
                  
                  // Include old values as they might be checked
                  "oldSDate": details['SDate'], // For delete, old is same as current
                  "oldPType": details['PType'],
                  "oldSession": details['Session'],
                  "oldRemarks": details['Remarks'] ?? "",
                  "oldPerMins": details['PerMins'] ?? 0,
                };
                await _permissionService.submitPermissionRequest(postData);
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
    _minsController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Permission Request', style: TextStyle(color: Colors.white, fontSize: 18)),
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
                      _currentAction == 'Create' ? 'New Permission Request' : 'Update Permission Request', 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                const SizedBox(height: 20),
                _buildDatePickerField('Date', _selectedDate, (date) => setState(() => _selectedDate = date)),
                const SizedBox(height: 15),
                _buildDropdownField('Type', ['PERMISSION', 'ONDUTY'], _selectedType, (val) => setState(() => _selectedType = val!)),
                const SizedBox(height: 15),
                _buildDropdownField('Session', ['MORNING', 'EVENING'], _selectedSession, (val) => setState(() => _selectedSession = val!)),
                const SizedBox(height: 15),
                _buildTextField('Minutes', 'Enter minutes', _minsController, keyboardType: TextInputType.number),
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
                child: Text('Permission History', 
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
                        headingRowColor: WidgetStateProperty.all(UIConstants.tableHeaderBg),
                        columns: [
                          DataColumn(label: Text('TICKET NO', style: UIConstants.tableHeaderStyle)),
                          DataColumn(label: Text('EMP NAME', style: UIConstants.tableHeaderStyle)),
                          DataColumn(label: Text('DATE', style: UIConstants.tableHeaderStyle)),
                          DataColumn(label: Text('TYPE', style: UIConstants.tableHeaderStyle)),
                          DataColumn(label: Text('SESSION', style: UIConstants.tableHeaderStyle)),
                          DataColumn(label: Text('MINS', style: UIConstants.tableHeaderStyle)),
                          DataColumn(label: Text('STATUS', style: UIConstants.tableHeaderStyle)),
                          DataColumn(label: Text('APP.BY', style: UIConstants.tableHeaderStyle)),
                          DataColumn(label: Text('ACTIONS', style: UIConstants.tableHeaderStyle)),
                        ],
                        rows: _filteredHistory.map((item) {
                          return DataRow(cells: [
                            DataCell(Text(item['TicketNo'] ?? '')),
                            DataCell(Text(item['EmpName'] ?? '')),
                            DataCell(Text(item['SDate'] ?? '')),
                            DataCell(Text(item['PType'] ?? '')),
                            DataCell(Text(item['Session'] ?? '')),
                            DataCell(Text((item['PMin'] ?? 0).toString())),
                            DataCell(Text(item['App'] ?? '')),
                            DataCell(Text(item['AppBy'] ?? '')),
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

  Widget _buildActions(dynamic item) {
    bool canEdit = (item['App'] == "-" || item['App'] == "Pending");
    
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
              hintText: 'Search by Ticket No or Name',
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

  Widget _buildHistoryItem(dynamic item) {
    final status = item['App'] ?? '-';
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
                Text(item['SDate'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${item['PType']} - ${item['Session']}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
            Text('${item['PMin']} Minutes', style: TextStyle(color: Colors.grey.shade700)),
            if (item['Remarks'] != null && item['Remarks'].isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Remarks: ${item['Remarks']}', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
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
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
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

  Widget _buildDropdownField(String label, List<String> items, String value, Function(String?) onChanged) {
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
}
