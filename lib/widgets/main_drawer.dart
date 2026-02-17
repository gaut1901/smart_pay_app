import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/constants.dart';
import '../data/services/auth_service.dart';
import '../data/models/menu_model.dart';
import 'dart:developer' as developer;

class MainDrawer extends StatefulWidget {
  const MainDrawer({super.key});

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  List<MenuModel> _menuItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMenus();
  }

  Future<void> _fetchMenus() async {
    try {
      final menus = await AuthService().getMenu();
      if (mounted) {
        setState(() {
          _menuItems = menus;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      developer.log('Error fetching menus: $e');
    }
  }

  // Helper to map web captions/names to Flutter routes
  String? _getRouteForMenu(String caption) {
    // Normalize string for comparison
    final normalizedCaption = caption.replaceAll(' ', '').toLowerCase();
    
    if (normalizedCaption.contains('dashboard')) return '/dashboard';
    if (normalizedCaption.contains('team')) return '/teams';
    // Requests is usually "Leave Request", "Permission Request", "Manual Punch" under a parent,
    // or sometimes just "Requests". For now, if we match "Request", go to /request
    if (normalizedCaption.contains('request')) return '/request';
    if (normalizedCaption.contains('itfile') || normalizedCaption.contains('incometax')) return '/it_file';
    if (normalizedCaption.contains('approval')) return '/approval';
    if (normalizedCaption.contains('attendancehistory') || normalizedCaption.contains('attendanceview')) return '/attendance';
    if (normalizedCaption.contains('leavebalance')) return '/leave';
    if (normalizedCaption.contains('payslip')) return '/payslips';
    if (normalizedCaption.contains('shiftschedule') || normalizedCaption.contains('roster')) return '/shift';
    
    return null;
  }

  // Helper to map web icon classes (FontAwesome) to Flutter Icons
  IconData _getIconForMenu(String iconClass, String caption) {
    if (iconClass.contains('dashboard')) return Icons.dashboard;
    if (iconClass.contains('users') || iconClass.contains('group')) return Icons.groups;
    if (iconClass.contains('edit') || iconClass.contains('pencil')) return Icons.edit_note;
    if (iconClass.contains('file') || iconClass.contains('text')) return Icons.description_outlined;
    if (iconClass.contains('check')) return Icons.check_circle_outline;
    if (iconClass.contains('history') || iconClass.contains('clock')) return Icons.history;
    if (iconClass.contains('balance') || iconClass.contains('scale')) return Icons.leaderboard_outlined;
    if (iconClass.contains('calendar') || iconClass.contains('list')) return Icons.list;
    if (iconClass.contains('building')) return Icons.business;

    // Fallback based on caption if icon class is generic or missing
    final normalizedCaption = caption.toLowerCase();
    if (normalizedCaption.contains('dashboard')) return Icons.dashboard;
    if (normalizedCaption.contains('team')) return Icons.groups;
    if (normalizedCaption.contains('request')) return Icons.edit_note;
    if (normalizedCaption.contains('it file')) return Icons.description;
    if (normalizedCaption.contains('approval')) return Icons.check_circle_outline;
    if (normalizedCaption.contains('attendance')) return Icons.history;
    if (normalizedCaption.contains('payslip')) return Icons.receipt;
    if (normalizedCaption.contains('shift')) return Icons.calendar_month;

    return Icons.circle_outlined; // Default icon
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
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
          
          // Menu List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // Always show generic dashboard if API fails or returns empty, 
                      // or if we just want to ensure it's there. 
                      // However, strict dynamic means we rely on API.
                      // Let's rely on API, but maybe keep Dashboard as a static fallback or pinned item?
                      // For this request, "menus are coming from api".
                      // We will iterate the API items.
                      ..._menuItems.map((menu) {
                        final routeName = _getRouteForMenu(menu.menuCaption);
                        if (routeName == null) return const SizedBox.shrink(); // Skip unknown menus

                        return _buildDrawerItem(
                          context,
                          icon: _getIconForMenu(menu.icon, menu.menuCaption),
                          title: menu.menuCaption,
                          onTap: () {
                            Navigator.pop(context);
                            if (ModalRoute.of(context)?.settings.name != routeName) {
                              // Special case for Dashboard removal logic if needed
                              if (routeName == '/dashboard') {
                                Navigator.pushNamedAndRemoveUntil(context, routeName, (route) => false);
                              } else {
                                Navigator.pushNamed(context, routeName);
                              }
                            }
                          },
                        );
                      }),
                      
                      // Fallback: If no menus loaded (e.g. error/empty), show default static list?
                      // Or just show nothing? The user asked for "menus come from api".
                      // I will show a message or just the Logout button if empty.
                      if (_menuItems.isEmpty && !_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("No menu items found.", style: TextStyle(color: Colors.grey)),
                        ),
                    ],
                  ),
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
          const SizedBox(height: 20),
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
