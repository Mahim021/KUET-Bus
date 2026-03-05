import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
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

  void navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    ScheduleScreen(),
    LiveMapScreen(),
    NoticesScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    navigateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);
    const items = [
      _NavItem(icon: Icons.home_rounded, label: 'Home'),
      _NavItem(icon: Icons.schedule_rounded, label: 'Schedule'),
      _NavItem(icon: Icons.map_rounded, label: 'Live Map'),
      _NavItem(icon: Icons.campaign_rounded, label: 'Notices'),
      _NavItem(icon: Icons.person_rounded, label: 'Profile'),
    ];

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
          height: 64,
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
                          width: 52,
                          height: 52,
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
                        const SizedBox(height: 2),
                        Text(
                          items[i].label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? theme.navActive
                                : theme.navInactive,
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
                          color: isActive
                              ? theme.navActive
                              : theme.navInactive,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[i].label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? theme.navActive
                              : theme.navInactive,
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
