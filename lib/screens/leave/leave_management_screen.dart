import 'package:flutter/material.dart';
import '../../core/constants.dart';
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
  bool _isLoadingHistory = true;
  bool _isLoadingBalance = true;
  bool _isLoadingPeriodBalance = true;
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

  // Search
  final TextEditingController _searchController = TextEditingController();
  List<LeaveBalance> _filteredBalances = [];
  List<String> _leaveHeaders = [];
  bool _isLoadingHeaders = true;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _generatePeriodOptions();
    _loadData();
    _fetchLookup();
    _searchController.addListener(_onSearchChanged);
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



  void _loadData() {
    _fetchHistory();
    _fetchBalance(); // Fetch current for Apply Leave
    _fetchPeriodBalance(); // Fetch period for Leave Balance tab
    _fetchHeaders();
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

  Future<void> _fetchPeriodBalance() async {
    setState(() {
      _isLoadingPeriodBalance = true;
    });
    try {
      // Fetch specific date balance for "Leave Balance" tab
      final balances = await _leaveService.getLeaveBalance(date: _periodStartDate);
      setState(() {
        _periodBalances = balances;
        _isLoadingPeriodBalance = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPeriodBalance = false;
      });
      // Optionally handle error for period balance
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



  Future<void> _fetchHeaders() async {
    setState(() => _isLoadingHeaders = true);
    try {
      final headers = await _leaveService.getEmployeeLeaveHeaders();
      setState(() {
        _leaveHeaders = headers;
        _isLoadingHeaders = false;
      });
    } catch (e) {
      setState(() => _isLoadingHeaders = false);
      // Optional: Handle error
      debugPrint('Error fetching headers: $e');
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
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave request submitted successfully')),
        );
        _remarksController.clear();
        setState(() {
          _mcFilePath = null;
          _selectedFile = null;
        });
        _loadData();
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
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitLeave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isSubmitting 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Submit Application', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
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

    if (_history.isEmpty) {
      return const Center(child: Text('No leave history found'));
    }

    return RefreshIndicator(
      onRefresh: () async => _fetchHistory(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          return _buildHistoryItem(_history[index]);
        },
      ),
    );
  }

  Widget _buildHistoryItem(LeaveRequest item) {
    final Color statusColor = item.status == 'Approved' 
        ? Colors.green 
        : (item.status == 'Rejected' ? Colors.red : Colors.orange);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.modernCardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.calendar_month, color: statusColor),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.remarks, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${item.fDate} - ${item.tDate}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.status, 
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildLeaveBalanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppStyles.modernCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Leave Balance', style: AppStyles.heading.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildPeriodDropdown(),
                const SizedBox(height: 16),
                _buildDateSearchRow(),
                const SizedBox(height: 20),
                Center(
                  child: Text('Leave Balance', style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold, 
                    color: AppColors.textDark
                  )),
                ),
                const SizedBox(height: 10),
                const Divider(),
                _buildBalanceTable(),
                const Divider(),
                _buildStatusDaysTable(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodDropdown() {
    return Container(
      width: 250, // Limit width as per design roughly
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Text('Select Leave Period'),
          value: _selectedPeriod,
          items: _periodOptions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedPeriod = val;
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
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildDateSearchRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          children: [
            _buildDateDisplay(_periodStartDate, () => _selectPeriodDate(true)),
            const SizedBox(height: 10),
            _buildDateDisplay(_periodEndDate, () => _selectPeriodDate(false)),
          ],
        ),
        const Spacer(),
        _buildSearchButton(),
      ],
    );
  }

  Widget _buildDateDisplay(DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: Color(0xFFB8860B), size: 16),
            const SizedBox(width: 8),
            Text(DateFormat('dd-MM-yyyy').format(date), 
              style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return SizedBox(
      height: 40,
      width: 40, // Small square button
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDE3C4B), // Red color from image
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        onPressed: _fetchPeriodBalance,
        child: const Icon(Icons.search, color: Colors.white, size: 20),
      ),
    );
  }



  Widget _buildBalanceTable() {
    if (_isLoadingPeriodBalance) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(),
      ));
    }

    if (_periodBalances.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text('No records found'),
      ));
    }

    const headerStyle = TextStyle(color: Color(0xFFB8860B), fontWeight: FontWeight.bold, fontSize: 13);


    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.white),
        columnSpacing: 15,
        columns: const [
          DataColumn(label: Text('Leave', style: headerStyle)),
          DataColumn(label: Text('Opening', style: headerStyle)),
          DataColumn(label: Text('Credit', style: headerStyle)),
          DataColumn(label: Text('Laps', style: headerStyle)),
          DataColumn(label: Text('Taken', style: headerStyle)),
          DataColumn(label: Text('Pending', style: headerStyle)),
          DataColumn(label: Text('Closing', style: headerStyle)),
        ],
        rows: _periodBalances.map((balance) {
          return DataRow(
            cells: [
              DataCell(Text(balance.leaveType, style: const TextStyle(fontSize: 13))),
              DataCell(Text(balance.yearOpen.toStringAsFixed(0), style: const TextStyle(fontSize: 13))),
              DataCell(Text(balance.yearCredit.toStringAsFixed(0), style: const TextStyle(fontSize: 13))),
              DataCell(Text(balance.yearLaps.toStringAsFixed(0), style: const TextStyle(fontSize: 13))),
              DataCell(Text(balance.yearTaken.toStringAsFixed(0), style: const TextStyle(fontSize: 13))),
              DataCell(Text(balance.pending.toStringAsFixed(0), style: const TextStyle(fontSize: 13))),
              DataCell(Text(balance.yearBalance.toStringAsFixed(0), style: const TextStyle(fontSize: 13))),
            ],
          );
        }).toList(),

      ),
    );
  }

  Widget _buildStatusDaysTable() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 10),
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade200),
        columnWidths: const {
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(1),
        },
        children: const [
          TableRow(
            children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Status', style: TextStyle(color: Color(0xFF555555), fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Days', style: TextStyle(color: Color(0xFF555555), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          TableRow(
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(''),
              ),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(''),
              ),
            ],
          ),
        ],
      ),
    );
  }


}
