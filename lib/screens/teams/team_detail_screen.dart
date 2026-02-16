import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:smartpay_flutter/widgets/main_drawer.dart';
import '../../core/constants.dart';
import '../../data/models/team_model.dart';
import '../../data/services/team_service.dart';
import '../../data/services/auth_service.dart';
import '../../widgets/custom_app_header.dart';
import '../approval/approval_list_screen.dart';

class TeamDetailScreen extends StatefulWidget {
  final String empCode;
  final TeamMember? member;

  const TeamDetailScreen({super.key, required this.empCode, this.member});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  final TeamService _teamService = TeamService();
  TeamMember? _member;
  TeamMemberApprovals? _approvals;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Set the member emp code globally to "act as" this member for child screens
    AuthService.memberEmpCode = widget.empCode;
    AuthService.memberName = widget.member?.empName ?? "";
    
    if (widget.member != null) {
      _member = widget.member;
      // We still want to load approvals, but we can show the member info immediately
      _loadApprovalsOnly();
    } else {
      _loadTeamMemberDetails();
    }
  }

  @override
  void dispose() {
    // Reset the member emp code when leaving the detail screen
    AuthService.memberEmpCode = "0";
    AuthService.memberName = "";
    super.dispose();
  }

  Future<void> _loadApprovalsOnly() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final approvals = await _teamService.getTeamMemberApprovals(widget.empCode);
      setState(() {
        _approvals = approvals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTeamMemberDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final member = await _teamService.getTeamMemberDetails(widget.empCode);
      final approvals = await _teamService.getTeamMemberApprovals(widget.empCode);
      
      setState(() {
        _member = member;
        _approvals = approvals;
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
    final user = AuthService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppHeader(
        title: '', // Show logo only as requested
        user: user,
        actions: const [], // Remove profile icon from app bar actions
      ),
      drawer: const MainDrawer(),
      body: _isLoading && _member == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _member == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTeamMemberDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _member == null
                  ? const Center(child: Text('Team member not found'))
                  : RefreshIndicator(
                      onRefresh: _loadTeamMemberDetails,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProfileHeader(),
                            _buildActionButtons(),
                            _buildRequestsSection(),
                            _buildApprovalsSection(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
      ),
      child: Column(
        children: [
          // Profile Photo removed as requested
          const SizedBox(height: 8),
          // Name and Code
          Text(
            _member!.displayName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _member!.empCode,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 20),
          // Info Cards
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              if (_member!.deptName != null && _member!.deptName!.isNotEmpty)
                _buildInfoCard('Department', _member!.deptName!),
              if (_member!.desName != null && _member!.desName!.isNotEmpty)
                _buildInfoCard('Designation', _member!.desName!),
              if (_member!.locName != null && _member!.locName!.isNotEmpty)
                _buildInfoCard('Location', _member!.locName!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      width: (MediaQuery.of(context).size.width - 64) / 2, // Half width minus margins/spacing
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/attendance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text(
                'Attendance History',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/leave'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text(
                'Leave Balance',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 20, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Requests',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildRequestCard('Apply Leave', Icons.calendar_today, const Color(0xFF03C95A), '/leave'),
              _buildRequestCard('Leave Compensation', Icons.calendar_month, const Color(0xFF1B84FF), '/leave_compensation'),
              _buildRequestCard('Permission', Icons.access_time, Colors.orange, '/permission_request'),
              _buildRequestCard('Reimbursement', Icons.receipt_long, const Color(0xFFE70D0D), '/reimbursement'),
              _buildRequestCard('Advance', Icons.attach_money, const Color(0xFF3B7080), '/advance'),
              _buildRequestCard('Advance Adjustment', Icons.calculate, const Color(0xFF3B7080), '/advance_adjustment'),
              _buildRequestCard('Asset Request', Icons.add_circle_outline, const Color(0xFF00c0ef), '/asset_request'),
              _buildRequestCard('Asset Return', Icons.undo, const Color(0xFF00c0ef), '/asset_return'),
              _buildRequestCard('Shift Deviation', Icons.schedule, const Color(0xFF00c0ef), '/shift_deviation'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(String title, IconData icon, Color color, String route) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalsSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 20, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Approvals',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 16),
          if (_isLoading && _approvals == null)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
          if (!_isLoading || _approvals != null)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildApprovalCard('Apply Leave', Icons.calendar_today, const Color(0xFF03C95A), _approvals?.attnReq ?? 0, 'Leave'),
                _buildApprovalCard('Leave Compensation', Icons.calendar_month, const Color(0xFF1B84FF), _approvals?.lgReq ?? 0, 'LeaveComp'),
                _buildApprovalCard('Advance', Icons.attach_money, const Color(0xFF3B7080), _approvals?.advReq ?? 0, 'Advance'),
                _buildApprovalCard('Advance Adjustment', Icons.calculate, const Color(0xFF3B7080), _approvals?.aarReq ?? 0, 'AdvAdj'),
                _buildApprovalCard('Permission', Icons.access_time, const Color(0xFFE70D0D), _approvals?.permissionReq ?? 0, 'Permission'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(String title, IconData icon, Color color, int count, String type) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ApprovalListScreen(
              type: type,
              title: title,
            ),
          ),
        ).then((_) => _loadApprovalsOnly());
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (count > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
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
