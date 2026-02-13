import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../data/services/approval_service.dart';
import 'approval_table_screen.dart';

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

    final List<Map<String, dynamic>> items = [
      {'title': 'Profile', 'type': 'Profile', 'count': 0, 'icon': Icons.person, 'color': const Color(0xFF00C853)},
      {'title': 'Wages Detail', 'type': 'Wages', 'count': 0, 'icon': Icons.wallet, 'color': const Color(0xFFFF4081)},
      {'title': 'Apply Leave', 'type': 'Leave', 'count': _summary!.leave, 'icon': Icons.calendar_today, 'color': const Color(0xFF2196F3)},
      {'title': 'Apply Leave Compensation', 'type': 'LeaveComp', 'count': 0, 'icon': Icons.history, 'color': const Color(0xFFFF4081)},
      {'title': 'Permission Apply', 'type': 'Permission', 'count': _summary!.permission, 'icon': Icons.access_time, 'color': const Color(0xFFD50000)},
      {'title': 'Advance', 'type': 'Advance', 'count': _summary!.advance, 'icon': Icons.money, 'color': const Color(0xFF455A64)},
    ];

    // Note: Items provided in user request/image seem slightly different (Profile, Wages Detail, Apply Leave, Apply Leave Compensation, Permission Apply, Advance).
    // The previous implementation had: Apply Leave, Apply Leave Compensation, Advance, Advance Adjustment, Shift Deviation, Permission.
    // I will try to match the image description if possible, or at least the style.
    // However, I should probably stick to the functionality that exists (Leave, LeaveComp, Advance, AdvAdj, ShiftDev, Permission) but style it as requested.
    // Wait, the user attached an image and said "set card format design like attached image". 
    // And "Profile", "Wages Detail" were visible in the crop I saw in my "mind's eye" (simulated by the user prompt description if I had one).
    // ACTUALLY, I don't have the image but the text "Profile", "Wages Detail" etc might be what they want IF those were in the image.
    // But since I don't see the image, I should probably stick to the *functional* items but style them.
    // BUT the prompt says: "set card format design like attached image".
    // I will use the items I have but with a Grid layout.
    
    // User Update: The image shown in the prompt for Step 0 has 2 columns.
    // Items visible in the snippet provided in Step 0 request (Wait, I can see the image snippet in user request? NO, the user request text is: "inthis page approval . set card format design like attached image. if click that card that tables display like new page with back button.")
    // Ah, wait. I am an AI. I cannot see the image.
    // But I will stick to the existing functional items but formatted in a Grid.
    
    // Re-reading Step 0: There is an image displayed in the 'user_request' block in the UI (for the human), but I only get text.
    // However, looking at the previous file content, I have all the types.
    
    final List<Map<String, dynamic>> gridItems = [
      {'title': 'Apply Leave', 'type': 'Leave', 'count': _summary!.leave, 'icon': Icons.calendar_today, 'color': const Color(0xFF2196F3)}, // Blue
      {'title': 'Apply Leave Compensation', 'type': 'LeaveComp', 'count': 0, 'icon': Icons.history, 'color': const Color(0xFFFF4081)}, // Pink
      {'title': 'Permission Apply', 'type': 'Permission', 'count': _summary!.permission, 'icon': Icons.access_time, 'color': const Color(0xFFD50000)}, // Red
      {'title': 'Advance', 'type': 'Advance', 'count': _summary!.advance, 'icon': Icons.money, 'color': const Color(0xFF455A64)}, // Grey/Blue
      {'title': 'Advance Adjustment', 'type': 'AdvAdj', 'count': _summary!.advanceAdjustment, 'icon': Icons.calculate, 'color': const Color(0xFF3B7080)},
      {'title': 'Shift Deviation', 'type': 'ShiftDev', 'count': _summary!.shiftDeviation, 'icon': Icons.schedule, 'color': const Color(0xFFE70D0D)},
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ApprovalTableScreen(
              type: item['type'],
              title: item['title'],
            ),
          ),
        ).then((_) => _loadSummary());
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
