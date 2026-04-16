import 'package:flutter/material.dart';

import '../theme/pawmilya_palette.dart';

class LoginCard extends StatelessWidget {
  const LoginCard({super.key, required this.child, required this.structured});

  final Widget child;
  final bool structured;

  @override
  Widget build(BuildContext context) {
    final radius = structured ? 22.0 : 28.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFEFB), Color(0xFFFFF6E9)],
        ),
        border: Border.all(
          color: PawmilyaPalette.cardEdge.withValues(
            alpha: structured ? 0.85 : 0.65,
          ),
          width: structured ? 1.15 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: PawmilyaPalette.goldDark.withValues(alpha: 0.16),
            blurRadius: structured ? 16 : 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
