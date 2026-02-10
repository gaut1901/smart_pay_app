import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
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

  // Form fields
  DateTime _devDate = DateTime.now();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String? _selectedGroupName;
  String? _selectedShiftName;
  
  List<String> _groupNames = [];
  List<String> _shiftNames = [];
  bool _isLoadingLookups = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
    _loadLookups();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });
    try {
      final history = await _shiftDevService.getShiftDeviationHistory();
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

  Future<void> _loadLookups() async {
    setState(() => _isLoadingLookups = true);
    try {
      final dateFormat = DateFormat('dd-MM-yyyy');
      final groups = await _shiftDevService.getGroupNames(
        dateFormat.format(_startDate),
        dateFormat.format(_endDate),
      );
      final shifts = await _shiftDevService.getShifts();
      
      setState(() {
        _groupNames = groups;
        _shiftNames = shifts;
        _isLoadingLookups = false;
      });
    } catch (e) {
      setState(() => _isLoadingLookups = false);
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedGroupName == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Group Name')));
      return;
    }
    if (_selectedShiftName == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Deviated Shift')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dateFormat = DateFormat('dd-MM-yyyy');
      await _shiftDevService.submitShiftDeviation(
        sDate: dateFormat.format(_devDate),
        groupName: _selectedGroupName!,
        shiftName: _selectedShiftName!,
        startDate: dateFormat.format(_startDate),
        endDate: dateFormat.format(_endDate),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift deviation submitted successfully')),
        );
        setState(() {
          _selectedGroupName = null;
          _selectedShiftName = null;
        });
        _loadHistory();
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppStyles.modernCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Apply Shift Deviation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildDatePickerField('Deviation Date', _devDate, (date) => setState(() => _devDate = date)),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _buildDatePickerField('Start Date', _startDate, (date) {
                      setState(() => _startDate = date);
                      _loadLookups();
                    })),
                    const SizedBox(width: 15),
                    Expanded(child: _buildDatePickerField('End Date', _endDate, (date) {
                      setState(() => _endDate = date);
                      _loadLookups();
                    })),
                  ],
                ),
                const SizedBox(height: 15),
                _buildDropdownField('Group Name', _groupNames, _selectedGroupName, (val) => setState(() => _selectedGroupName = val)),
                const SizedBox(height: 15),
                _buildDropdownField('Deviated Shift', _shiftNames, _selectedShiftName, (val) => setState(() => _selectedShiftName = val)),
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
    if (_history.isEmpty) return const Center(child: Text('No history found'));

    return RefreshIndicator(
      onRefresh: () async => _loadHistory(),
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

  Widget _buildHistoryItem(ShiftDeviationRequest item) {
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
                Text('No: ${item.devNo}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Group: ${item.groupName}', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text('Shift: ${item.shiftName}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('Period: ${item.startDate} to ${item.endDate}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
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
              firstDate: DateTime.now().subtract(const Duration(days: 90)),
              lastDate: DateTime.now().add(const Duration(days: 90)),
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
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
