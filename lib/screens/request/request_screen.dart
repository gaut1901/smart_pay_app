import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../data/services/request_service.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  final RequestService _requestService = RequestService();
  Map<String, dynamic>? _rights;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRights();
  }

  Future<void> _loadRights() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rights = await _requestService.getRequestRights();
      setState(() {
        _rights = rights;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F9), // Matching legacy background
      appBar: AppBar(
        title: const Text('Request', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
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
                      ElevatedButton(
                        onPressed: _loadRights,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildRequestGrid(),
    );
  }

  Widget _buildRequestGrid() {
    if (_rights == null) return const SizedBox.shrink();

    final List<Map<String, dynamic>> items = [];

    if (_rights!['isProfile'] == true) {
      items.add({
        'title': 'Profile',
        'icon': Icons.person,
        'color': const Color(0xFF03C95A),
        'route': '/profile_edit',
      });
    }
    if (_rights!['isProfile'] == true) {
      items.add({
        'title': 'Wages Detail',
        'icon': Icons.account_balance_wallet,
        'color': const Color(0xFFFD3995),
        'route': '/wages_detail',
      });
    }
    if (_rights!['isAttn'] == true) {
      items.add({
        'title': 'Apply Leave',
        'icon': Icons.calendar_today,
        'color': const Color(0xFF1B84FF),
        'route': '/leave',
      });
    }
    if (_rights!['isLeaveGrant'] == true) {
      items.add({
        'title': 'Apply Leave Compensation',
        'icon': Icons.more_time,
        'color': const Color(0xFFFD3995),
        'route': '/leave_compensation',
      });
    }
    if (_rights!['isPermission'] == true) {
      items.add({
        'title': 'Permission Apply',
        'icon': Icons.history_toggle_off,
        'color': const Color(0xFFE70D0D),
        'route': '/permission_request',
      });
    }
    if (_rights!['isReim'] == true) {
      items.add({
        'title': 'Reimbursement',
        'icon': Icons.receipt_long,
        'color': const Color(0xFFE70D0D),
        'route': '/reimbursement',
      });
    }
    if (_rights!['isAdvance'] == true) {
      items.add({
        'title': 'Advance',
        'icon': Icons.payments,
        'color': const Color(0xFF3B7080),
        'route': '/advance',
      });
    }
    if (_rights!['isAdvAdj'] == true) {
      items.add({
        'title': 'Advance Adjustment',
        'icon': Icons.calculate,
        'color': const Color(0xFFAB47BC),
        'route': '/advance_adjustment',
      });
    }
    if (_rights!['isAsset'] == true) {
      items.add({
        'title': 'Asset Request',
        'icon': Icons.add_circle,
        'color': const Color(0xFF00C0EF),
        'route': '/asset_request',
      });
    }
    if (_rights!['isAssetRtn'] == true) {
      items.add({
        'title': 'Asset Return',
        'icon': Icons.undo,
        'color': const Color(0xFF00C0EF),
        'route': '/asset_return',
      });
    }
    if (_rights!['isITFile'] == true) {
      items.add({
        'title': 'Income Tax File',
        'icon': Icons.attach_money,
        'color': const Color(0xFF00C0EF),
        'route': '/it_file',
      });
    }
    if (_rights!['isShiftDev'] == true || _rights!['isShiftDeviation'] == true) {
      items.add({
        'title': 'Shift Deviation',
        'icon': Icons.schedule,
        'color': const Color(0xFFF39C12),
        'route': '/shift_deviation',
      });
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildRequestCard(
          context,
          item['title'],
          item['icon'],
          item['color'],
          item['route'],
        );
      },
    );
  }

  Widget _buildRequestCard(BuildContext context, String title, IconData icon, Color color, String route) {
    return InkWell(
      onTap: () {
        if (ModalRoute.of(context)?.settings.name != route) {
          Navigator.pushNamed(context, route);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
