import 'package:flutter/material.dart';

import '../theme/pawmilya_palette.dart';

class RoleCard extends StatelessWidget {
  const RoleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.icon,
    required this.gradient,
    required this.actionGradient,
    required this.onTap,
    required this.structured,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final IconData icon;
  final List<Color> gradient;
  final List<Color> actionGradient;
  final VoidCallback onTap;
  final bool structured;

  @override
  Widget build(BuildContext context) {
    final radius = structured ? 22.0 : 28.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        border: Border.all(
          color: PawmilyaPalette.cardEdge.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: PawmilyaPalette.goldDark.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        actionGradient.first.withValues(alpha: 0.95),
                        actionGradient.last.withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                  child: Icon(icon, color: const Color(0xFFFFF8EC), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: PawmilyaPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: PawmilyaPalette.textSecondary,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(colors: actionGradient),
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      color: Color(0xFFFFF8EC),
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
