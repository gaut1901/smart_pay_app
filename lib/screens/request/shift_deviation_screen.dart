import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/ui_constants.dart';
import '../../data/services/shift_deviation_service.dart';

class ShiftDeviationScreen extends StatefulWidget {
  const ShiftDeviationScreen({super.key});

  @override
  State<ShiftDeviationScreen> createState() => _ShiftDeviationScreenState();
}

class _ShiftDeviationScreenState extends State<ShiftDeviationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ShiftDeviationService _shiftDevService = ShiftDeviationService();
  
  List<ShiftDeviationRequest> _history = [];
  bool _isLoadingHistory = true;
  String? _historyError;

  // Form data
  List<String> _groupNames = [];
  List<String> _shiftNames = [];
  List<Map<String, dynamic>> _allEmployees = [];
  bool _isLoadingLookups = true;

  // Form fields
  DateTime _deviationDate = DateTime.now();
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  String? _selectedGroup;
  String? _selectedShift;
  List<String> _selectedEmployees = [];
  bool _isSubmitting = false;

  // Actions State
  String _currentAction = 'Create'; // Create, Modify, Revise, Delete, Cancel
  String? _editId;
  Map<String, dynamic>? _editDetails;

  // Table & Search State
  final TextEditingController _searchController = TextEditingController();
  int _rowsPerPage = 10;
  List<ShiftDeviationRequest> _filteredHistory = [];

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
          (request.devNo.toLowerCase().contains(_searchController.text.toLowerCase())) ||
          (request.groupName.toLowerCase().contains(_searchController.text.toLowerCase())) ||
          (request.shiftName.toLowerCase().contains(_searchController.text.toLowerCase()))
        ).toList();
      }
    });
  }

  void _resetForm() {
    setState(() {
      _currentAction = 'Create';
      _editId = null;
      _editDetails = null;
      _deviationDate = DateTime.now();
      _fromDate = DateTime.now();
      _toDate = DateTime.now();
      _selectedGroup = null;
      _selectedShift = null;
      _selectedEmployees = [];
    });
    _fetchLookups();
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
      final history = await _shiftDevService.getShiftDeviationHistory();
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
      final lookupData = await _shiftDevService.getShiftDeviationLookup(action: _currentAction);
      
      if (lookupData['FDate'] != null && lookupData['FDate'] != "") {
         try {
           _fromDate = DateFormat('dd-MM-yyyy').parse(lookupData['FDate']);
         } catch (_) {}
      }
      if (lookupData['TDate'] != null && lookupData['TDate'] != "") {
         try {
           _toDate = DateFormat('dd-MM-yyyy').parse(lookupData['TDate']);
         } catch (_) {}
      }

      setState(() {
        _groupNames = List<String>.from((lookupData['dtGroup'] as List?)?.map((e) => e['GroupName']?.toString() ?? '') ?? []);
        _shiftNames = List<String>.from((lookupData['dtShift'] as List?)?.map((e) => e['ShiftName']?.toString() ?? '') ?? []);
        _allEmployees = List<Map<String, dynamic>>.from(lookupData['dtEmp'] ?? []);
        _isLoadingLookups = false;
      });
    } catch (e) {
      if (mounted) {
        UIConstants.showErrorSnackBar(context, 'Failed to load lookups: $e');
      }
      setState(() => _isLoadingLookups = false);
    }
  }

  Future<void> _updateGroups() async {
    try {
      final dateFormat = DateFormat('dd-MM-yyyy');
      final groups = await _shiftDevService.getGroupNames(dateFormat.format(_fromDate), dateFormat.format(_toDate));
      setState(() {
        _groupNames = groups;
      });
    } catch (e) {
      debugPrint('Error updating groups: $e');
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedGroup == null || _selectedShift == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Group and Shift')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dateFormat = DateFormat('dd-MM-yyyy');
      final Map<String, dynamic> postData = {
        "SDate": dateFormat.format(_deviationDate),
        "GroupName": _selectedGroup,
        "DShiftName": _selectedShift,
        "StartDate": dateFormat.format(_fromDate),
        "EndDate": dateFormat.format(_toDate),
        "EmpNames": _selectedEmployees,
        "App": _editDetails?['App'] ?? "-",
        "Actions": _currentAction,
        "EditId": _editId ?? "",
      };

      await _shiftDevService.submitShiftDeviation(postData);
      
      if (mounted) {
        UIConstants.showSuccessSnackBar(
          context, 
          'Shift deviation ${_currentAction == 'Create' ? 'submitted' : 'updated'} successfully'
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

  void _handleAction(ShiftDeviationRequest item, String action) async {
    if (action == 'View') {
      _showViewDialog(item);
    } else if (action == 'Modify' || action == 'Revise') {
      _loadEditData(item, action);
    } else if (action == 'Delete' || action == 'Cancel') {
      _confirmDelete(item, action);
    }
  }

  Future<void> _loadEditData(ShiftDeviationRequest item, String action) async {
    setState(() => _isLoadingHistory = true);
    try {
      final details = await _shiftDevService.getShiftDeviationDetails(item.id, action);
      setState(() {
        _currentAction = action;
        _editId = item.id;
        _editDetails = details;
        
        try {
          _deviationDate = DateFormat('dd-MM-yyyy').parse(details['SDate']);
          _fromDate = DateFormat('dd-MM-yyyy').parse(details['StartDate']);
          _toDate = DateFormat('dd-MM-yyyy').parse(details['EndDate']);
        } catch (_) {}
        
        _selectedGroup = details['GroupName'];
        _selectedShift = details['DShiftName'];
        
        final empNamesData = details['EmpNames'];
        if (empNamesData is List) {
          _selectedEmployees = List<String>.from(empNamesData.map((e) => e.toString()));
        } else {
          _selectedEmployees = (empNamesData?.toString() ?? '').split(',').where((e) => e.isNotEmpty).toList();
        }
        
        // Populate dropdowns from details if present
        if (details['dtGroup'] != null) {
          _groupNames = List<String>.from((details['dtGroup'] as List).map((e) => e['GroupName']?.toString() ?? ''));
        }
        if (details['dtShift'] != null) {
          _shiftNames = List<String>.from((details['dtShift'] as List).map((e) => e['ShiftName']?.toString() ?? ''));
        }

        _isLoadingHistory = false;
        _tabController.animateTo(0);
      });
    } catch (e) {
      setState(() => _isLoadingHistory = false);
      if (mounted) {
        UIConstants.showErrorSnackBar(context, 'Error loading details: $e');
      }
    }
  }

  void _showViewDialog(ShiftDeviationRequest item) async {
    UIConstants.showViewModal(
      context: context,
      title: 'Shift Deviation Details',
      body: FutureBuilder<Map<String, dynamic>>(
        future: _shiftDevService.getShiftDeviationDetails(item.id, 'View'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) {
            return Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red))));
          }
          final d = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                UIConstants.buildDetailItem('Dev No', (d['DevNo'] ?? d['devNo'] ?? '').toString()),
                UIConstants.buildDetailItem('Deviation Date', (d['SDate'] ?? d['sDate'] ?? '').toString()),
                UIConstants.buildDetailItem('Start Date', (d['StartDate'] ?? d['startDate'] ?? '').toString()),
                UIConstants.buildDetailItem('End Date', (d['EndDate'] ?? d['endDate'] ?? '').toString()),
                UIConstants.buildDetailItem('Group', (d['GroupName'] ?? d['groupName'] ?? '').toString()),
                UIConstants.buildDetailItem('Deviated Shift', (d['DShiftName'] ?? d['shiftName'] ?? '').toString()),
                UIConstants.buildDetailItem('Employees', d['EmpNames'] is List ? (d['EmpNames'] as List).join(', ') : (d['EmpNames']?.toString() ?? '')),
                UIConstants.buildDetailItem('Status', (d['App'] ?? '').toString()),
                UIConstants.buildDetailItem('Approved By', (d['AppBy'] ?? '').toString()),
                UIConstants.buildDetailItem('Approved On', (d['AppOn'] ?? d['On'] ?? '').toString()),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(ShiftDeviationRequest item, String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action Request'),
        content: Text('Are you sure you want to $action this shift deviation?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoadingHistory = true);
              try {
                final details = await _shiftDevService.getShiftDeviationDetails(item.id, action);
                // Build postData from scratch to match Angular backend
                final Map<String, dynamic> postData = {
                  "SDate": details['SDate'],
                  "GroupName": details['GroupName'],
                  "DShiftName": details['DShiftName'],
                  "StartDate": details['StartDate'],
                  "EndDate": details['EndDate'],
                  "EmpNames": details['EmpNames'],
                  "App": details['App'] ?? "-",
                  "Actions": action,
                  "EditId": item.id,
                };
                
                await _shiftDevService.submitShiftDeviation(postData);
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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shift Deviation', style: TextStyle(color: Colors.white, fontSize: 18)),
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
                  _currentAction == 'Create' ? 'New Shift Deviation Request' : 'Update Shift Deviation', 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 20),
                _buildDatePickerField('Deviation Date', _deviationDate, (date) {
                  setState(() => _deviationDate = date);
                }),
                const SizedBox(height: 15),
                _buildDatePickerField('Start Date', _fromDate, (date) {
                  setState(() => _fromDate = date);
                  _updateGroups();
                }),
                const SizedBox(height: 15),
                _buildDatePickerField('End Date', _toDate, (date) {
                  setState(() => _toDate = date);
                  _updateGroups();
                }),
                const SizedBox(height: 15),
                _buildDropdownField(
                  'Group Name', 
                  _groupNames, 
                  _selectedGroup, 
                  (val) => setState(() => _selectedGroup = val)
                ),
                const SizedBox(height: 15),
                _buildDropdownField(
                  'Shift Name', 
                  _shiftNames, 
                  _selectedShift, 
                  (val) => setState(() => _selectedShift = val)
                ),
                const SizedBox(height: 15),
                _buildMultiSelectEmployees(),
                const SizedBox(height: 30),
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
                child: Text('Shift Deviation History', 
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
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
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
                          DataColumn(label: Text('DEV NO', style: UIConstants.tableHeaderStyle)),
                          DataColumn(label: Text('REQ DATE', style: UIConstants.tableHeaderStyle)),
                          DataColumn(label: Text('FROM DATE', style: UIConstants.tableHeaderStyle)),
                          DataColumn(label: Text('TO DATE', style: UIConstants.tableHeaderStyle)),
                          DataColumn(label: Text('GROUP', style: UIConstants.tableHeaderStyle)),
                          DataColumn(label: Text('SHIFT', style: UIConstants.tableHeaderStyle)),
                          DataColumn(label: Text('STATUS', style: UIConstants.tableHeaderStyle)),
                          DataColumn(label: Text('ACTIONS', style: UIConstants.tableHeaderStyle)),
                        ],
                        rows: _filteredHistory.map((item) {
                          return DataRow(cells: [
                            DataCell(Text(item.devNo)),
                            DataCell(Text(item.sDate)),
                            DataCell(Text(item.startDate)),
                            DataCell(Text(item.endDate)),
                            DataCell(Text(item.groupName)),
                            DataCell(Text(item.shiftName)),
                            DataCell(Text(item.app)),
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

  Widget _buildActions(ShiftDeviationRequest item) {
    bool canEdit = (item.app == "-" || item.app == "Pending");
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
              hintText: 'Search by Dev No, Group or Shift',
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
              value: (value != null && items.contains(value)) ? value : null,
              hint: const Text('Select option'),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String placeholder, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiSelectEmployees() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Employees', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) {
                return StatefulBuilder(
                  builder: (context, setDialogState) {
                    return AlertDialog(
                      title: const Text('Select Employees'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _allEmployees.length,
                          itemBuilder: (context, index) {
                            final emp = _allEmployees[index];
                            final name = emp['EmpName']?.toString() ?? '';
                            final isSelected = _selectedEmployees.contains(name);
                            return CheckboxListTile(
                              title: Text(name, style: const TextStyle(fontSize: 14)),
                              value: isSelected,
                              onChanged: (val) {
                                setDialogState(() {
                                  if (val == true) {
                                    _selectedEmployees.add(name);
                                  } else {
                                    _selectedEmployees.remove(name);
                                  }
                                });
                                setState(() {});
                              },
                            );
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedEmployees.isEmpty ? 'Select employees' : _selectedEmployees.join(', '),
                    style: TextStyle(
                      fontSize: 14,
                      color: _selectedEmployees.isEmpty ? Colors.grey : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.person_add, size: 18, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
