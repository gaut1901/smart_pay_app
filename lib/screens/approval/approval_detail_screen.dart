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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppStyles.modernCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Request Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                ...displayFields.map((field) => _buildDetailRow(field['label']!, field['value']!)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Approval Remarks',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _remarksController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter your remarks here...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 100), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
        ],
      ),
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

    // Common fields
    if (_details!.containsKey('EmpName')) fields.add({'label': 'Employee', 'value': _details!['EmpName'].toString()});
    if (_details!.containsKey('TicketNo')) fields.add({'label': 'Ticket No', 'value': _details!['TicketNo'].toString()});
    if (_details!.containsKey('SDate')) fields.add({'label': 'Request Date', 'value': _details!['SDate'].toString()});

    switch (widget.type) {
      case 'Attendance':
      case 'Leave':
        if (_details!.containsKey('FromDate')) fields.add({'label': 'From Date', 'value': _details!['FromDate'].toString()});
        if (_details!.containsKey('ToDate')) fields.add({'label': 'To Date', 'value': _details!['ToDate'].toString()});
        if (_details!.containsKey('Days')) fields.add({'label': 'Days', 'value': _details!['Days'].toString()});
        if (_details!.containsKey('Status')) fields.add({'label': 'Type', 'value': _details!['Status'].toString()});
        if (_details!.containsKey('LRName')) fields.add({'label': 'Reason', 'value': _details!['LRName'].toString()});
        break;
      case 'Permission':
        if (_details!.containsKey('FromTime')) fields.add({'label': 'From Time', 'value': _details!['FromTime'].toString()});
        if (_details!.containsKey('ToTime')) fields.add({'label': 'To Time', 'value': _details!['ToTime'].toString()});
        if (_details!.containsKey('LRName')) fields.add({'label': 'Reason', 'value': _details!['LRName'].toString()});
        break;
      case 'Advance':
      case 'AdvanceAdjustment':
        if (_details!.containsKey('Amount')) fields.add({'label': 'Amount', 'value': _details!['Amount'].toString()});
        if (_details!.containsKey('AdvAmount')) fields.add({'label': 'Advance Amount', 'value': _details!['AdvAmount'].toString()});
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

    if (_details!.containsKey('Remarks') && !fields.any((f) => f['label'] == 'Remarks')) {
      fields.add({'label': 'Employee Remarks', 'value': _details!['Remarks'].toString()});
    }

    return fields;
  }
}
