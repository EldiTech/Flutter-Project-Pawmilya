import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onMenuTap,
    required this.showMenu,
  });

  final String title;
  final String subtitle;
  final VoidCallback onMenuTap;
  final bool showMenu;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 16,
            vertical: isCompact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showMenu) ...[
                      IconButton(
                        onPressed: onMenuTap,
                        icon: const Icon(Icons.menu_rounded),
                        color: AppColors.textDark,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.quicksand(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    if (showMenu) ...[
                      IconButton(
                        onPressed: onMenuTap,
                        icon: const Icon(Icons.menu_rounded),
                        color: AppColors.textDark,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.quicksand(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.quicksand(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
