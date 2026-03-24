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
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            mainAxisExtent: isCompact ? 194 : 186,
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
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.warmBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warmAccent.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: isCompact ? 78 : 84,
            height: isCompact ? 78 : 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.warmAccent.withValues(alpha: 0.78),
                  AppColors.textMid.withValues(alpha: 0.35),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textDark.withValues(alpha: 0.13),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: CircularPercentIndicator(
              radius: isCompact ? 32 : 35,
              lineWidth: 6.5,
              percent: item.percent,
              progressColor: AppColors.primary,
              backgroundColor: AppColors.warmAccent.withValues(alpha: 0.75),
              center: Container(
                width: isCompact ? 46 : 50,
                height: isCompact ? 46 : 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: AppColors.warmAccent),
                ),
                child: Icon(item.icon, size: isCompact ? 18 : 20, color: AppColors.primaryDark),
              ),
              circularStrokeCap: CircularStrokeCap.round,
            ),
          ),
          SizedBox(height: isCompact ? 9 : 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${item.value}',
              maxLines: 1,
              style: GoogleFonts.playfairDisplay(
                fontSize: isCompact ? 36 : 40,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(
              fontSize: isCompact ? 12 : 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textMid,
            ),
          ),
          SizedBox(height: isCompact ? 6 : 10),
          _CopperProgressRod(percent: item.percent, isCompact: isCompact),
        ],
      ),
    );
  }
}

class _CopperProgressRod extends StatelessWidget {
  const _CopperProgressRod({required this.percent, required this.isCompact});

  final double percent;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final normalized = percent.clamp(0.0, 1.0);
    return SizedBox(
      height: isCompact ? 10 : 12,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final progressWidth = constraints.maxWidth * normalized;
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: isCompact ? 5 : 6,
                decoration: BoxDecoration(
                  color: AppColors.warmAccent.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Container(
                width: progressWidth,
                height: isCompact ? 5 : 6,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 10,
                      spreadRadius: -2,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: (progressWidth - (isCompact ? 6 : 7)).clamp(0.0, constraints.maxWidth),
                child: Container(
                  width: isCompact ? 6 : 7,
                  height: isCompact ? 6 : 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.warmAccent,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
