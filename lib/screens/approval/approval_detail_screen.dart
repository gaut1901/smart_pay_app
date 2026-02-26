import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../data/services/approval_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/leave_service.dart';

class ApprovalDetailScreen extends StatefulWidget {
  final String type;
  final String id;
  final String title;
  final String? empCode; // Optional: set when navigating from Team Detail screen

  const ApprovalDetailScreen({
    super.key,
    required this.type,
    required this.id,
    required this.title,
    this.empCode,
  });

  @override
  State<ApprovalDetailScreen> createState() => _ApprovalDetailScreenState();
}

class _ApprovalDetailScreenState extends State<ApprovalDetailScreen> {
  final ApprovalService _approvalService = ApprovalService();
  final LeaveService _leaveService = LeaveService();
  final TextEditingController _remarksController = TextEditingController();
  Map<String, dynamic>? _details;
  List<dynamic> _leaveBalances = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Restore member emp code if navigating from a team detail context
    if (widget.empCode != null && widget.empCode!.isNotEmpty) {
      AuthService.memberEmpCode = widget.empCode!;
    }
    _loadDetails();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    // Reset member emp code if we set it
    if (widget.empCode != null && widget.empCode!.isNotEmpty) {
      AuthService.memberEmpCode = '0';
    }
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final details = await _approvalService.getRequestDetails(widget.type, widget.id);
      
      if (details.isEmpty) {
        setState(() {
          _error = 'No details found for this request';
          _isLoading = false;
        });
        return;
      }

      // If it's a leave related request, try to fetch current balance proactively if not in details
      List<dynamic> fetchedBalances = [];
      if (widget.type == 'Leave' || widget.type == 'Attendance' || widget.type == 'LeaveComp' || widget.type == 'Supplementary') {
        final dynamic rawDt1 = details['dt1'] ?? details['dt'] ?? [];
        final List<dynamic> dt1 = rawDt1 is List ? rawDt1 : [];
        
        if (dt1.isEmpty) {
          try {
            final balances = await _leaveService.getLeaveBalance();
            fetchedBalances = balances.map((b) => {
              'Status': b.leaveType,
              'OB': b.yearOpen.toStringAsFixed(1),
              'Entitle': b.yearCredit.toStringAsFixed(1),
              'Laps': b.yearLaps.toStringAsFixed(1),
              'Taken': b.yearTaken.toStringAsFixed(1),
              'Pending': b.pending.toStringAsFixed(1),
              'Balance': b.yearBalance.toStringAsFixed(1),
            }).toList();
          } catch (e) {
            debugPrint('Error fetching fallback balance: $e');
          }
        }
      }

