import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../data/services/approval_service.dart';
import 'pending_approval_list_screen.dart';

class ApprovalScreen extends StatefulWidget {
  const ApprovalScreen({super.key});

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  final ApprovalService _approvalService = ApprovalService();
  ApprovalSummary? _summary;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final summary = await _approvalService.getApprovalSummary();
      if (mounted) {
        setState(() {
          _summary = summary;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Approvals', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSummary,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadSummary, child: const Text('Retry')),
                      ],
                    ),
                  )
                : _buildApprovalGrid(),
      ),
    );
  }

  Widget _buildApprovalGrid() {
    if (_summary == null) return const SizedBox.shrink();

    final List<Map<String, dynamic>> items = [
      {'title': 'Attendance', 'type': 'Attendance', 'count': _summary!.attendance, 'icon': Icons.check_circle_outline, 'color': const Color(0xFFF26522)},
      {'title': 'Leave', 'type': 'Leave', 'count': _summary!.leave, 'icon': Icons.calendar_today, 'color': const Color(0xFF3B7080)},
      {'title': 'Permission', 'type': 'Permission', 'count': _summary!.permission, 'icon': Icons.history_toggle_off, 'color': const Color(0xFF3B7080)},
      {'title': 'Advance', 'type': 'Advance', 'count': _summary!.advance, 'icon': Icons.payments, 'color': const Color(0xFF1B84FF)},
      {'title': 'Adv. Adjustment', 'type': 'AdvanceAdjustment', 'count': _summary!.advanceAdjustment, 'icon': Icons.calculate, 'color': const Color(0xFFFD3995)},
      {'title': 'Reimbursement', 'type': 'Reimbursement', 'count': _summary!.reimbursement, 'icon': Icons.receipt_long, 'color': const Color(0xFFAB47BC)},
      {'title': 'Asset Request', 'type': 'AssetRequest', 'count': _summary!.assetRequest, 'icon': Icons.devices, 'color': const Color(0xFF00C0EF)},
      {'title': 'Asset Return', 'type': 'AssetReturn', 'count': _summary!.assetReturn, 'icon': Icons.undo, 'color': const Color(0xFF00C0EF)},
      {'title': 'Shift Deviation', 'type': 'ShiftDeviation', 'count': _summary!.shiftDeviation, 'icon': Icons.schedule, 'color': const Color(0xFFF39C12)},
      {'title': 'Income Tax File', 'type': 'ITFile', 'count': _summary!.itFile, 'icon': Icons.attach_money, 'color': const Color(0xFF00A65A)},
      {'title': 'Profile Change', 'type': 'ProfileChange', 'count': _summary!.profileChange, 'icon': Icons.person_search, 'color': const Color(0xFF605CA8)},
    ];

    // Only show items where count > 0 or all items? 
    // Usually managers want to see everything that is pending.
    final pendingItems = items.where((item) => item['count'] > 0).toList();

    if (pendingItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('No pending approvals', style: TextStyle(fontSize: 16, color: AppColors.textGray)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: pendingItems.length,
      itemBuilder: (context, index) {
        final item = pendingItems[index];
        return _buildApprovalCard(item);
      },
    );
  }

  Widget _buildApprovalCard(Map<String, dynamic> item) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PendingApprovalListScreen(
              type: item['type'],
              title: item['title'],
            ),
          ),
        ).then((_) => _loadSummary());
      },
      child: Container(
        decoration: AppStyles.modernCardDecoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item['color'],
                shape: BoxShape.circle,
              ),
              child: Icon(item['icon'], color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              '${item['count']}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            Text(
              item['title'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textGray),
            ),
          ],
        ),
      ),
    );
  }
}
