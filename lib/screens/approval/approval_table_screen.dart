import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../data/services/approval_service.dart';

class ApprovalTableScreen extends StatefulWidget {
  final String type;
  final String title;

  const ApprovalTableScreen({
    super.key,
    required this.type,
    required this.title,
  });

  @override
  State<ApprovalTableScreen> createState() => _ApprovalTableScreenState();
}

class _ApprovalTableScreenState extends State<ApprovalTableScreen> {
  final ApprovalService _approvalService = ApprovalService();
  
  // Table Data
  List<dynamic> _pendingList = [];
  List<dynamic> _completedList = [];
  bool _isLoadingTables = false;

  // Date Filters
  DateTime _fDate = DateTime.now().subtract(const Duration(days: 10));
  DateTime _tDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    setState(() => _isLoadingTables = true);
    try {
      Map<String, dynamic> pendingData = {};
      Map<String, dynamic> completedData = {};
      
      final fDateStr = DateFormat('dd-MM-yyyy').format(_fDate);
      final tDateStr = DateFormat('dd-MM-yyyy').format(_tDate);

      switch (widget.type) {
        case 'Leave':
          pendingData = await _approvalService.getLeaveApprovals();
          completedData = await _approvalService.getCompletedLeaveApprovals(fDate: fDateStr, tDate: tDateStr);
          break;
        case 'LeaveComp':
          pendingData = await _approvalService.getLeaveCompApprovals();
          completedData = await _approvalService.getCompletedLeaveCompApprovals(fDate: fDateStr, tDate: tDateStr);
          break;
        case 'Advance':
        case 'AdvAdj':
          pendingData = await _approvalService.getAdvanceApprovals();
          completedData = await _approvalService.getCompletedAdvanceApprovals(fDate: fDateStr, tDate: tDateStr);
          break;
        case 'ShiftDev':
          pendingData = await _approvalService.getShiftDevApprovals();
          completedData = await _approvalService.getCompletedShiftDevApprovals(fDate: fDateStr, tDate: tDateStr);
          break;
        case 'Permission':
          pendingData = await _approvalService.getPermissionApprovals();
          completedData = await _approvalService.getCompletedPermissionApprovals(fDate: fDateStr, tDate: tDateStr);
          break;
      }
      
      if (mounted) {
        setState(() {
          _pendingList = pendingData['dtLapp'] ?? pendingData['dtList'] ?? [];
          _completedList = completedData['dtLapp'] ?? completedData['dtList'] ?? [];
          _isLoadingTables = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTables = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _selectDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fDate : _tDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) _fDate = picked;
        else _tDate = picked;
      });
      _loadTables();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingTables 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPendingTableCard(),
                const SizedBox(height: 20),
                _buildCompletedTableCard(),
              ],
            ),
          ),
    );
  }

  String _getPendingTitle() {
    switch (widget.type) {
      case 'Leave': return 'Attendance Approval';
      case 'LeaveComp': return 'Leave Grant Approval';
      case 'Advance': 
      case 'AdvAdj': return 'Advance Adjustment Approval';
      case 'ShiftDev': return 'Approval Shift Deviation';
      case 'Permission': return 'Permission Approval';
      default: return 'Approval';
    }
  }

  List<DataColumn> _getPendingColumns() {
    final boldStyle = const TextStyle(fontWeight: FontWeight.bold);
    switch (widget.type) {
      case 'Leave':
        return [
          DataColumn(label: Text('TKT.NO', style: boldStyle)),
          DataColumn(label: Text('EMP NAME', style: boldStyle)),
          DataColumn(label: Text('DATE', style: boldStyle)),
          DataColumn(label: Text('FROM DATE', style: boldStyle)),
          DataColumn(label: Text('TO DATE', style: boldStyle)),
          DataColumn(label: Text('STATUS', style: boldStyle)),
          DataColumn(label: Text('REASON', style: boldStyle)),
          DataColumn(label: Text('ACTIONS', style: boldStyle)),
        ];
      case 'LeaveComp':
        return [
          DataColumn(label: Text('Tkt.No', style: boldStyle)),
          DataColumn(label: Text('Emp Name', style: boldStyle)),
          DataColumn(label: Text('Date', style: boldStyle)),
          DataColumn(label: Text('Status', style: boldStyle)),
          DataColumn(label: Text('Remarks', style: boldStyle)),
          DataColumn(label: Text('Actions', style: boldStyle)),
        ];
      case 'Advance':
      case 'AdvAdj':
        return [
          DataColumn(label: Text('TKT.NO', style: boldStyle)),
          DataColumn(label: Text('EMP NAME', style: boldStyle)),
          DataColumn(label: Text('DATE', style: boldStyle)),
          DataColumn(label: Text('SALARY PERIOD', style: boldStyle)),
          DataColumn(label: Text('DEDUCTION', style: boldStyle)),
          DataColumn(label: Text('ADJ.AMOUNT', style: boldStyle)),
          DataColumn(label: Text('ACTIONS', style: boldStyle)),
        ];
      case 'ShiftDev':
        return [
          DataColumn(label: Text('DEVNO', style: boldStyle)),
          DataColumn(label: Text('DATE', style: boldStyle)),
          DataColumn(label: Text('FROM DATE', style: boldStyle)),
          DataColumn(label: Text('TO DATE', style: boldStyle)),
          DataColumn(label: Text('GROUP NAME', style: boldStyle)),
          DataColumn(label: Text('DEVIATION SHIFT', style: boldStyle)),
          DataColumn(label: Text('ACTIONS', style: boldStyle)),
        ];
      case 'Permission':
        return [
          DataColumn(label: Text('TKT.NO', style: boldStyle)),
          DataColumn(label: Text('EMP NAME', style: boldStyle)),
          DataColumn(label: Text('DATE', style: boldStyle)),
          DataColumn(label: Text('TYPE', style: boldStyle)),
          DataColumn(label: Text('SESSION', style: boldStyle)),
          DataColumn(label: Text('MINS', style: boldStyle)),
          DataColumn(label: Text('REASON', style: boldStyle)),
          DataColumn(label: Text('ACTIONS', style: boldStyle)),
        ];
      default: return [];
    }
  }

  DataRow _getPendingRow(dynamic item) {
    List<DataCell> cells = [];
    switch (widget.type) {
      case 'Leave':
        cells = [
          DataCell(Text(item['TicketNo']?.toString() ?? '')),
          DataCell(Text(item['EmpName']?.toString() ?? '')),
          DataCell(Text(item['SDate']?.toString() ?? '')),
          DataCell(Text(item['FromDate']?.toString() ?? '')),
          DataCell(Text(item['ToDate']?.toString() ?? '')),
          DataCell(Text(item['Status']?.toString() ?? '')),
          DataCell(Text(item['Remarks']?.toString() ?? '')),
        ];
        break;
      case 'LeaveComp':
        cells = [
          DataCell(Text(item['TicketNo']?.toString() ?? '')),
          DataCell(Text(item['EmpName']?.toString() ?? '')),
          DataCell(Text(item['SDate']?.toString() ?? '')),
          DataCell(Text(item['Status']?.toString() ?? '')),
          DataCell(Text(item['Remarks']?.toString() ?? '')),
        ];
        break;
      case 'Advance':
      case 'AdvAdj':
        cells = [
          DataCell(Text(item['TicketNo']?.toString() ?? '')),
          DataCell(Text(item['EmpName']?.toString() ?? '')),
          DataCell(Text(item['ReqDate']?.toString() ?? '')),
          DataCell(Text(item['SalaryMonth']?.toString() ?? '')),
          DataCell(Text(item['DedName']?.toString() ?? '')),
          DataCell(Text(item['AdjAmount']?.toString() ?? '')),
        ];
        break;
      case 'ShiftDev':
        cells = [
          DataCell(Text(item['DevNo']?.toString() ?? '')),
          DataCell(Text(item['SDate']?.toString() ?? '')),
          DataCell(Text(item['StartDate']?.toString() ?? '')),
          DataCell(Text(item['EndDate']?.toString() ?? '')),
          DataCell(Text(item['GroupName']?.toString() ?? '')),
          DataCell(Text(item['DShiftName']?.toString() ?? '')),
        ];
        break;
      case 'Permission':
        cells = [
          DataCell(Text(item['TicketNo']?.toString() ?? '')),
          DataCell(Text(item['EmpName']?.toString() ?? '')),
          DataCell(Text(item['SDate']?.toString() ?? '')),
          DataCell(Text(item['MStatus']?.toString() ?? '')),
          DataCell(Text(item['EStatus']?.toString() ?? '')),
          DataCell(Text(item['WHours']?.toString() ?? '')),
          DataCell(Text(item['Remarks']?.toString() ?? '')),
        ];
        break;
    }
    
    // Add common actions
    cells.add(DataCell(Row(children: [
      IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () {}),
      IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () {}),
    ])));
    
    return DataRow(cells: cells);
  }

  List<DataColumn> _getCompletedColumns() {
    final boldStyle = const TextStyle(fontWeight: FontWeight.bold);
    switch (widget.type) {
      case 'Leave':
      case 'LeaveComp':
        return [
          DataColumn(label: Text('Tkt.No', style: boldStyle)),
          DataColumn(label: Text('Emp Name', style: boldStyle)),
          DataColumn(label: Text('Date', style: boldStyle)),
          DataColumn(label: Text('Leave Name', style: boldStyle)),
          DataColumn(label: Text('Reason', style: boldStyle)),
          DataColumn(label: Text('Status', style: boldStyle)),
          DataColumn(label: Text('By', style: boldStyle)),
          DataColumn(label: Text('On', style: boldStyle)),
        ];
      case 'Advance':
      case 'AdvAdj':
        return [
          DataColumn(label: Text('Tkt.No', style: boldStyle)),
          DataColumn(label: Text('Emp Name', style: boldStyle)),
          DataColumn(label: Text('Date', style: boldStyle)),
          DataColumn(label: Text('Salary Period', style: boldStyle)),
          DataColumn(label: Text('Deduction', style: boldStyle)),
          DataColumn(label: Text('Adj.Amount', style: boldStyle)),
          DataColumn(label: Text('Status', style: boldStyle)),
          DataColumn(label: Text('By', style: boldStyle)),
          DataColumn(label: Text('On', style: boldStyle)),
        ];
      case 'ShiftDev':
        return [
          DataColumn(label: Text('DEVNO', style: boldStyle)),
          DataColumn(label: Text('DATE', style: boldStyle)),
          DataColumn(label: Text('FROM DATE', style: boldStyle)),
          DataColumn(label: Text('TO DATE', style: boldStyle)),
          DataColumn(label: Text('GROUP NAME', style: boldStyle)),
          DataColumn(label: Text('DEVIATION SHIFT', style: boldStyle)),
          DataColumn(label: Text('STATUS', style: boldStyle)),
          DataColumn(label: Text('ON', style: boldStyle)),
        ];
      case 'Permission':
        return [
          DataColumn(label: Text('Tkt.No', style: boldStyle)),
          DataColumn(label: Text('Emp Name', style: boldStyle)),
          DataColumn(label: Text('Date', style: boldStyle)),
          DataColumn(label: Text('Type', style: boldStyle)),
          DataColumn(label: Text('Session', style: boldStyle)),
          DataColumn(label: Text('Mins', style: boldStyle)),
          DataColumn(label: Text('Reason', style: boldStyle)),
          DataColumn(label: Text('Status', style: boldStyle)),
          DataColumn(label: Text('By', style: boldStyle)),
          DataColumn(label: Text('On', style: boldStyle)),
          DataColumn(label: Text('Remarks', style: boldStyle)),
        ];
      default: return [];
    }
  }

  DataRow _getCompletedRow(dynamic item) {
    List<DataCell> cells = [];
    switch (widget.type) {
      case 'Leave':
      case 'LeaveComp':
        cells = [
          DataCell(Text(item['TicketNo']?.toString() ?? '')),
          DataCell(Text(item['EmpName']?.toString() ?? '')),
          DataCell(Text(item['SDate']?.toString() ?? '')),
          DataCell(Text(item['Status']?.toString() ?? '')),
          DataCell(Text(item['Remarks']?.toString() ?? '')),
          DataCell(Text(item['App']?.toString() ?? '')),
          DataCell(Text(item['AppBy']?.toString() ?? '')),
          DataCell(Text(item['AppDate']?.toString() ?? '')),
        ];
        break;
      case 'Advance':
      case 'AdvAdj':
        cells = [
          DataCell(Text(item['TicketNo']?.toString() ?? '')),
          DataCell(Text(item['EmpName']?.toString() ?? '')),
          DataCell(Text(item['ReqDate']?.toString() ?? '')),
          DataCell(Text(item['SalaryMonth']?.toString() ?? '')),
          DataCell(Text(item['DedName']?.toString() ?? '')),
          DataCell(Text(item['AdjAmount']?.toString() ?? '')),
          DataCell(Text(item['App']?.toString() ?? '')),
          DataCell(Text(item['AppBy']?.toString() ?? '')),
          DataCell(Text(item['AppOn']?.toString() ?? '')),
        ];
        break;
      case 'ShiftDev':
        cells = [
          DataCell(Text(item['DevNo']?.toString() ?? '')),
          DataCell(Text(item['SDate']?.toString() ?? '')),
          DataCell(Text(item['StartDate']?.toString() ?? '')),
          DataCell(Text(item['EndDate']?.toString() ?? '')),
          DataCell(Text(item['GroupName']?.toString() ?? '')),
          DataCell(Text(item['DShiftName']?.toString() ?? '')),
          DataCell(Text(item['App']?.toString() ?? '')),
          DataCell(Text(item['AppOn']?.toString() ?? '')),
        ];
        break;
      case 'Permission':
        cells = [
          DataCell(Text(item['TicketNo']?.toString() ?? '')),
          DataCell(Text(item['EmpName']?.toString() ?? '')),
          DataCell(Text(item['SDate']?.toString() ?? '')),
          DataCell(Text(item['MStatus']?.toString() ?? '')),
          DataCell(Text(item['EStatus']?.toString() ?? '')),
          DataCell(Text(item['WHours']?.toString() ?? '')),
          DataCell(Text(item['Remarks']?.toString() ?? '')),
          DataCell(Text(item['App']?.toString() ?? '')),
          DataCell(Text(item['AppBy']?.toString() ?? '')),
          DataCell(Text(item['AppDate']?.toString() ?? '')),
          DataCell(Text(item['AppRemarks']?.toString() ?? '')),
        ];
        break;
    }
    return DataRow(cells: cells);
  }

  Widget _buildPendingTableCard() {
    return Column(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(_getPendingTitle(), 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTableActionsRow(),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F1F1)),
                  columns: _getPendingColumns(),
                  rows: _pendingList.isEmpty 
                    ? [DataRow(cells: [const DataCell(Text('No data available in table')), ...List.generate(_getPendingColumns().length - 1, (i) => const DataCell(SizedBox()))])]
                    : _pendingList.map((item) => _getPendingRow(item)).toList(),
                ),
              ),
              const Divider(),
              _buildPaginationFooter(_pendingList.length),
              Container(height: 3, width: 80, color: Colors.grey.shade300)
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedTableCard() {
    final title = widget.type == 'ShiftDev' ? 'Shift Deviation Approval Completed' : 'Approval Completed';
    return Column(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(title, 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              _buildDatePickerRow(_fDate, true),
              const SizedBox(height: 12),
              _buildDatePickerRow(_tDate, false),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loadTables,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B734B),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Icon(Icons.search, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTableActionsRow(),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F1F1)),
                  columns: _getCompletedColumns(),
                  rows: _completedList.isEmpty 
                    ? [DataRow(cells: [const DataCell(Text('No data available in table')), ...List.generate(_getCompletedColumns().length - 1, (i) => const DataCell(SizedBox()))])]
                    : _completedList.map((item) => _getCompletedRow(item)).toList(),
                ),
              ),
              const Divider(),
              _buildPaginationFooter(_completedList.length),
              Container(height: 3, width: 80, color: Colors.grey.shade300)
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerRow(DateTime date, bool isFrom) {
    return InkWell(
      onTap: () => _selectDate(isFrom),
      child: Container(
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade300))),
              child: const Icon(Icons.calendar_today, size: 16, color: Color(0xFF8B734B)),
            ),
            const SizedBox(width: 12),
            Text(DateFormat('dd-MM-yyyy').format(date), style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ],
        ),
      ),
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
              child: const Row(
                children: [
                  Text('10', style: TextStyle(fontSize: 12)),
                  Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.blue),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 40,
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
          child: const TextField(
            decoration: InputDecoration(
              hintText: 'Search',
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
          Text('Showing 0 to $count of $count entries', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
}
