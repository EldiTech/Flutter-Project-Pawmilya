import 'package:flutter/material.dart';

import '../screens/enter_system_landing_screen.dart';
import '../theme/pawmilya_theme.dart';

class PawmilyaApp extends StatelessWidget {
  const PawmilyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pawmilya',
      debugShowCheckedModeBanner: false,
      theme: buildPawmilyaTheme(),
      home: const EnterSystemLandingScreen(),
    );
  }
}
