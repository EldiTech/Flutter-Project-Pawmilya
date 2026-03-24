import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';

class PetCard extends StatelessWidget {
  final String name;
  final String status;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const PetCard({
    super.key,
    required this.name,
    required this.status,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Center(child: FaIcon(icon, size: 18, color: iconColor)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                status,
                style: GoogleFonts.quicksand(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.adoptionGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
