import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants.dart';
import '../../data/services/it_file_service.dart';

class ITFileScreen extends StatefulWidget {
  const ITFileScreen({super.key});

  @override
  State<ITFileScreen> createState() => _ITFileScreenState();
}

class _ITFileScreenState extends State<ITFileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ITFileService _itFileService = ITFileService();
  
  List<ITFileRequest> _history = [];
  bool _isLoadingHistory = true;
  String? _historyError;

  // Form data
  List<dynamic> _dtFinYear = [];
  List<dynamic> _dtEmp = [];
  List<dynamic> _dtSlab = [];
  List<dynamic> _dtITHeadType = [];
  List<dynamic> _dtITHead = [];
  bool _isLoadingLookups = true;

  // Form fields
  DateTime _selectedDate = DateTime.now();
  String? _selectedFinYear;
  String? _selectedEmpName;
  String? _selectedSlab;
  String? _selectedITHeadType;
  String? _selectedITHead;
  final TextEditingController _pAmountController = TextEditingController(text: '0');
  final TextEditingController _aAmountController = TextEditingController(text: '0');
  File? _selectedFile;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
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
      final history = await _itFileService.getITFileHistory();
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

  Future<void> _fetchLookups() async {
    setState(() => _isLoadingLookups = true);
    try {
      final lookupData = await _itFileService.getITFileLookup();
      setState(() {
        _dtFinYear = lookupData['dtFinYear'] ?? [];
        _dtEmp = lookupData['dtEmp'] ?? [];
        _dtSlab = lookupData['dtSlab'] ?? [];
        _dtITHeadType = lookupData['dtITHeadType'] ?? [];

        if (_dtFinYear.isNotEmpty) _selectedFinYear = _dtFinYear[0]['FinYear'];
        if (_dtEmp.isNotEmpty) _selectedEmpName = _dtEmp[0]['EMPNAME'];
        if (_dtSlab.isNotEmpty) _selectedSlab = _dtSlab[0]['ITSlabName'];
        if (_dtITHeadType.isNotEmpty) _selectedITHeadType = _dtITHeadType[0]['ITHeadType'];
        
        if (lookupData['SDate'] != null && lookupData['SDate'] != "") {
           try {
             _selectedDate = DateFormat('dd-MM-yyyy').parse(lookupData['SDate']);
           } catch (_) {}
        }
        
        _isLoadingLookups = false;
      });
      _onITHeadParamsChange();
    } catch (e) {
      setState(() => _isLoadingLookups = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load lookups: $e')),
        );
      }
    }
  }

  Future<void> _onITHeadParamsChange() async {
    if (_selectedEmpName == null || _selectedITHeadType == null || _selectedFinYear == null || _selectedSlab == null) return;

    try {
      final result = await _itFileService.getITHead(
        empName: _selectedEmpName!,
        itHeadType: _selectedITHeadType!,
        finYear: _selectedFinYear!,
        slabName: _selectedSlab!,
      );
      setState(() {
        _dtITHead = result['dtITHead'] ?? [];
        if (_dtITHead.isNotEmpty) {
          _selectedITHead = _dtITHead[0]['ITHead'];
          _onITHeadChange();
        } else {
          _selectedITHead = null;
          _pAmountController.text = '0';
        }
      });
    } catch (e) {
      debugPrint('Error fetching IT heads: $e');
    }
  }

  Future<void> _onITHeadChange() async {
    if (_selectedEmpName == null || _selectedITHeadType == null || _selectedFinYear == null || _selectedSlab == null || _selectedITHead == null) return;

    try {
      final result = await _itFileService.getITHeadAmount(
        empName: _selectedEmpName!,
        itHeadType: _selectedITHeadType!,
        finYear: _selectedFinYear!,
        slabName: _selectedSlab!,
        itHead: _selectedITHead!,
      );
      setState(() {
        final dtAmount = result['dtAmount'] as List?;
        if (dtAmount != null && dtAmount.isNotEmpty) {
          _pAmountController.text = dtAmount[0]['PAmount']?.toString() ?? '0';
        } else {
          _pAmountController.text = '0';
        }
      });
    } catch (e) {
      debugPrint('Error fetching IT head amount: $e');
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedFinYear == null || _selectedEmpName == null || _selectedSlab == null || _selectedITHeadType == null || _selectedITHead == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }
    if (_aAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Actual Amount')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dateFormat = DateFormat('dd-MM-yyyy');
      await _itFileService.submitITFile(
        entryDate: dateFormat.format(_selectedDate),
        slabName: _selectedSlab!,
        finYear: _selectedFinYear!,
        itHead: _selectedITHead!,
        itHeadType: _selectedITHeadType!,
        empName: _selectedEmpName!,
        pAmount: double.tryParse(_pAmountController.text) ?? 0.0,
        aAmount: double.tryParse(_aAmountController.text) ?? 0.0,
        file: _selectedFile,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('IT file submitted successfully')),
        );
        _aAmountController.text = '0';
        setState(() {
          _selectedFile = null;
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

  @override
  void dispose() {
    _tabController.dispose();
    _pAmountController.dispose();
    _aAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Income Tax File', style: TextStyle(color: Colors.white, fontSize: 18)),
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
                const Text('New IT File Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildDatePickerField('Date', _selectedDate, (date) => setState(() => _selectedDate = date)),
                const SizedBox(height: 15),
                _buildDropdownField(
                  'Fin Year', 
                  _dtFinYear.map((e) => e['FinYear']?.toString() ?? '').toList(), 
                  _selectedFinYear, 
                  (val) {
                    setState(() => _selectedFinYear = val);
                    _onITHeadParamsChange();
                  }
                ),
                const SizedBox(height: 15),
                _buildDropdownField(
                  'Emp Name', 
                  _dtEmp.map((e) => e['EMPNAME']?.toString() ?? '').toList(), 
                  _selectedEmpName, 
                  (val) {
                    setState(() => _selectedEmpName = val);
                    _onITHeadParamsChange();
                  }
                ),
                const SizedBox(height: 15),
                _buildDropdownField(
                  'Slab', 
                  _dtSlab.map((e) => e['ITSlabName']?.toString() ?? '').toList(), 
                  _selectedSlab, 
                  (val) {
                    setState(() => _selectedSlab = val);
                    _onITHeadParamsChange();
                  }
                ),
                const SizedBox(height: 15),
                _buildDropdownField(
                  'Earnings/Deductions', 
                  _dtITHeadType.map((e) => e['ITHeadType']?.toString() ?? '').toList(), 
                  _selectedITHeadType, 
                  (val) {
                    setState(() => _selectedITHeadType = val);
                    _onITHeadParamsChange();
                  }
                ),
                const SizedBox(height: 15),
                _buildDropdownField(
                  'Head', 
                  _dtITHead.map((e) => e['ITHead']?.toString() ?? '').toList(), 
                  _selectedITHead, 
                  (val) {
                    setState(() => _selectedITHead = val);
                    _onITHeadChange();
                  }
                ),
                const SizedBox(height: 15),
                _buildTextField('Projected Amount', '0', _pAmountController, keyboardType: TextInputType.number, readOnly: true),
                const SizedBox(height: 15),
                _buildTextField('Actual Amount', 'Enter amount', _aAmountController, keyboardType: TextInputType.number),
                const SizedBox(height: 15),
                _buildFilePickerField(),
                const SizedBox(height: 30),
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
                      : const Text('Submit Request', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
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
    if (_history.isEmpty) return const Center(child: Text('No history found'));

    return RefreshIndicator(
      onRefresh: () async => _fetchHistory(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final item = _history[index];
          return _buildHistoryItem(item);
        },
      ),
    );
  }

  Widget _buildHistoryItem(ITFileRequest item) {
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
                Text('FY: ${item.finYear}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.itHead, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500, fontSize: 15)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Amount: ${item.amount}', style: const TextStyle(fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.app.contains('Approved') ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.app,
                    style: TextStyle(
                      color: item.app.contains('Approved') ? Colors.green : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (item.appBy.isNotEmpty) ...[
               const SizedBox(height: 8),
               Text('Approved By: ${item.appBy} on ${item.appOn}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
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
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
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

  Widget _buildTextField(String label, String placeholder, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: placeholder,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.all(12),
            filled: readOnly,
            fillColor: readOnly ? Colors.grey.shade100 : null,
          ),
        ),
      ],
    );
  }

  Widget _buildFilePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Attachment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickFile,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_file, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedFile == null ? 'Select file (PDF, JPG, PNG)' : _selectedFile!.path.split('/').last,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _selectedFile == null ? Colors.grey : Colors.black),
                  ),
                ),
                if (_selectedFile != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(() => _selectedFile = null),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
