import 'package:flutter/material.dart';
import '../../core/services/auth_role_service.dart';
import '../../core/theme/app_theme.dart';
import '../admin/admin_dashboard_screen.dart';
import '../home/home_screen.dart';
import '../schedule/schedule_screen.dart';
import '../live_map/live_map_screen.dart';
import '../notices/notices_screen.dart';
import '../profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final _roleService = const AuthRoleService();

  void navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  void _onItemTapped(int index) {
    navigateTo(index);
  }

  List<Widget> _screens(bool isAdmin) {
    final screens = <Widget>[
      const HomeScreen(),
      const ScheduleScreen(),
      const LiveMapScreen(),
      const NoticesScreen(),
      const ProfileScreen(),
    ];
    if (isAdmin) {
      screens.add(const AdminDashboardScreen());
    }
    return screens;
  }

  List<_NavItem> _items(bool isAdmin) {
    final items = <_NavItem>[
      const _NavItem(icon: Icons.home_rounded, label: 'Home'),
      const _NavItem(icon: Icons.schedule_rounded, label: 'Schedule'),
      const _NavItem(icon: Icons.map_rounded, label: 'Live Map'),
      const _NavItem(icon: Icons.campaign_rounded, label: 'Notices'),
      const _NavItem(icon: Icons.person_rounded, label: 'Profile'),
    ];
    if (isAdmin) {
      items.add(const _NavItem(
          icon: Icons.admin_panel_settings_rounded, label: 'Admin'));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _roleService.watchIsAdmin(),
      initialData: false,
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? false;
        final screens = _screens(isAdmin);
        final items = _items(isAdmin);
        final safeIndex = _currentIndex >= screens.length ? 0 : _currentIndex;

        return Scaffold(
          body: IndexedStack(
            index: safeIndex,
            children: screens,
          ),
          bottomNavigationBar: _BottomNavBar(
            currentIndex: safeIndex,
            onTap: _onItemTapped,
            items: items,
          ),
        );
      },
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavItem> items;

  const _BottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: theme.navBg,
        boxShadow: [
          BoxShadow(
            color: theme.isDark
                ? Colors.black.withValues(alpha: 0.4)
                : const Color(0x18000000),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 72,
          child: Row(
            children: List.generate(items.length, (i) {
              final isCenter = i == 2;
              final isActive = currentIndex == i;

              if (isCenter) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.navCenterBg,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.navCenterShadow,
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            items[i].icon,
                            color: theme.navCenterIcon,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          items[i].label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color:
                                isActive ? theme.navActive : theme.navInactive,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.navActivePill
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          items[i].icon,
                          size: 22,
                          color: isActive ? theme.navActive : theme.navInactive,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        items[i].label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive ? theme.navActive : theme.navInactive,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