      setState(() {
        _details = details;
        _leaveBalances = fetchedBalances;
        _isLoading = false;
        
        // Pre-fill remarks if available
        if (_details != null) {
           String? existingRemarks = _details!['AppRemarks']?.toString() ?? _details!['AppRemarks1']?.toString();
           if (existingRemarks != null && existingRemarks != 'null') {
             _remarksController.text = existingRemarks;
           }
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _processApproval(String status) async {
    if (_details == null) return;

    setState(() => _isSubmitting = true);
    try {
      Map<String, dynamic> extraData = {};
      
      // Standard fields to echo back for legacy backend
      final fieldsToEcho = [
        'AppType', 'AppLevel', 'Amount', 'AdvAmount', 'Days', 'OldDays',
        'SDate', 'FromDate', 'ToDate', 'Status', 'LRName', 'Remarks',
        'FText', 'TText', 'SalaryMonth', 'DedName', 'InstAmt', 'NoOfInst',
        'PType', 'Session', 'PerMins', 'EmpCode', 'EmpCode1', 'oldPType', 'oldSession', 
        'oldPerMins', 'oldSDate', 'oldRemarks', 'Revise', 'Cancel'
      ];

      for (var field in fieldsToEcho) {
        if (_details!.containsKey(field)) {
          extraData[field] = _details![field];
        }
      }

      // Special handling for some keys that might be slightly different or missing in list above
      if (_details!.containsKey('AdvAmount')) extraData['Amount'] = _details!['AdvAmount'];

      await _approvalService.submitApproval(
        type: widget.type,
        id: widget.id,
        status: status,
        remarks: _remarksController.text,
        extraData: extraData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request $status successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isProcessed = false;
    if (_details != null) {
      final status = _getDetailValue(['App', 'AppStatus', 'Status', 'MStatus1'])?.toLowerCase() ?? '';
      isProcessed = status.contains('approved') || status.contains('rejected') || status.contains('accept');
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.title} Details', style: const TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _buildContent(),
      bottomNavigationBar: (_isLoading || _error != null || isProcessed) 
          ? null 
          : _buildBottomActions(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _loadDetails, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_details == null) return const Center(child: Text('No details found'));

    final List<Map<String, String>> displayFields = _getDisplayFields();

    // Extract header fields
    // Extract header fields with comprehensive keys
    final ticketNo = _getDetailValue(['TicketNo', 'TicketNo1', 'ticketno', 'TKTNO', 'tktno', 'TktNo', 'TKT_NO', 'TKT.NO']) ?? '-';
    final empCode = _getDetailValue(['EmpCode', 'EmpCode1', 'empcode', 'EmpID', 'empid', 'Emp_Code']) ?? '-';
    final date = _getDetailValue(['SDate', 'SDate1', 'ReqDate', 'sdate', 'date', 'Date', 'RequestDate', 'ReqDate']) ?? '-';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium Header Card mimicking the list card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Expanded(child: _headerDetailItem('TKT.NO', ticketNo)),
                Expanded(child: _headerDetailItem('EmpCode', empCode)),
                Expanded(child: _headerDetailItem('Date', date)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildExtraInfoSection(),
          const SizedBox(height: 16),
          
          // Render dynamic fields as read-only form
          ...displayFields.map((field) {
            // Skip fields already shown in header to reduce clutter
            if (field['label'] == 'TKT.NO' || field['label'] == 'EmpCode' || field['label'] == 'Date') {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildReadOnlyField(field['label']!, field['value']!),
            );
          }),
          const SizedBox(height: 24),
          const Text(
            'Approval Remarks',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _remarksController,
            maxLines: 1, 
            decoration: InputDecoration(
              hintText: '-',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  List<Map<String, String>> _getDisplayFields() {
    if (_details == null) return [];

    final List<Map<String, String>> fields = [];

    void addField(String label, List<String> keys) {
      final value = _getDetailValue(keys);
      if (value != null && value.isNotEmpty && value != 'null') {
        fields.add({'label': label, 'value': value});
      }
    }

    // Common fields from list card and general details
    addField('TKT.NO', ['TicketNo', 'TicketNo1', 'ticketno', 'TKTNO', 'tktno', 'TktNo', 'TKT_NO', 'TKT.NO']);
    addField('EmpCode', ['EmpCode', 'EmpCode1', 'empcode', 'EmpID', 'empid', 'Emp_Code']);
    addField('Employee Name', ['EmpName', 'EmpName1', 'empname', 'LRName', 'EmployeeName']);
    addField('Date', ['SDate', 'SDate1', 'ReqDate', 'sdate', 'date', 'Date', 'RequestDate']);
    
    switch (widget.type) {
      case 'Attendance':
      case 'Leave':
        addField('Status', ['Status', 'Status1', 'LeaveName', 'leavename', 'MStatus1', 'MStatus', 'status', 'StatusType', 'statustype']);
        addField('From Date', ['FromDate', 'FromDate1', 'FDate', 'fdate', 'fromdate', 'From_Date']);
        addField('To Date', ['ToDate', 'ToDate1', 'TDate', 'EDate', 'tdate', 'todate', 'To_Date']);
        addField('Reason', ['Remarks', 'Remarks1', 'LRName', 'lrname', 'remarks', 'Reason', 'reason', 'Rsn']);
        break;
      case 'LeaveComp':
        addField('Worked Date', ['SDate', 'SDate1', 'date']);
        addField('Days', ['Days', 'OldDays', 'days']);
        addField('Leave Name', ['Status', 'Status1', 'LeaveName', 'status', 'StatusType']);
        addField('Reason', ['Remarks', 'Remarks1', 'LRName', 'remarks', 'Reason']);
        break;
      case 'Supplementary':
        addField('Ticket No', ['TicketNo', 'ticketno', 'TicketNo1']);
        addField('Employee', ['EmpName', 'empname', 'EmpName1']);
        addField('Date', ['SDate', 'sdate', 'SDate1']);
        addField('From Date', ['FromDate', 'fdate', 'FromDate1']);
        addField('To Date', ['ToDate', 'tdate', 'ToDate1']);
        addField('Status', ['Status', 'status', 'Status1']);
        addField('Reason', ['Remarks', 'remarks', 'Remarks1']);
        break;
      case 'Permission':
        addField('Type', ['PType', 'ptype']);
        addField('Session', ['Session', 'session']);
        addField('Minutes', ['PerMins', 'permins']);
        addField('Reason', ['Remarks', 'remarks', 'Reason', 'reason']);
        break;
      case 'Advance':
      case 'AdvAdj':
      case 'AdvanceAdjustment':
        addField('Amount', ['Amount', 'Amount1', 'amount']);
        addField('Advance Amount', ['AdvAmount', 'advamount']);
        addField('Adjustment Amount', ['AdjAmount', 'adjamount']);
        addField('Salary Period', ['SalaryMonth', 'salarymonth']);
        addField('Deduction', ['DedName', 'dedname']);
        addField('Installment', ['InstAmt', 'instamt']);
        addField('No. of Inst.', ['NoOfInst', 'noofinst']);
        addField('Purpose', ['Purpose', 'purpose']);
        break;
      case 'Reimbursement':
        addField('Expense Type', ['EDName', 'edname']);
        addField('Amount', ['Amount', 'amount']);
        addField('Purpose', ['Purpose', 'purpose']);
        break;
      case 'AssetRequest':
      case 'AssetReturn':
        addField('Asset Group', ['AGroupName', 'agroupname']);
        addField('Asset Name', ['AssetName', 'assetname']);
        addField('Purpose', ['Purpose', 'purpose']);
        break;
      case 'ITFile':
        addField('Section', ['Section', 'section']);
        addField('Amount', ['Amount', 'amount']);
        addField('Remarks', ['Remarks', 'remarks']);
        break;
      case 'ShiftDeviation':
        addField('Group', ['GroupName', 'groupname']);
        addField('Deviated Shift', ['ShiftName', 'shiftname']);
        addField('Remarks', ['Remarks', 'remarks']);
        break;
      case 'ProfileChange':
        addField('Field Changed', ['FieldName', 'fieldname']);
        addField('Old Value', ['OldValue', 'oldvalue']);
        addField('New Value', ['NewValue', 'newvalue']);
        break;
    }

    // Add generic remarks if not captured by specific logic
    if (!fields.any((f) => f['label'] == 'Reason' || f['label'] == 'Remarks' || f['label'] == 'Employee Remarks')) {
       final remarks = _getDetailValue(['Remarks', 'Remarks1', 'remarks', 'Reason', 'reason', 'AppRemarks', 'AppRemarks1']);
       if (remarks != null && remarks != 'null') {
         fields.add({'label': 'Employee Remarks', 'value': remarks});
       }
    }

    // FALLBACK DIAGNOSTIC: If still empty, search all nested maps/lists for flat data
    if (fields.isEmpty && _details != null) {
      _extractAllFlatData(_details!, fields);
    }

    return fields;
  }

  String? _getDetailValue(List<String> keys) {
    if (_details == null) return null;
    return _findRecursive(_details, keys.map((k) => k.toLowerCase()).toList());
  }

  String? _findRecursive(dynamic data, List<String> lowerKeys) {
    if (data == null) return null;

    if (data is Map) {
      // 1. Check current level keys (case-insensitive)
      for (var entry in data.entries) {
        if (lowerKeys.contains(entry.key.toString().toLowerCase())) {
          final val = entry.value?.toString().trim();
          if (val != null && val.isNotEmpty && val != 'null' && !val.contains('? string:')) {
            return val;
          }
        }
      }

      // 2. Check in common detail lists specifically
      for (var listKey in ['dtList', 'dtLapp', 'dtLApp', 'dt', 'dt1', 'dtLDetail']) {
        if (data.containsKey(listKey) || data.containsKey(listKey.toLowerCase())) {
          final list = data[listKey] ?? data[listKey.toLowerCase()];
          if (list is List && list.isNotEmpty) {
            for (var item in list) {
              final val = _findRecursive(item, lowerKeys);
              if (val != null) return val;
            }
          }
        }
      }

      // 3. Recursive search in other maps/lists (limited depth or broad search)
      for (var value in data.values) {
        if (value is Map || value is List) {
          final val = _findRecursive(value, lowerKeys);
          if (val != null) return val;
        }
      }
    } else if (data is List) {
      for (var item in data) {
        final val = _findRecursive(item, lowerKeys);
        if (val != null) return val;
      }
    }
    return null;
  }

  void _extractAllFlatData(dynamic data, List<Map<String, String>> fields) {
    if (data is Map) {
      data.forEach((key, value) {
        if (value != null && value is! List && value is! Map) {
          final sVal = value.toString().trim();
          if (sVal.isNotEmpty && sVal != 'null' && !key.toLowerCase().contains('id') && 
              !fields.any((f) => f['label'] == key)) {
            fields.add({'label': key, 'value': sVal});
          }
        } else if (value is Map || value is List) {
          _extractAllFlatData(value, fields);
        }
      });
    } else if (data is List) {
      // For lists, usually only the first item has the relevant details for a detail screen
      if (data.isNotEmpty) {
        _extractAllFlatData(data[0], fields);
      }
    }
  }

  Widget _buildExtraInfoSection() {
    if (_details == null) return const SizedBox.shrink();

    // Punch Times - try multiple keys for robustness
    final sin = _getDetailValue(['SIn', 'SIn1', 'SInTime', 'In1', 'In', 'sin', 'sin1', 'sintime', 'in1', 'in']) ?? '';
    final lout = _getDetailValue(['LOut', 'LOut1', 'LOutTime', 'LunchOut1', 'LunchOut', 'lout', 'lout1', 'louttime', 'lunchout']) ?? '';
    final lin = _getDetailValue(['LIn', 'LIn1', 'LInTime', 'LunchIn1', 'LunchIn', 'lin', 'lin1', 'lintime', 'lunchin']) ?? '';
    final sout = _getDetailValue(['SOut', 'SOut1', 'SOutTime', 'Out1', 'Out', 'sout', 'sout1', 'souttime', 'out1', 'out']) ?? '';

    bool hasPunch = sin.isNotEmpty || lout.isNotEmpty || lin.isNotEmpty || sout.isNotEmpty;

    // Table Data - Try all common dt keys safely
    final dynamic rawDt1 = _details!['dt1'] ?? _details!['dtAbs'] ?? _details!['dtabs'];
    List<dynamic> dt1 = rawDt1 is List ? rawDt1 : [];
    
    final dynamic rawDt2 = _details!['dt2'] ?? _details!['dtAbs1'] ?? _details!['dtabs1'];
    List<dynamic> dt2 = rawDt2 is List ? rawDt2 : [];
    
    // Fallback logic for tables
    if (dt1.isEmpty) {
      for (var k in ['dt', 'dtList', 'dtLapp', 'dtLApp']) {
        final dynamic dt = _details![k] ?? _details![k.toLowerCase()];
        if (dt is List && dt.length > 1) {
          dt1 = dt; // Likely a balance table if more than 1 record
          break;
        }
      }
    }

    if (dt1.isEmpty && dt2.isNotEmpty) {
      dt1 = dt2;
      dt2 = [];
    }

    if (dt1.isEmpty && _leaveBalances.isNotEmpty) {
      dt1 = _leaveBalances;
    }

    bool hasTable = dt1.isNotEmpty || dt2.isNotEmpty;

    if (!hasPunch && !hasTable) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasPunch) ...[
          const Text(
            'Attendance Punch Details',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPunchItem('In', sin),
                _buildPunchItem('Lunch Out', lout),
                _buildPunchItem('Lunch In', lin),
                _buildPunchItem('Out', sout),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (hasTable) ...[
          const Text(
            'Leave Balance Details',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          _buildBalanceTable(
            '',
            dt1,
            ['LEAVE', 'OPENING', 'CREDIT', 'LAPS', 'TAKEN', 'PENDING', 'CLOSING'],
            ['Status', 'OB', 'Entitle', 'Laps', 'Taken', 'Pending', 'Balance'],
          ),
        ],
      ],
    );
  }

  Widget _buildBalanceTable(String title, List<dynamic> data, List<String> headers, List<String> keys) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
            ),
          ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 32),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.2),
                4: FlexColumnWidth(1.2),
                5: FlexColumnWidth(1.2),
                6: FlexColumnWidth(1.2),
              },
              border: TableBorder.all(color: Colors.grey.shade300),
              children: [
                // Header
                TableRow(
                  decoration: BoxDecoration(color: const Color(0xFFF5F7FA)),
                  children: headers.map((h) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    child: Text(
                      h.toUpperCase(), 
                      textAlign: TextAlign.center, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1A335E))
                    ),
                  )).toList(),
                ),
                // Data
                ...data.map((item) {
                  return TableRow(
                    children: keys.map((k) {
                  // Map display keys to possible API response keys (case-insensitive checks)
                  final searchKeys = [
                    k, k.toLowerCase(), k.toUpperCase(),
                    if (k == 'OB') ...['YearOpen', 'yearopen', 'Opening', 'opening', 'OPENING'],
                    if (k == 'Entitle') ...['YearCredit', 'yearcredit', 'Credit', 'credit', 'CREDIT'],
                    if (k == 'Laps') ...['YearLaps', 'yearlaps', 'Laps', 'laps', 'LAPS'],
                    if (k == 'Taken') ...['YearTaken', 'yeartaken', 'Taken', 'taken', 'TAKEN'],
                    if (k == 'Balance') ...['YearBalance', 'yearbalance', 'Balance', 'balance', 'Closing', 'closing', 'Balance1', 'CLOSING'],
                    if (k == 'Pending') ...['Pending', 'pending', 'PENDING'],
                    if (k == 'Status' || k == 'LEAVE' || k == 'Leave') ...['Status', 'status', 'LeaveName', 'leavename', 'Leave', 'leave', 'LEAVE'],
                  ];
                  
                  dynamic value;
                  for (var key in searchKeys) {
                    if (item is Map && item.containsKey(key)) {
                      value = item[key];
                      break;
                    }
                  }
                  value ??= (k == 'Status' || k == 'LEAVE' || k == 'Leave' ? '-' : '0');
                  
                  bool isLeaveCol = k == 'Status' || k == 'LEAVE' || k == 'Leave';
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    child: Text(
                      value.toString(),
                      textAlign: isLeaveCol ? TextAlign.left : TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isLeaveCol ? FontWeight.bold : FontWeight.w500,
                        color: isLeaveCol ? Colors.black87 : Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    ),
  ],
);
  }

  Widget _buildPunchItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(
          value.isEmpty || value == 'null' ? '-' : value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade200, // Read-only background
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.transparent), // No border or subtle
          ),
          child: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : () => _processApproval('Rejected'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : () => _processApproval('Approved'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
      ],
    );
  }
}
