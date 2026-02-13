import 'package:flutter/material.dart';
import 'screens/login/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/leave/leave_management_screen.dart';
import 'screens/leave/leave_compensation_screen.dart';
import 'screens/attendance/attendance_screen.dart';
import 'screens/payslips/payslip_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/profile_edit_screen.dart';
import 'screens/profile/wages_detail_screen.dart';
import 'screens/shift/shift_screen.dart';
import 'screens/request/request_screen.dart';
import 'screens/permission/permission_request_screen.dart';
import 'screens/reimbursement/reimbursement_screen.dart';
import 'screens/advance/advance_request_screen.dart';
import 'screens/advance/advance_adjustment_screen.dart';
import 'screens/asset/asset_request_screen.dart';
import 'screens/asset/asset_return_screen.dart';
import 'screens/it_file/it_file_screen.dart';
import 'screens/request/shift_deviation_screen.dart';
import 'screens/approval/approval_screen.dart';
import 'screens/teams/teams_screen.dart';
import 'screens/teams/team_detail_screen.dart';
import 'data/models/team_model.dart';
import 'core/constants.dart';

void main() {
  runApp(const SmartPayApp());
}

class SmartPayApp extends StatelessWidget {
  const SmartPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartPAY',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        useMaterial3: true,
        fontFamily: 'Source Sans Pro', // AdminLTE default
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/leave': (context) => const LeaveManagementScreen(),
        '/leave_compensation': (context) => const LeaveCompensationScreen(),
        '/attendance': (context) => const AttendanceScreen(),
        '/payslips': (context) => const PayslipScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/profile_edit': (context) => const ProfileEditScreen(),
        '/wages_detail': (context) => const WagesDetailScreen(),
        '/shift': (context) => const ShiftScreen(),
        '/request': (context) => const RequestScreen(),
        '/permission_request': (context) => const PermissionRequestScreen(),
        '/reimbursement': (context) => const ReimbursementScreen(),
        '/advance': (context) => const AdvanceRequestScreen(),
        '/advance_adjustment': (context) => const AdvanceAdjustmentScreen(),
        '/asset_request': (context) => const AssetRequestScreen(),
        '/asset_return': (context) => const AssetReturnScreen(),
        '/it_file': (context) => const ITFileScreen(),
        '/shift_deviation': (context) => const ShiftDeviationScreen(),
        '/approval': (context) => const ApprovalScreen(),
        '/teams': (context) => const TeamsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/team_detail') {
          if (settings.arguments is TeamMember) {
            final member = settings.arguments as TeamMember;
            return MaterialPageRoute(
              builder: (context) => TeamDetailScreen(
                empCode: member.empCode,
                member: member,
              ),
            );
          } else if (settings.arguments is String) {
            final empCode = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => TeamDetailScreen(empCode: empCode),
            );
          }
        }
        return null;
      },
    );
  }
}
