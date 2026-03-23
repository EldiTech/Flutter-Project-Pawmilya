import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../models/dashboard_stats.dart';
import '../../theme/app_theme.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({
    super.key,
    required this.stats,
  });

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatItem(
        label: 'Total Animals',
        value: stats.totalAnimals,
        percent: _safePercent(stats.totalAnimals, stats.totalAnimals + 10),
        icon: Icons.pets_rounded,
      ),
      _StatItem(
        label: 'Adoptions',
        value: stats.totalAdoptions,
        percent: _safePercent(stats.totalAdoptions, stats.totalAnimals),
        icon: Icons.volunteer_activism_rounded,
      ),
      _StatItem(
        label: 'Pending',
        value: stats.pendingApplications,
        percent: _safePercent(stats.pendingApplications, stats.totalApplications),
        icon: Icons.pending_actions_rounded,
      ),
      _StatItem(
        label: 'Employees',
        value: stats.activeEmployees,
        percent: _safePercent(stats.activeEmployees, stats.activeEmployees + 5),
        icon: Icons.badge_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 2;
        final isCompact = constraints.maxWidth < 420;

        return GridView.builder(
          itemCount: cards.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: isCompact ? 184 : 170,
          ),
          itemBuilder: (context, index) => _StatCard(item: cards[index]),
        );
      },
    );
  }

  double _safePercent(int value, int total) {
    if (total <= 0) return 0;
    return (value / total).clamp(0.0, 1.0);
  }
}

class _StatItem {
  const _StatItem({
    required this.label,
    required this.value,
    required this.percent,
    required this.icon,
  });

  final String label;
  final int value;
  final double percent;
  final IconData icon;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});

  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 420;

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularPercentIndicator(
            radius: isCompact ? 26 : 30,
            lineWidth: 6,
            percent: item.percent,
            progressColor: AppColors.primary,
            backgroundColor: AppColors.warmAccent.withValues(alpha: 0.35),
            center: Icon(item.icon, size: isCompact ? 16 : 18, color: AppColors.primary),
            circularStrokeCap: CircularStrokeCap.round,
          ),
          SizedBox(height: isCompact ? 8 : 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${item.value}',
              maxLines: 1,
              style: GoogleFonts.quicksand(
                fontSize: isCompact ? 30 : 34,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: isCompact ? 6 : 8),
          LinearProgressIndicator(
            value: item.percent,
            minHeight: isCompact ? 5 : 6,
            borderRadius: BorderRadius.circular(999),
            color: AppColors.primary,
            backgroundColor: AppColors.warmAccent.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
