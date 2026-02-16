import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/constants.dart';
import '../data/services/auth_service.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
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
            onTap: () {
              Navigator.pop(context);
              // If we are not already on Dashboard, navigate to it
              if (ModalRoute.of(context)?.settings.name != '/dashboard') {
                Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
              }
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.groups,
            title: 'Teams',
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/teams') {
                Navigator.pushNamed(context, '/teams');
              }
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
              if (ModalRoute.of(context)?.settings.name != '/request') {
                Navigator.pushNamed(context, '/request');
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 72),
            child: ListTile(
              title: const Text(
                'IT File',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textGray,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                if (ModalRoute.of(context)?.settings.name != '/it_file') {
                  Navigator.pushNamed(context, '/it_file');
                }
              },
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.check_circle_outline,
            title: 'Approvals',
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/approval') {
                Navigator.pushNamed(context, '/approval');
              }
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.history,
            title: 'Attendance History',
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/attendance') {
                Navigator.pushNamed(context, '/attendance');
              }
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.leaderboard_outlined,
            title: 'Leave Balance',
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/leave') {
                Navigator.pushNamed(context, '/leave');
              }
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.description_outlined,
            title: 'PaySlip',
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/payslips') {
                Navigator.pushNamed(context, '/payslips');
              }
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.list,
            title: 'Shift Schedule',
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/shift') {
                Navigator.pushNamed(context, '/shift');
              }
            },
          ),
          const SizedBox(height: 20),
          const Divider(),
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              AuthService().logout();
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
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
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: titleColor ?? AppColors.textGray,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
