import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../data/services/approval_service.dart';

class ApprovalDetailScreen extends StatefulWidget {
  final String type;
  final String id;
  final String title;

  const ApprovalDetailScreen({
    super.key,
    required this.type,
    required this.id,
    required this.title,
  });

  @override
  State<ApprovalDetailScreen> createState() => _ApprovalDetailScreenState();
}

class _ApprovalDetailScreenState extends State<ApprovalDetailScreen> {
  final ApprovalService _approvalService = ApprovalService();
  final TextEditingController _remarksController = TextEditingController();
  Map<String, dynamic>? _details;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final details = await _approvalService.getRequestDetails(widget.type, widget.id);
      setState(() {
        _details = details;
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
      // Common extra fields used in legacy backend
      if (_details!.containsKey('AppType')) extraData['AppType'] = _details!['AppType'];
      if (_details!.containsKey('AppLevel')) extraData['AppLevel'] = _details!['AppLevel'];
      if (_details!.containsKey('Amount')) extraData['Amount'] = _details!['Amount'];
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadDetails, child: const Text('Retry')),
                    ],
                  ),
                )
              : _buildContent(),
      bottomNavigationBar: _isLoading || _error != null ? null : _buildBottomActions(),
    );
  }

  Widget _buildContent() {
    if (_details == null) return const Center(child: Text('No details found'));

    final List<Map<String, String>> displayFields = _getDisplayFields();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Render dynamic fields as read-only form
          ...displayFields.map((field) {
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

  List<Map<String, String>> _getDisplayFields() {
    if (_details == null) return [];

    final List<Map<String, String>> fields = [];

    // Helper to get value from multiple possible keys
    String? getValue(List<String> keys) {
      for (var key in keys) {
        if (_details!.containsKey(key) && _details![key] != null && _details![key].toString() != 'null') {
          return _details![key].toString();
        }
      }
      return null;
    }

    // Common fields
    String? empName = getValue(['EmpName1', 'EmpName']);
    if (empName != null) fields.add({'label': 'Employee', 'value': empName});
    
    String? ticketNo = getValue(['TicketNo1', 'TicketNo']);
    if (ticketNo != null) fields.add({'label': 'Ticket No', 'value': ticketNo});
    
    String? sDate = getValue(['SDate1', 'SDate']);
    if (sDate != null) fields.add({'label': 'Request Date', 'value': sDate});

    switch (widget.type) {
      case 'Attendance':
      case 'Leave':
        String? fDate = getValue(['FromDate1', 'FromDate']);
        if (fDate != null) fields.add({'label': 'From Date', 'value': fDate});
        
        String? tDate = getValue(['ToDate1', 'ToDate']);
        if (tDate != null) fields.add({'label': 'To Date', 'value': tDate});
        
        String? days = getValue(['Days', 'OldDays']); 
        if (days != null) fields.add({'label': 'Days', 'value': days});
        
        String? status = getValue(['Status1', 'Status', 'MStatus1', 'MStatus']);
        if (status != null) fields.add({'label': 'Leave Name', 'value': status});
        
        String? lrName = getValue(['Remarks1', 'Remarks', 'LRName']);
        if (lrName != null) fields.add({'label': 'Reason', 'value': lrName});
        break;
      case 'Permission':
        if (_details!.containsKey('FromTime')) fields.add({'label': 'From Time', 'value': _details!['FromTime'].toString()});
        if (_details!.containsKey('ToTime')) fields.add({'label': 'To Time', 'value': _details!['ToTime'].toString()});
        if (_details!.containsKey('LRName')) fields.add({'label': 'Reason', 'value': _details!['LRName'].toString()});
        break;
      case 'Advance':
      case 'AdvAdj':
      case 'AdvanceAdjustment':
        if (_details!.containsKey('Amount')) fields.add({'label': 'Amount', 'value': _details!['Amount'].toString()});
        if (_details!.containsKey('AdvAmount')) fields.add({'label': 'Advance Amount', 'value': _details!['AdvAmount'].toString()});
        if (_details!.containsKey('AdjAmount')) fields.add({'label': 'Adjustment Amount', 'value': _details!['AdjAmount'].toString()});
        if (_details!.containsKey('SalaryMonth')) fields.add({'label': 'Salary Period', 'value': _details!['SalaryMonth'].toString()});
        if (_details!.containsKey('DedName')) fields.add({'label': 'Deduction', 'value': _details!['DedName'].toString()});
        if (_details!.containsKey('InstAmt')) fields.add({'label': 'Installment', 'value': _details!['InstAmt'].toString()});
        if (_details!.containsKey('NoOfInst')) fields.add({'label': 'No. of Inst.', 'value': _details!['NoOfInst'].toString()});
        if (_details!.containsKey('Purpose')) fields.add({'label': 'Purpose', 'value': _details!['Purpose'].toString()});
        break;
      case 'Reimbursement':
        if (_details!.containsKey('EDName')) fields.add({'label': 'Expense Type', 'value': _details!['EDName'].toString()});
        if (_details!.containsKey('Amount')) fields.add({'label': 'Amount', 'value': _details!['Amount'].toString()});
        if (_details!.containsKey('Purpose')) fields.add({'label': 'Purpose', 'value': _details!['Purpose'].toString()});
        break;
      case 'AssetRequest':
      case 'AssetReturn':
        if (_details!.containsKey('AGroupName')) fields.add({'label': 'Asset Group', 'value': _details!['AGroupName'].toString()});
        if (_details!.containsKey('AssetName')) fields.add({'label': 'Asset Name', 'value': _details!['AssetName'].toString()});
        if (_details!.containsKey('Purpose')) fields.add({'label': 'Purpose', 'value': _details!['Purpose'].toString()});
        break;
      case 'ITFile':
        if (_details!.containsKey('Section')) fields.add({'label': 'Section', 'value': _details!['Section'].toString()});
        if (_details!.containsKey('Amount')) fields.add({'label': 'Amount', 'value': _details!['Amount'].toString()});
        if (_details!.containsKey('Remarks')) fields.add({'label': 'Remarks', 'value': _details!['Remarks'].toString()});
        break;
      case 'ShiftDeviation':
        if (_details!.containsKey('GroupName')) fields.add({'label': 'Group', 'value': _details!['GroupName'].toString()});
        if (_details!.containsKey('ShiftName')) fields.add({'label': 'Deviated Shift', 'value': _details!['ShiftName'].toString()});
        if (_details!.containsKey('Remarks')) fields.add({'label': 'Remarks', 'value': _details!['Remarks'].toString()});
        break;
      case 'ProfileChange':
        if (_details!.containsKey('FieldName')) fields.add({'label': 'Field Changed', 'value': _details!['FieldName'].toString()});
        if (_details!.containsKey('OldValue')) fields.add({'label': 'Old Value', 'value': _details!['OldValue'].toString()});
        if (_details!.containsKey('NewValue')) fields.add({'label': 'New Value', 'value': _details!['NewValue'].toString()});
        break;
    }

    // Add generic remarks if not captured by specific logic
    String? genericRemarks = getValue(['Remarks', 'Remarks1']);
    // Avoid duplicate Reason/Remarks if handled above
    bool alreadyHasReason = fields.any((f) => f['label'] == 'Reason' || f['label'] == 'Remarks');
    if (!alreadyHasReason && genericRemarks != null) {
       fields.add({'label': 'Employee Remarks', 'value': genericRemarks});
    }

    return fields;
  }
}
