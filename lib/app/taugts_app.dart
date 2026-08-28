import 'package:flutter/material.dart';
import 'package:taugts/core/theme/app_theme.dart';
import 'package:taugts/features/home/presentation/home_screen.dart';

class TaugtsApp extends StatelessWidget {
  const TaugtsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      theme: AppTheme.light,
      title: 'Taugt’s?',
    );
  }
}
