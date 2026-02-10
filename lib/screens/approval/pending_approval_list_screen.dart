import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../data/services/approval_service.dart';
import 'approval_detail_screen.dart';

class PendingApprovalListScreen extends StatefulWidget {
  final String type;
  final String title;

  const PendingApprovalListScreen({
    super.key,
    required this.type,
    required this.title,
  });

  @override
  State<PendingApprovalListScreen> createState() => _PendingApprovalListScreenState();
}

class _PendingApprovalListScreenState extends State<PendingApprovalListScreen> {
  final ApprovalService _approvalService = ApprovalService();
  List<ApprovalRequest> _requests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final requests = await _approvalService.getPendingRequests(widget.type);
      if (mounted) {
        setState(() {
          _requests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _processApproval(ApprovalRequest request, String status) async {
    final remarksController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${status == 'Approved' ? 'Approve' : 'Reject'} Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employee: ${request.empName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Details: ${request.details}'),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                hintText: 'Enter remarks (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'Approved' ? Colors.green : Colors.red,
            ),
            child: Text(status, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() => _isLoading = true);
      try {
        // Fetch extra details if needed (like AppType, AppLevel)
        final details = await _approvalService.getRequestDetails(widget.type, request.id);
        
        Map<String, dynamic> extraData = {};
        if (details.containsKey('AppType')) extraData['AppType'] = details['AppType'];
        if (details.containsKey('AppLevel')) extraData['AppLevel'] = details['AppLevel'];
        if (details.containsKey('Amount')) extraData['Amount'] = details['Amount'];

        await _approvalService.submitApproval(
          type: widget.type,
          id: request.id,
          status: status,
          remarks: remarksController.text,
          extraData: extraData,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request $status successfully')));
          _loadRequests();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.title} Pending', style: const TextStyle(color: Colors.white, fontSize: 18)),
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
                      ElevatedButton(onPressed: _loadRequests, child: const Text('Retry')),
                    ],
                  ),
                )
              : _requests.isEmpty
                  ? const Center(child: Text('No pending requests'))
                  : RefreshIndicator(
                      onRefresh: _loadRequests,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _requests.length,
                        itemBuilder: (context, index) {
                          final request = _requests[index];
                          return _buildRequestCard(request);
                        },
                      ),
                    ),
    );
  }

  Widget _buildRequestCard(ApprovalRequest request) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ApprovalDetailScreen(
              type: widget.type,
              id: request.id,
              title: widget.title,
            ),
          ),
        ).then((refresh) {
          if (refresh == true) _loadRequests();
        });
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      request.empName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  Text(
                    'Tkt: ${request.ticketNo}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildInfoRow(Icons.calendar_today, 'Date', request.date),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.info_outline, 'Details', request.details),
              if (request.remarks.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(Icons.comment_outlined, 'Reason', request.remarks),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _processApproval(request, 'Rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _processApproval(request, 'Approved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark),
          ),
        ),
      ],
    );
  }
}
