import 'package:flutter/material.dart';

// ── Notifier ─────────────────────────────────────────────────────────────────

class AppThemeNotifier extends ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  void toggle() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

// ── Scope (InheritedNotifier) ─────────────────────────────────────────────────

class AppThemeScope extends InheritedNotifier<AppThemeNotifier> {
  const AppThemeScope({
    super.key,
    required AppThemeNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AppThemeNotifier of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppThemeScope>()!
        .notifier!;
  }

  static AppThemeData dataOf(BuildContext context) {
    return AppThemeData(
      isDark: context
          .dependOnInheritedWidgetOfExactType<AppThemeScope>()!
          .notifier!
          .isDark,
    );
  }
}

// ── ThemeData ─────────────────────────────────────────────────────────────────

class AppThemeData {
  final bool isDark;
  const AppThemeData({required this.isDark});

  static AppThemeData of(BuildContext context) => AppThemeScope.dataOf(context);

  // ── Backgrounds ───────────────────────────────────────────────────────────
  Color get bg => isDark ? const Color(0xFF0D0606) : const Color(0xFFF3F4F6);
  Color get surface => isDark ? const Color(0xFF1A0A0A) : Colors.white;
  Color get surfaceDeep =>
      isDark ? const Color(0xFF270D0D) : const Color(0xFFF3F4F6);
  Color get fieldFill =>
      isDark ? const Color(0xFF1F0F0F) : const Color(0xFFF2F3F5);

  // ── Borders ───────────────────────────────────────────────────────────────
  Color get border =>
      isDark ? const Color(0xFF2A1010) : const Color(0xFFE5E7EB);

  // ── Text ──────────────────────────────────────────────────────────────────
  Color get text => isDark ? Colors.white : const Color(0xFF1C1C1C);
  Color get subText =>
      isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  Color get label =>
      isDark ? const Color(0xFF776060) : const Color(0xFF9CA3AF);
  // Primary accent: maroon in light, light-rose in dark (stays visible on dark surfaces)
  Color get primaryAccent =>
      isDark ? const Color(0xFFE07B7B) : const Color(0xFF3B0D0D);

  // ── Nav Bar ───────────────────────────────────────────────────────────────
  Color get navBg => isDark ? const Color(0xFF3B0D0D) : Colors.white;
  Color get navActive => isDark ? Colors.white : const Color(0xFF3B0D0D);
  Color get navInactive =>
      isDark ? Colors.white54 : const Color(0xFFAAAAAA);
  Color get navActivePill => isDark
      ? Colors.white.withValues(alpha: 0.14)
      : const Color(0xFF3B0D0D).withValues(alpha: 0.10);

  // Center FAB
  Color get navCenterBg => isDark ? Colors.white : const Color(0xFF3B0D0D);
  Color get navCenterIcon => isDark ? const Color(0xFF3B0D0D) : Colors.white;
  Color get navCenterShadow => isDark
      ? Colors.white.withValues(alpha: 0.20)
      : const Color(0xFF3B0D0D).withValues(alpha: 0.40);
}
