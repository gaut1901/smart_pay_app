import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smartpay_flutter/core/ui_constants.dart';
import '../../core/constants.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/dashboard_service.dart';
import '../../data/services/attendance_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  final AttendanceService _attendanceService = AttendanceService();
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _handlePunchAction(bool isPunchedIn) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      Map<String, dynamic> responseData;
      if (isPunchedIn) {
        responseData = await _attendanceService.punchOut();
      } else {
        responseData = await _attendanceService.punchIn();
      }
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Update local state immediately with response data
        setState(() {
          if (_dashboardData != null) {
            _dashboardData!['CheckIn'] = responseData['CheckIn'];
            _dashboardData!['CheckOut'] = responseData['CheckOut'];
            _dashboardData!['WorkedHours'] = responseData['WorkedHours'];
            _dashboardData!['TotalHours'] = responseData['TotalHours'];
            _dashboardData!['AttnIn'] = responseData['AttnIn'];
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isPunchedIn ? 'Punched out successfully' : 'Punched in successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _dashboardService.getDashboardData(DateTime.now());
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        if (errorMsg.contains('User not logged in')) {
          // Clear session and redirect to login
          AuthService().logout();
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          return;
        }
        
        setState(() {
          _error = errorMsg;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: SvgPicture.asset(
          'assets/images/logo.svg',
          height: 30,
          color: Colors.white,
        ),
        centerTitle: true,
        elevation: 0,
      ),
      drawer: _buildDrawer(context, user),
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
                        onPressed: _loadDashboardData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildProfileSection(context, _dashboardData?['dt_Emp']?[0]),
                        _buildLeaveDetailsRow(context, _dashboardData),
                        _buildAttendanceSection(context, _dashboardData),
                        _buildWorkHoursSection(_dashboardData),
                        _buildPercentagesSection(_dashboardData),
                        _buildTeamAndApprovalsSection(_dashboardData),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildDrawer(BuildContext context, user) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SvgPicture.asset(
              'assets/images/logo.svg',
              height: 60,
              alignment: Alignment.centerLeft,
            ),
          ),
          const SizedBox(height: 40),
          _buildDrawerItem(
            context,
            icon: Icons.list,
            title: 'Dashboard',
            onTap: () => Navigator.pop(context),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.groups,
            title: 'Teams',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/teams');
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.edit_note,
            title: 'Requests',
            titleColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/request');
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 72),
            child: ListTile(
              title: const Text(
                'IT File',
                style: TextStyle(
                  fontSize: UIConstants.fontSizePageTitle,
                  color: AppColors.textGray,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/it_file');
              },
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.check_circle_outline,
            title: 'Approvals',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/approval');
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.history,
            title: 'Attendance History',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/attendance');
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.leaderboard_outlined,
            title: 'Leave Balance',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/leave');
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.description_outlined,
            title: 'PaySlip',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/payslips');
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.list,
            title: 'Shift Schedule',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/shift');
            },
          ),
          // _buildDrawerItem(
          //   context,
          //   icon: Icons.lock_outline,
          //   title: 'Change Password',
          //   onTap: () {
          //     Navigator.pop(context);
          //     Navigator.pushNamed(context, '/change_password');
          //   },
          // ),
          const SizedBox(height: 20),
          const Divider(),
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              AuthService().logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? AppColors.textGray,
        size: 28,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: UIConstants.fontSizePageTitle,
          fontWeight: FontWeight.w500,
          color: titleColor ?? AppColors.textGray,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  Widget _buildProfileSection(BuildContext context, Map<String, dynamic>? emp) {
    if (emp == null) return const SizedBox.shrink();
    
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/profile'),
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2EADC), // Light gold/cream background
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.accent, // Gold header
                borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(emp['EmpName'] ?? '', style: TextStyle(color: Colors.white, fontSize: UIConstants.fontSizePageTitle, fontWeight: FontWeight.bold)),
                  Text('${emp['DesName'] ?? ''} | ${emp['DeptName'] ?? ''}', style: TextStyle(color: Colors.white, fontSize: UIConstants.fontSizeSmall)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  _buildProfileInfoItem('EmpCode', (emp['EmpCode'] ?? emp['Empcode'])?.toString() ?? ''),
                  _buildProfileInfoItem('LocName', emp['LocName'] ?? ''),
                  _buildProfileInfoItem('Report Person Name', emp['Report_Person_Name'] ?? ''),
                  _buildProfileInfoItem('PayGroup', emp['PayGroup'] ?? ''),
                  _buildProfileInfoItem('MobileNo', emp['MobileNo'] ?? ''),
                  _buildProfileInfoItem('EMail', (emp['Office_Mail'] == null || emp['Office_Mail'] == 'NONE') ? (emp['Personal_Mail'] ?? '') : emp['Office_Mail']),
                  _buildProfileInfoItem('Date of Joining', emp['DOJ'] ?? ''),
                  _buildProfileInfoItem('Date of Birth', emp['DOB'] ?? ''),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(fontSize: UIConstants.fontSizeSmall, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        Text(label, style: TextStyle(fontSize: UIConstants.fontSizeTiny, color: Color(0xFF6B7280))),
      ],
    );
  }

  Widget _buildLeaveDetailsRow(BuildContext context, Map<String, dynamic>? data) {
    if (data == null) return const SizedBox.shrink();

    return Column(
      children: [
        _buildAttendanceSummarySection(context, data['dtAttn']?[0]),
        _buildDashboardLeaveSection(context, data),
      ],
    );
  }

  Widget _buildAttendanceSummarySection(BuildContext context, Map<String, dynamic>? attn) {
    if (attn == null) return const SizedBox.shrink();

    // Map the keys from API to UI labels
    final items = [
      {'label': 'Work', 'value': attn['Work']?.toString() ?? '0', 'color': const Color(0xFFF0C32A)},
      {'label': 'Absent', 'value': attn['Absent']?.toString() ?? '0', 'color': const Color(0xFF387386)},
      {'label': 'Leave', 'value': attn['Leave']?.toString() ?? '0', 'color': const Color(0xFFC71A2A)},
      {'label': 'LateDays', 'value': attn['LateDays']?.toString() ?? '0', 'color': const Color(0xFFFD3998)},
      {'label': 'OntimeDays', 'value': attn['OntimeDays']?.toString() ?? '0', 'color': const Color(0xFF01CA5C)},
    ];

    return _buildCard('Monthly Status', Column(
      children: [
        ...items.map((item) => _buildLeaveItem(item['label'] as String, item['value'] as String, item['color'] as Color)),
      ],
    ));
  }

  Widget _buildDashboardLeaveSection(BuildContext context, Map<String, dynamic>? dashboard) {
    if (dashboard == null) return const SizedBox.shrink();

    final items = [
      {'label': 'Total Leaves', 'value': dashboard['TotalLeaves']?.toString() ?? '0', 'color': const Color(0xFFF0C32A)},
      {'label': 'Taken', 'value': dashboard['LeaveTaken']?.toString() ?? '0', 'color': const Color(0xFF387386)},
      {'label': 'Request', 'value': dashboard['LeaveRequest']?.toString() ?? '0', 'color': const Color(0xFFC71A2A)},
      {'label': 'Worked Days', 'value': dashboard['WorkedDays']?.toString() ?? '0', 'color': const Color(0xFFFD3998)},
      {'label': 'Loss of Pay', 'value': dashboard['LopDays']?.toString() ?? '0', 'color': const Color(0xFF01CA5C)},
    ];

    return _buildCard('Leave Details', Column(
      children: [
        ...items.map((item) => _buildLeaveItem(item['label'] as String, item['value'] as String, item['color'] as Color)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/leave'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent, // Use gold for Apply
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              elevation: 0,
            ),
            child: Text('Apply', style: TextStyle(color: Colors.white, fontSize: UIConstants.fontSizeBody, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    ));
  }

  Widget _buildLeaveItem(String label, String value, Color bgColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(label, style: TextStyle(fontSize: UIConstants.fontSizeBody, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value, 
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: UIConstants.fontSizeSectionHeader, color: Color(0xFF1F2937))
            ),
          ),
        ],
      ),
    );
  }

  String _formatProduction(String? value) {
    if (value == null || value.isEmpty || value == '0:00') return '0 hrs 00 mins';
    final parts = value.split(':');
    if (parts.length != 2) return value;
    final hrs = int.tryParse(parts[0]) ?? 0;
    final mins = int.tryParse(parts[1]) ?? 0;
    return '$hrs hrs ${mins.toString().padLeft(2, '0')} mins';
  }

  Widget _buildAttendanceSection(BuildContext context, Map<String, dynamic>? data) {
    final checkIn = data?['CheckIn']?.toString() ?? '--:--';
    final checkOut = data?['CheckOut']?.toString() ?? '--:--';
    final attnIn = data?['AttnIn']?.toString() ?? '';
    
    // Determine if user is currently punched in
    final bool hasPunchedIn = checkIn != '--:--' && checkIn != '12:00 AM';
    final bool hasPunchedOut = checkOut != '--:--' && checkOut != '12:00 AM';
    
    final bool isPunchedIn = hasPunchedIn && !hasPunchedOut;
    final String buttonText = isPunchedIn ? 'Punch Out' : 'Punch In';
    final Color buttonColor = const Color(0xFFF26522); // Exact Orange from web screenshot

    return _buildCard('Attendance', Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Hours', style: TextStyle(fontSize: UIConstants.fontSizeSmall, color: Colors.grey)),
            if (attnIn.isNotEmpty) Text(attnIn, style: TextStyle(fontSize: UIConstants.fontSizeSmall, color: Colors.grey)),
          ],
        ),
        Text('${data?['TotalHours'] ?? '0:00'} hrs', style: TextStyle(fontSize: UIConstants.fontSizeSmall, color: Colors.grey)),
        const SizedBox(height: 80), 
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF212529),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Production : ${_formatProduction(data?['WorkedHours'])}',
            style: TextStyle(color: Colors.white, fontSize: UIConstants.fontSizeTiny, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.login, size: 14, color: Colors.black),
            Text(
              isPunchedIn ? ' Punch In at $checkIn' : ' Not Punched In',
              style: TextStyle(fontSize: UIConstants.fontSizeSmall, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 40,
          child: ElevatedButton(
            onPressed: () => _handlePunchAction(isPunchedIn),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              elevation: 0,
            ),
            child: Text(buttonText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    ));
  }

  Widget _buildWorkHoursSection(Map<String, dynamic>? data) {
    if (data == null) return const SizedBox.shrink();

    final items = [
      {
        'title': 'Total Hours Today',
        'value': '${data['Day_Worked_Hrs'] ?? '0:00'} / ${data['Day_Shift_Hrs'] ?? '0:00'}',
        'color': AppColors.chartColors[7] // Orange
      },
      {
        'title': 'Total Hours Month',
        'value': '${data['Month_Worked_Hrs'] ?? '0:00'} / ${data['Month_Shift_Hrs'] ?? '0:00'}',
        'color': AppColors.chartColors[1] // Slate
      },
      {
        'title': 'Total Hours Week',
        'value': '${data['Week_Worked_Hrs'] ?? '0:00'} / ${data['Week_Shift_Hrs'] ?? '0:00'}',
        'color': AppColors.chartColors[5] // Blue
      },
      {
        'title': 'Total Hours Break',
        'value': '${data['Day_Break_Hrs'] ?? '0:00'} / ${data['Day_Total_Hrs'] ?? '0:00'}',
        'color': AppColors.chartColors[3] // Pink
      },
      {
        'title': 'Total Hours OT',
        'value': '${data['Day_OT_Hrs'] ?? '0:00'} / ${data['Month_OT_Hrs'] ?? '0:00'}',
        'color': AppColors.chartColors[6] // Purple
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: items.map((item) {
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 48) / 2, // 2 items per row with padding
                height: 90,
                child: _buildWorkHrCard(
                  item['title'] as String,
                  item['value'] as String,
                  item['color'] as Color,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkHrCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value == '0:00 / 0:00' ? '0 / 0' : value, 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: UIConstants.fontSizePageTitle)
          ),
          Text(title, style: TextStyle(fontSize: UIConstants.fontSizeTiny, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPercentagesSection(Map<String, dynamic>? data) {
    if (data == null) return const SizedBox.shrink();

    final dayPct = double.tryParse(data['Day_Percentage']?.toString() ?? '0') ?? 0;
    final monthPct = double.tryParse(data['Month_Percentage']?.toString() ?? '0') ?? 0;
    final weekPct = double.tryParse(data['Week_Percentage']?.toString() ?? '0') ?? 0;
    final otPct = double.tryParse(data['OT_Percentage']?.toString() ?? '0') ?? 0;

    final total = dayPct + monthPct + weekPct + otPct;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildPercentageItemWrapper(context, 'Day Percentage', dayPct, AppColors.chartColors[0]),
              _buildPercentageItemWrapper(context, 'Month Percentage', monthPct, AppColors.chartColors[1]),
              _buildPercentageItemWrapper(context, 'Week Percentage', weekPct, AppColors.chartColors[2]),
              _buildPercentageItemWrapper(context, 'OT Percentage', otPct, AppColors.chartColors[3]),
            ],
          ),
          const SizedBox(height: 16),
          // Stacked progress bar
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE9ECEF),
              borderRadius: BorderRadius.circular(2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Row(
                children: [
                  if (dayPct > 0) Expanded(flex: dayPct.toInt(), child: Container(color: AppColors.chartColors[0])),
                  if (monthPct > 0) Expanded(flex: monthPct.toInt(), child: Container(color: AppColors.chartColors[1])),
                  if (weekPct > 0) Expanded(flex: weekPct.toInt(), child: Container(color: AppColors.chartColors[2])),
                  if (otPct > 0) Expanded(flex: otPct.toInt(), child: Container(color: AppColors.chartColors[3])),
                  if (total < 100) Expanded(flex: (100 - total).toInt(), child: const SizedBox.shrink()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageItemWrapper(BuildContext context, String title, double value, Color color) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 48) / 2,
      height: 90,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10, 
                  height: 10, 
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))
                ),
              ],
            ),
            const Spacer(),
            Text('${value.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: UIConstants.fontSizePageTitle)),
            Text(title, style: TextStyle(fontSize: UIConstants.fontSizeTiny, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamAndApprovalsSection(Map<String, dynamic>? data) {
    final team = (data?['dtTeam'] as List?) ?? [];
    final limitedTeam = team.take(5).toList();
    final approvals = (data?['dtApproval'] as List?) ?? [];

    return Column(
      children: [
        if (team.isNotEmpty)
          _buildCard(
            'Team Members',
            Column(
              children: List.generate(limitedTeam.length, (index) {
                final member = limitedTeam[index];
                final Color color = AppColors.chartColors[index % AppColors.chartColors.length];
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.1),
                    child: Icon(Icons.person, color: color),
                  ),
                  title: Text(member['EmpName'] ?? '', style: TextStyle(fontSize: UIConstants.fontSizeBody, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member['DesName'] ?? '', style: TextStyle(fontSize: UIConstants.fontSizeSmall)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          member['DeptName'] ?? '', 
                          style: TextStyle(fontSize: UIConstants.fontSizeTiny, color: color, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            trailing: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/teams'),
              child: Text('View All', style: TextStyle(fontSize: UIConstants.fontSizeSmall)),
            ),
          ),
        if (approvals.isNotEmpty)
          _buildCard(
            'Approvals',
            Column(
              children: approvals.map((approval) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_outlined, size: 18, color: AppColors.error),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(approval['ReqType'] ?? 'Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: UIConstants.fontSizeBody)),
                        Text(approval['Status'] ?? '', style: TextStyle(fontSize: UIConstants.fontSizeSmall, color: Colors.grey)),
                      ],
                    )),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/approval'), 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, 
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        minimumSize: const Size(60, 30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ), 
                      child: Text('View', style: TextStyle(color: Colors.white, fontSize: UIConstants.fontSizeTiny))
                    ),
                  ],
                ),
              )).toList(),
            ),
            trailing: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/approval'),
              child: Text('View All', style: TextStyle(fontSize: UIConstants.fontSizeSmall)),
            ),
          ),
      ],
    );
  }

  Widget _buildCard(String title, Widget content, {Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontSize: UIConstants.fontSizeSectionHeader, fontWeight: FontWeight.bold)),
                if (trailing != null) trailing,
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: content,
          ),
        ],
      ),
    );
  }
}
