import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/ui_constants.dart';
import '../../data/models/leave_model.dart';
import '../../data/services/leave_service.dart';
import 'package:intl/intl.dart';

import 'package:file_picker/file_picker.dart';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LeaveService _leaveService = LeaveService();
  
  List<LeaveRequest> _history = [];
  List<LeaveBalance> _balances = []; // For Apply Leave (Current)
  List<LeaveBalance> _periodBalances = []; // For Leave Balance Tab (Search)
  List<dynamic> _balanceDetails = []; // For the detailed card view (dt)
  List<dynamic> _statusDetails = []; // For the status/days card view (dt1)
  bool _isLoadingHistory = true;
  bool _isLoadingBalance = true;
  bool _isLoadingPeriodBalance = false;
  bool _isLoadingDetails = false;
  String? _historyError;
  String? _balanceError;


  // New Design State
  String? _selectedPeriod;
  DateTime _periodStartDate = DateTime(DateTime.now().year, 1, 1);
  DateTime _periodEndDate = DateTime(DateTime.now().year, 12, 31);
  List<String> _periodOptions = [];


  // Form fields
  String? _selectedLeaveType;
  String? _selectedLeaveReason;
  String _selectedFromPortion = 'Full Day';
  String _selectedToPortion = 'Full Day';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  final TextEditingController _remarksController = TextEditingController();
  bool _isSubmitting = false;

  Map<String, dynamic>? _lookupData;
  bool _isLoadingLookup = true;
  bool _mcReq = false;
  String? _mcFilePath;
  PlatformFile? _selectedFile;
  bool _isUploadingFile = false;

  // Actions State
  String _currentAction = 'Create'; // Create, Modify, Revise, View
  String? _editId;
  Map<String, dynamic>? _editDetails;

  // Search
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _historySearchController = TextEditingController();
  List<LeaveBalance> _filteredBalances = [];
  List<LeaveRequest> _filteredHistory = [];
  int _rowsPerPage = 10;
  final List<int> _rowsPerPageOptions = [10, 25, 50, 100];
  List<String> _leaveHeaders = [];
  bool _isLoadingHeaders = true;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // _generatePeriodOptions(); // Removed static generation
    _loadData();
    _fetchLookup();
    _searchController.addListener(_onSearchChanged);
    _historySearchController.addListener(_onHistorySearchChanged);
  }


  void _generatePeriodOptions() {
    final currentYear = DateTime.now().year;
    final nextYear = currentYear + 1;
    final leaveTypes = ['CL', 'EL', 'SL', 'CO', 'Special Leave', 'Optional Leave']; // Common types
    
    List<String> options = [];
    for (var year in [currentYear, nextYear]) {
      for (var type in leaveTypes) {
        options.add('$type (01-01-$year - 31-12-$year)');
      }
    }
    _periodOptions = options;
  }


  void _onSearchChanged() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredBalances = _balances;
      } else {
        _filteredBalances = _balances.where((balance) => 
          balance.leaveType.toLowerCase().contains(_searchController.text.toLowerCase())
        ).toList();
      }
    });
  }

  void _onHistorySearchChanged() {
    _filterHistory();
  }

  void _filterHistory() {
    setState(() {
      if (_historySearchController.text.isEmpty) {
        _filteredHistory = List.from(_history);
      } else {
        final query = _historySearchController.text.toLowerCase();
        _filteredHistory = _history.where((item) => 
          item.empName.toLowerCase().contains(query) ||
          item.ticketNo.toLowerCase().contains(query) ||
          item.status.toLowerCase().contains(query) ||
          item.remarks.toLowerCase().contains(query)
        ).toList();
      }
    });
  }



  Future<void> _loadData() async {
    setState(() {
      _isLoadingHistory = true;
      _isLoadingBalance = true;
      _isLoadingPeriodBalance = true;
      _isLoadingDetails = true;
    });

    // We MUST fetch headers first to set the default period and dates
    await _fetchHeaders();
    
    // Now fetch others
    await Future.wait([
      _fetchHistory(),
      _fetchBalance(),
      _fetchPeriodBalance(),
    ]);
  }


  Future<void> _fetchLookup() async {
    setState(() => _isLoadingLookup = true);
    try {
      final lookup = await _leaveService.getLeaveLookup();
      setState(() {
        _lookupData = lookup;
        final dtStatus = lookup['dtStatus'] as List?;
        if (dtStatus != null && dtStatus.isNotEmpty) {
          _selectedLeaveType = dtStatus[0]['Status'];
        }
        final dtLR = lookup['dtLR'] as List?;
        if (dtLR != null && dtLR.isNotEmpty) {
          _selectedLeaveReason = dtLR[0]['LRName'];
        }
        _isLoadingLookup = false;
      });
      _onStatusChange();
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
      final history = await _leaveService.getLeaveHistory();
      setState(() {
        _history = history;
        _filterHistory(); // Initial filter
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() {
        _historyError = e.toString().replaceAll('Exception: ', '');
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _fetchBalance() async {
    setState(() {
      _isLoadingBalance = true;
      _balanceError = null;
    });
    try {
      // Restore: Always fetch current balance for "Apply Leave" tab
      final balances = await _leaveService.getLeaveBalance();
      setState(() {
        _balances = balances;
        _isLoadingBalance = false;
      });
    } catch (e) {
      setState(() {
        _balanceError = e.toString().replaceAll('Exception: ', '');
        _isLoadingBalance = false;
      });
    }
  }

  Future<void> _fetchHeaders() async {
    setState(() => _isLoadingHeaders = true);
    try {
      final headers = await _leaveService.getEmployeeLeaveHeaders();
      setState(() {
        _leaveHeaders = headers;
        // Prepend default option
        _periodOptions = ['Select Leave Period', ...headers];
        
        if (_selectedPeriod == null) {
          _selectedPeriod = 'Select Leave Period';
        }
        _isLoadingHeaders = false;
      });
    } catch (e) {
      setState(() => _isLoadingHeaders = false);
      debugPrint('Error fetching headers: $e');
    }
  }

  void _parseSelectedPeriod(String val) {
    if (val == 'Select Leave Period') return;
    try {
      final parts = val.split('(');
      if (parts.length > 1) {
        final datePart = parts[1].replaceAll(')', '');
        final dates = datePart.split(' - ');
        if (dates.length == 2) {
          _periodStartDate = DateFormat('dd-MM-yyyy').parse(dates[0]);
          _periodEndDate = DateFormat('dd-MM-yyyy').parse(dates[1]);
        }
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }
  }

  Future<void> _fetchPeriodBalance() async {
    setState(() {
      _isLoadingPeriodBalance = true;
      _isLoadingDetails = true;
    });
    try {
      final dateFormatDisp = DateFormat('dd-MM-yyyy');

      // 1. Fetch summary balance (Opening, Credit, Taken, etc.)
      final balances = await _leaveService.getLeaveBalance(date: _periodStartDate);
      
      // 2. Fetch detailed balance and status summary (dt and dt1)
      List<dynamic> details = [];
      List<dynamic> status = [];
      if (_selectedPeriod != null && _selectedPeriod != 'Select Leave Period') {
        final result = await _leaveService.getLeaveBalanceDetails(
          fDate: dateFormatDisp.format(_periodStartDate),
          tDate: dateFormatDisp.format(_periodEndDate),
          salaryName: _selectedPeriod!,
        );
        details = result['dt'] ?? [];
        status = result['dt1'] ?? [];
      }

      setState(() {
        _periodBalances = balances;
        _balanceDetails = details;
        _statusDetails = status;
        _isLoadingPeriodBalance = false;
        _isLoadingDetails = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPeriodBalance = false;
        _isLoadingDetails = false;
      });
      debugPrint('Error fetching period balance: $e');
    }
  }

  Future<void> _selectPeriodDate(bool isStart) async {
    final initialDate = isStart ? _periodStartDate : _periodEndDate;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _periodStartDate = date;
        } else {
          _periodEndDate = date;
        }
      });
    }
  }

  Future<void> _onStatusChange() async {
    if (_selectedLeaveType == null) return;

    try {
      final dateFormat = DateFormat('yyyy-MM-dd');
      final result = await _leaveService.statusChange(
        fDate: dateFormat.format(_startDate),
        tDate: dateFormat.format(_endDate),
        fText: _selectedFromPortion,
        tText: _selectedToPortion,
        status: _selectedLeaveType!,
      );

      setState(() {
        _mcReq = result['MCReq'] ?? false;
        // Handle TableText or other fields if necessary
      });
    } catch (e) {
      debugPrint('Error in statusChange: $e');
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
        _mcFilePath = null; // Reset uploaded path when new file is picked
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;

    setState(() => _isUploadingFile = true);
    try {
      final bytes = _selectedFile!.bytes ?? await _readFileBytes(_selectedFile!);
      final filePath = await _leaveService.uploadMedicalCertificate(_selectedFile!.name, bytes);
      setState(() {
        _mcFilePath = filePath;
        _isUploadingFile = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully')),
        );
      }
    } catch (e) {
      setState(() => _isUploadingFile = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  Future<List<int>> _readFileBytes(PlatformFile file) async {
    // In mobile/desktop, we might need to read from path if bytes are null
    if (file.bytes != null) return file.bytes!;
    // This is a placeholder for actual file reading if needed
    // For now, assuming bytes are available (common in Web/some pickers)
    // On mobile, you might need: return await File(file.path!).readAsBytes();
    throw Exception('File bytes not available');
  }

  Future<void> _submitLeave() async {
    if (_selectedLeaveType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select leave type')));
      return;
    }
    if (_selectedLeaveReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select leave reason')));
      return;
    }
    if (_remarksController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter remarks')));
      return;
    }

    if (_mcReq && (_mcFilePath == null || _mcFilePath!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload Medical Certificate')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dateFormat = DateFormat('yyyy-MM-dd');
      await _leaveService.submitLeaveRequest(
        sDate: dateFormat.format(DateTime.now()),
        fDate: dateFormat.format(_startDate),
        tDate: dateFormat.format(_endDate),
        remarks: _remarksController.text.trim(),
        status: _selectedLeaveType!, 
        lrName: _selectedLeaveReason!,
        fText: _selectedFromPortion,
        tText: _selectedToPortion,
        days: _calculateDays(),
        filePath: _mcFilePath ?? "",
        mcReq: _mcReq,
        actions: _currentAction,
        editId: _editId ?? '',
        revise: _currentAction == 'Revise',
        oldDetails: _editDetails,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Leave request ${_currentAction == 'Create' ? 'submitted' : 'updated'} successfully')),
        );
        _resetForm();
        await _loadData();
        _tabController.animateTo(2); // Back to History
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

  double _calculateDays() {
    double total = _endDate.difference(_startDate).inDays + 1.0;
    if (_startDate == _endDate) {
      if (_selectedFromPortion != 'Full Day') return 0.5;
    } else {
      if (_selectedFromPortion != 'Full Day') total -= 0.5;
      if (_selectedToPortion != 'Full Day') total -= 0.5;
    }
    return total;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _remarksController.dispose();
    _searchController.dispose();
    _historySearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Leave Management', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Leave Balance'),
            Tab(text: 'Apply Leave'),
            Tab(text: 'Leave History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaveBalanceTab(),
          _buildApplyLeaveTab(),
          _buildLeaveHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildApplyLeaveTab() {
    return RefreshIndicator(
      onRefresh: () async => _fetchBalance(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeaveBalanceSummary(),
            const SizedBox(height: 20),
            _buildLeaveApplicationForm(),
          ],
        ),
      ),
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

  Widget _buildLeaveApplicationForm() {
    if (_isLoadingLookup) {
      return const Center(child: CircularProgressIndicator());
    }

    final dtStatus = (_lookupData?['dtStatus'] as List?)?.map((e) => e['Status'].toString()).toList() ?? [];
    final dtLR = (_lookupData?['dtLR'] as List?)?.map((e) => e['LRName'].toString()).toList() ?? [];
    final dtText = (_lookupData?['dtText'] as List?)?.map((e) => e['Text1'].toString()).toList() ?? ['Full Day', '1st Half', '2nd Half'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.modernCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Apply for Leave', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildDropdownField('Leave Type', dtStatus, _selectedLeaveType, (val) {
            setState(() => _selectedLeaveType = val);
            _onStatusChange();
          }),
          const SizedBox(height: 15),
          _buildDropdownField('Leave Reason', dtLR, _selectedLeaveReason, (val) => setState(() => _selectedLeaveReason = val)),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDatePickerField('From Date', _startDate, (date) {
                      setState(() {
                        _startDate = date;
                        _endDate = date; // Match Angular behavior: onchange="$('#txtTDate').val(this.value); ..."
                      });
                      _onStatusChange();
                    }),
                    const SizedBox(height: 8),
                    _buildDropdownField('Portion', dtText, _selectedFromPortion, (val) {
                      setState(() => _selectedFromPortion = val!);
                      _onStatusChange();
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDatePickerField('To Date', _endDate, (date) {
                      setState(() => _endDate = date);
                      _onStatusChange();
                    }),
                    const SizedBox(height: 8),
                    _buildDropdownField('Portion', dtText, _selectedToPortion, (val) {
                      setState(() => _selectedToPortion = val!);
                      _onStatusChange();
                    }),
                  ],
                ),
              ),
            ],
          ),
          if (_mcReq) ...[
            const SizedBox(height: 20),
            const Text('Medical Certificate', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _selectedFile?.name ?? 'No file selected',
                      style: TextStyle(color: _selectedFile == null ? Colors.grey : Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _pickFile,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black87),
                  child: const Text('Pick'),
                ),
              ],
            ),
            if (_selectedFile != null && _mcFilePath == null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUploadingFile ? null : _uploadFile,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                  child: _isUploadingFile
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Upload Certificate', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
            if (_mcFilePath != null)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text('File uploaded successfully', style: TextStyle(color: Colors.green, fontSize: 12)),
              ),
          ],
          const SizedBox(height: 15),
          _buildTextField('Remarks', 'Enter remarks for leave', _remarksController, maxLines: 3),
          const SizedBox(height: 20),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitLeave,
                  style: _currentAction == 'Create' ? UIConstants.primaryButtonStyle : UIConstants.updateButtonStyle,
                  child: _isSubmitting 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_currentAction == 'Create' ? 'Submit Application' : 'Update Application', style: UIConstants.buttonTextStyle),
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
    );
  }

  void _resetForm() {
    setState(() {
      _currentAction = 'Create';
      _editId = null;
      _editDetails = null;
      _remarksController.clear();
      _mcFilePath = null;
      _selectedFile = null;
      _startDate = DateTime.now();
      _endDate = DateTime.now();
      // Reset dropdowns if lookup data is available
      if (_lookupData != null) {
        final dtStatus = _lookupData!['dtStatus'] as List?;
        if (dtStatus != null && dtStatus.isNotEmpty) {
          _selectedLeaveType = dtStatus[0]['Status'];
        }
        final dtLR = _lookupData!['dtLR'] as List?;
        if (dtLR != null && dtLR.isNotEmpty) {
          _selectedLeaveReason = dtLR[0]['LRName'];
        }
      }
    });
  }

  Widget _buildDropdownField(String label, List<String> items, String? value, Function(String?) onChanged) {
    // Ensure value is in items
    final selectedValue = items.contains(value) ? value : (items.isNotEmpty ? items[0] : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedValue,
              items: items.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
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
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) onSelect(date);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('dd-MM-yyyy').format(selectedDate), style: TextStyle(color: Colors.grey.shade800)),
                const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
              ],
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
          decoration: InputDecoration(
            hintText: placeholder,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_historyError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_historyError', style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _fetchHistory, child: const Text('Retry')),
          ],
        ),
      );
    }

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
                  const Text('Leave History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildTableActionsRow(),
                  const SizedBox(height: 16),
                  if (_filteredHistory.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No leave history found')))
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
    // Basic pagination
    int displayCount = _filteredHistory.length > _rowsPerPage ? _rowsPerPage : _filteredHistory.length;
    List<LeaveRequest> displayedItems = _filteredHistory.take(displayCount).toList();

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
              _buildCardItem('EMP NAME', item.empName, flex: 2),
              _buildActions(item),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              _buildCardItem('FROM DATE', item.fDate, flex: 1),
              _buildCardItem('TO DATE', item.tDate, flex: 1),
              _buildCardItem('STATUS', item.status, flex: 1, isHighlight: true),
            ],
          ),
          const SizedBox(height: 8),
          _buildCardItem('REASON', item.remarks, isFullWidth: true),
          if (item.app != "-") ...[
            const Divider(height: 16),
            Row(
              children: [
                _buildCardItem('APP. STATUS', item.app, flex: 1),
                _buildCardItem('APP. BY', item.appBy, flex: 1),
                _buildCardItem('APP. ON', item.appOn, flex: 1),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildActions(LeaveRequest item) {
    bool canEdit = !item.cancel;
    // Matching Angular logic: row.App=="-" ? 'Modify' : 'Revise'
    String editLabel = item.app == "-" ? "Modify" : "Revise";
    String deleteLabel = item.app == "-" ? "Delete" : "Cancel";

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UIConstants.buildViewButton(onPressed: () => _handleAction(item, 'View')),
        if (canEdit) ...[
          const SizedBox(width: 8),
          UIConstants.buildEditButton(
            onPressed: () => _handleAction(item, editLabel),
            tooltip: editLabel,
          ),
          const SizedBox(width: 8),
          UIConstants.buildDeleteButton(
            onPressed: () => _handleAction(item, deleteLabel),
            tooltip: deleteLabel,
          ),
        ],
      ],
    );
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
      final details = await _leaveService.getLeaveRequestDetails(item.id, action);
      setState(() {
        _currentAction = action;
        _editId = item.id;
        _editDetails = details;
        
        // Populate form
        try {
          final dateFormat = DateFormat('dd-MM-yyyy');
          _startDate = dateFormat.parse(details['FromDate']);
          _endDate = dateFormat.parse(details['ToDate']);
        } catch (e) {
          debugPrint('Date parsing error: $e');
        }
        
        _selectedLeaveType = details['Status'];
        _selectedLeaveReason = details['LRName'];
        _selectedFromPortion = details['FText'] ?? 'Full Day';
        _selectedToPortion = details['TText'] ?? 'Full Day';
        _remarksController.text = details['Remarks'] ?? '';
        _mcFilePath = details['FilePath'] == "-" ? null : details['FilePath'];
        _mcReq = details['MCReq'] ?? false;
        
        _isLoadingHistory = false;
        _tabController.animateTo(1); // Switch to Apply Leave tab
      });
    } catch (e) {
      setState(() => _isLoadingHistory = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading details: $e')));
    }
  }

  void _showViewDialog(LeaveRequest item) async {
    UIConstants.showViewModal(
      context: context,
      title: 'Leave Request Details',
      body: FutureBuilder<Map<String, dynamic>>(
        future: _leaveService.getLeaveRequestDetails(item.id, 'View'),
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
                UIConstants.buildDetailItem('Request Date', d['SDate'] ?? ''),
                UIConstants.buildDetailItem('From Date', d['FromDate'] ?? ''),
                UIConstants.buildDetailItem('To Date', d['ToDate'] ?? ''),
                UIConstants.buildDetailItem('Days', (d['Days'] ?? 0).toString()),
                UIConstants.buildDetailItem('Leave Type', d['Status'] ?? ''),
                UIConstants.buildDetailItem('Reason', d['LRName'] ?? ''),
                UIConstants.buildDetailItem('Remarks', d['Remarks'] ?? ''),
                UIConstants.buildDetailItem('Status', d['App'] ?? ''),
                UIConstants.buildDetailItem('Approved By', d['AppBy'] ?? ''),
                UIConstants.buildDetailItem('Approved Date', d['AppOn'] ?? ''),
                UIConstants.buildDetailItem('Approval Remarks', d['AppRemarks'] ?? ''),
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
        content: Text('Are you sure you want to $action this leave request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoadingHistory = true);
              try {
                // Fetch details first to get necessary fields and old values
                final details = await _leaveService.getLeaveRequestDetails(item.id, 'Delete');
                
                await _leaveService.submitLeaveRequest(
                  sDate: details['SDate'] ?? item.sDate,
                  fDate: details['FromDate'],
                  tDate: details['ToDate'],
                  remarks: details['Remarks'] ?? "",
                  status: details['Status'],
                  lrName: details['LRName'],
                  fText: details['FText'] ?? "Full Day",
                  tText: details['TText'] ?? "Full Day",
                  days: double.tryParse(details['Days'].toString()) ?? 0,
                  actions: action,
                  editId: item.id,
                  oldDetails: details,
                );
                await _loadData();
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
  Widget _buildLeaveBalanceTab() {
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppStyles.modernCardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Leave Balance Search', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  const Text('Select Leave Period', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey)),
                  const SizedBox(height: 8),
                  _buildPeriodDropdown(),
                  const SizedBox(height: 16),
                  _buildDateSearchRow(),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Summary Section
            if (_isLoadingPeriodBalance)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_periodBalances.isNotEmpty)
              _buildSummarySection()
            else if (_selectedPeriod != null)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No Data', style: TextStyle(color: Colors.grey)))),

            const SizedBox(height: 20),

            // Detailed Section
            if (_isLoadingDetails)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else ...[
              if (_balanceDetails.isNotEmpty || _statusDetails.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppStyles.modernCardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Leave Details', style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold, 
                      color: AppColors.textDark
                    )),
                    const SizedBox(height: 15),
                    const Divider(),
                    const SizedBox(height: 15),
                    
                    if (_balanceDetails.isNotEmpty) ...[
                      _buildBalanceCards(),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 20),
                    ] else
                      const Center(child: Padding(padding: EdgeInsets.all(10), child: Text('No Transaction Records', style: TextStyle(color: Colors.grey, fontSize: 12)))),

                    if (_statusDetails.isNotEmpty) ...[
                      const Text('Status Summary', style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.bold, 
                        color: AppColors.textDark
                      )),
                      const SizedBox(height: 15),
                      _buildStatusCards(),
                    ] else
                      const Center(child: Padding(padding: EdgeInsets.all(10), child: Text('No Status Summary Available', style: TextStyle(color: Colors.grey, fontSize: 12)))),
                  ],
                ),
              )
              else if (_selectedPeriod != null)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No Detailed Data', style: TextStyle(color: Colors.grey)))),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text('Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 130,
          ),
          itemCount: _periodBalances.length,
          itemBuilder: (context, index) {
            final b = _periodBalances[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: AppStyles.modernCardDecoration.copyWith(
                border: Border.all(color: AppColors.primary.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.leaveType, 
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryItem('Opening', b.yearOpen.toStringAsFixed(1)),
                      _buildSummaryItem('Credit', b.yearCredit.toStringAsFixed(1)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryItem('Taken', b.yearTaken.toStringAsFixed(1)),
                      _buildSummaryItem('Balance', b.yearBalance.toStringAsFixed(1), highlight: true),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: TextStyle(
          fontSize: 13, 
          fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
          color: highlight ? AppColors.accent : AppColors.textDark
        )),
      ],
    );
  }

  Widget _buildStatusCards() {
    return Column(
      children: _statusDetails.map((s) => _buildStatusCard(s)).toList(),
    );
  }

  Widget _buildStatusCard(dynamic status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(status['Status']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
          Text(status['days']?.toString() ?? '0', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildBalanceCards() {
    return Column(
      children: _balanceDetails.map((detail) => _buildDetailCard(detail)).toList(),
    );
  }

  Widget _buildDetailCard(dynamic detail) {
    if (detail == null || detail is! Map) {
      return const SizedBox.shrink();
    }
    final data = detail as Map<String, dynamic>;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCardItem('Date', (data['SDate1'] ?? data['fdate'] ?? data['Date'] ?? '-').toString(), flex: 2),
              _buildCardItem('Leave Taken', (data['DayValue'] ?? data['Taken'] ?? '0').toString(), flex: 1, isHighlight: true),
              _buildCardItem('Leave Credit', (data['CDayValue'] ?? data['Credit'] ?? '0').toString(), flex: 1, isHighlight: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(String label, String value, {int flex = 1, bool isHighlight = false, bool isFullWidth = false}) {
    final widget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(
          fontSize: 14, 
          fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
          color: isHighlight ? AppColors.primary : AppColors.textDark,
        )),
      ],
    );

    if (isFullWidth) return widget;
    return Expanded(flex: flex, child: widget);
  }

  Widget _buildPeriodDropdown() {
    return Container(
      width: double.infinity, 
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Text('Select Leave Period'),
          value: _selectedPeriod,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
          items: _periodOptions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedPeriod = val;
                _parseSelectedPeriod(val);
              });
              _fetchPeriodBalance();
            }
          },
        ),
      ),
    );
  }

  Widget _buildDateSearchRow() {
    return Row(
      children: [
        Expanded(child: _buildDateDisplay(_periodStartDate, () => _selectPeriodDate(true))),
        const SizedBox(width: 8),
        Expanded(child: _buildDateDisplay(_periodEndDate, () => _selectPeriodDate(false))),
        const SizedBox(width: 8),
        _buildSearchButton(),
      ],
    );
  }

  Widget _buildDateDisplay(DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: Color(0xFFB8860B), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(DateFormat('dd-MM-yyyy').format(date), 
                style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return SizedBox(
      height: 42,
      width: 42,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDE3C4B),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
        onPressed: _fetchPeriodBalance,
        child: const Icon(Icons.search, color: Colors.white, size: 22),
      ),
    );
  }





  Widget _buildTableActionsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('Rows Per Page', style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Container(
                  padding: EdgeInsets.zero, // Removed padding
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300), 
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _rowsPerPage,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.primary),
                      items: _rowsPerPageOptions.map((int val) {
                        return DropdownMenuItem<int>(
                          value: val,
                          child: Text('$val', style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _rowsPerPage = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 45,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300), 
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: TextField(
            controller: _historySearchController,
            decoration: const InputDecoration(
              hintText: 'Search History...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: InputBorder.none,
              suffixIcon: Icon(Icons.search, size: 20, color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationFooter(int count) {
    int displayCount = count > _rowsPerPage ? _rowsPerPage : count;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Showing $displayCount of $count entries', 
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          Row(
            children: [
              IconButton(
                onPressed: null, // Placeholder for real pagination logic
                icon: const Icon(Icons.chevron_left, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: null, 
                icon: const Icon(Icons.chevron_right, color: Colors.grey),
              ),
            ],
          )
        ],
      ),
    );
  }
}
