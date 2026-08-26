import 'package:flutter/material.dart';
import 'package:walt/core/constants/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.splashBackground,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
