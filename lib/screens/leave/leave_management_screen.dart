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
  List<LeaveBalance> _balances = [];
  bool _isLoadingHistory = true;
  bool _isLoadingBalance = true;
  String? _historyError;
  String? _balanceError;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _fetchLookup();
  }

  void _loadData() {
    _fetchHistory();
    _fetchBalance();
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
            Tab(text: 'Apply Leave'),
            Tab(text: 'Leave History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
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
}
