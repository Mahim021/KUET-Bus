import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'features/main/main_shell.dart';

class KuetBusApp extends StatefulWidget {
  const KuetBusApp({super.key});

  @override
  State<KuetBusApp> createState() => _KuetBusAppState();
}

class _KuetBusAppState extends State<KuetBusApp> {
  final _themeNotifier = AppThemeNotifier();

  @override
  void dispose() {
    _themeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeScope(
      notifier: _themeNotifier,
      child: MaterialApp(
        title: 'KUET Bus',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3B0D0D),
          ),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/home': (_) => const MainShell(),
        },
      ),
    );
  }
}
