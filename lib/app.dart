import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'features/main/main_shell.dart';
import 'features/auth/login_screen.dart';

/// Global navigator key — used by FCM tap handler to navigate without context.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3B0D0D),
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        routes: {
          '/home': (_) => const MainShell(),
          '/login': (_) => const LoginScreen(),
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.data != null) {
          return const MainShell();
        }
        return const LoginScreen();
      },
    );
  }
}
