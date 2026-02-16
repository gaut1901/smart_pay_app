import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../data/services/approval_service.dart';
import 'approval_list_screen.dart';
import 'shift_deviation_approval_screen.dart';

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
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Approvals', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSummary),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : RefreshIndicator(
            onRefresh: _loadSummary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildGridCards(),
              ),
            ),
          ),
    );
  }

  Widget _buildGridCards() {
    if (_summary == null) return const SizedBox.shrink();

    final List<Map<String, dynamic>> gridItems = [
      {'title': 'Apply Leave', 'type': 'Leave', 'count': _summary!.leave, 'icon': Icons.calendar_today, 'color': const Color(0xFF00C853)},
      {'title': 'Apply Leave Compensation', 'type': 'LeaveComp', 'count': 0, 'icon': Icons.history, 'color': const Color(0xFF2196F3)},
      {'title': 'Advance', 'type': 'Advance', 'count': _summary!.advance, 'icon': Icons.money, 'color': const Color(0xFFFF4081)},
      {'title': 'Advance Adjustment', 'type': 'AdvAdj', 'count': _summary!.advanceAdjustment, 'icon': Icons.calculate, 'color': const Color(0xFF3B7080)},
      {'title': 'Shift Deviation', 'type': 'ShiftDev', 'count': _summary!.shiftDeviation, 'icon': Icons.schedule, 'color': const Color(0xFFD50000)},
      {'title': 'Permission', 'type': 'Permission', 'count': _summary!.permission, 'icon': Icons.access_time, 'color': const Color(0xFFD50000)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1, // Adjust for square-ish look
      ),
      itemCount: gridItems.length,
      itemBuilder: (context, index) {
        final item = gridItems[index];
        return _buildCard(item);
      },
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        if (item['type'] == 'ShiftDev') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShiftDeviationApprovalScreen(
                type: item['type'],
                title: item['title'],
              ),
            ),
          ).then((_) => _loadSummary());
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ApprovalListScreen(
                type: item['type'],
                title: item['title'],
              ),
            ),
          ).then((_) => _loadSummary());
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: item['color'],
                shape: BoxShape.circle,
              ),
              child: Icon(
                item['icon'],
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                item['title'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (item['count'] > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${item['count']} Pending',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
