import 'package:flutter/material.dart';
import 'features/splash/splash_screen.dart';

class KuetBusApp extends StatelessWidget {
  const KuetBusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'KUET Bus',
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
