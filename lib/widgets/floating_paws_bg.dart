import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';

class FloatingPawsBackground extends StatelessWidget {
  const FloatingPawsBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final random = Random(42); // fixed seed for consistent layout

    return IgnorePointer(
      child: Stack(
        children: List.generate(8, (index) {
          final top = random.nextDouble() * size.height;
          final left = random.nextDouble() * size.width;
          final rotation = random.nextDouble() * 2 * pi;
          final pawSize = 24.0 + random.nextDouble() * 36;

          return Positioned(
            top: top,
            left: left,
            child: Transform.rotate(
              angle: rotation,
              child: FaIcon(
                FontAwesomeIcons.paw,
                size: pawSize,
                color: AppColors.primary.withValues(alpha: 0.04),
              ),
            ),
          );
        }),
      ),
    );
  }
}
