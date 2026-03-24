import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/adoption_application.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBg,
      appBar: AppBar(
        title: Text(
          'Pet Management Analytics',
          style: GoogleFonts.quicksand(
            color: AppColors.textDark,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          final stats = provider.stats;
          final monthly = _buildMonthlyBreakdown(provider.applications);
          final metrics = [
            _MetricSpec(
              title: 'Total Adoptions',
              value: '${stats.totalAdoptions}',
              icon: Icons.pets_outlined,
            ),
            _MetricSpec(
              title: 'Success Rate',
              value: '${stats.successRate}%',
              icon: Icons.trending_up_rounded,
            ),
            _MetricSpec(
              title: 'Pending Apps',
              value: '${stats.pendingApplications}',
              icon: Icons.hourglass_top_rounded,
            ),
            _MetricSpec(
              title: 'Active Employees',
              value: '${stats.activeEmployees}',
              icon: Icons.groups_2_outlined,
            ),
            _MetricSpec(
              title: 'Total Animals',
              value: '${stats.totalAnimals}',
              icon: Icons.pets_rounded,
            ),
          ];

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _AnalyticsSidebar(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(10, 16, 16, 20),
                  children: [
                    _BentoMetricsGrid(metrics: metrics),
                    const SizedBox(height: 16),
                    _MonthlyApprovedChart(monthly: monthly),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<_MonthCount> _buildMonthlyBreakdown(List<AdoptionApplication> applications) {
    final monthNames = const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final counts = List<int>.filled(12, 0);

    for (final app in applications) {
      final status = app.status;
      if (status != 'Approved') continue;

      final parsed = DateTime.tryParse(app.date ?? '');
      if (parsed == null) continue;
      counts[parsed.month - 1] += 1;
    }

    return List.generate(
      12,
      (index) => _MonthCount(month: monthNames[index], count: counts[index]),
    );
  }
}

class _AnalyticsSidebar extends StatelessWidget {
  const _AnalyticsSidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      margin: const EdgeInsets.fromLTRB(12, 12, 0, 12),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warmAccent.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          Icon(Icons.dashboard_outlined, size: 16, color: AppColors.textMid),
          const SizedBox(height: 18),
          Container(
            width: 6,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}

class _BentoMetricsGrid extends StatelessWidget {
  const _BentoMetricsGrid({required this.metrics});

  final List<_MetricSpec> metrics;

  @override
  Widget build(BuildContext context) {
    final large = metrics.first;
    final rest = metrics.skip(1).toList();

    return Column(
      children: [
        _MetricCard(spec: large, isLarge: true),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _MetricCard(spec: rest[0])),
            const SizedBox(width: 12),
            Expanded(child: _MetricCard(spec: rest[1])),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _MetricCard(spec: rest[2])),
            const SizedBox(width: 12),
            Expanded(child: _MetricCard(spec: rest[3])),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.spec, this.isLarge = false});

  final _MetricSpec spec;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 16 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.warmAccent.withValues(alpha: 0.68)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spec.title,
                  style: GoogleFonts.quicksand(
                    color: AppColors.textMuted,
                    fontSize: isLarge ? 14 : 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.25,
                  ),
                ),
                SizedBox(height: isLarge ? 8 : 10),
                Text(
                  spec.value,
                  style: GoogleFonts.quicksand(
                    color: AppColors.textDark,
                    fontSize: isLarge ? 44 : 30,
                    fontWeight: FontWeight.w900,
                    height: 0.95,
                  ),
                ),
              ],
            ),
          ),
          Icon(spec.icon, color: AppColors.textMid, size: isLarge ? 20 : 18),
        ],
      ),
    );
  }
}

class _MonthlyApprovedChart extends StatelessWidget {
  const _MonthlyApprovedChart({required this.monthly});

  final List<_MonthCount> monthly;

  @override
  Widget build(BuildContext context) {
    final maxCount = monthly.fold<int>(1, (max, item) => item.count > max ? item.count : max);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.warmAccent.withValues(alpha: 0.68)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Approved Applications',
            style: GoogleFonts.quicksand(
              color: AppColors.textDark,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Approval trend over the year',
            style: GoogleFonts.quicksand(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 210,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: (maxCount + 1).toDouble(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.warmAccent.withValues(alpha: 0.58),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= monthly.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            monthly[index].month,
                            style: GoogleFonts.quicksand(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      monthly.length,
                      (index) => FlSpot(index.toDouble(), monthly[index].count.toDouble()),
                    ),
                    isCurved: true,
                    curveSmoothness: 0.28,
                    color: AppColors.primary,
                    barWidth: 3.4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 3,
                        color: AppColors.primary,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.34),
                          AppColors.primary.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricSpec {
  const _MetricSpec({required this.title, required this.value, required this.icon});

  final String title;
  final String value;
  final IconData icon;
}

class _MonthCount {
  const _MonthCount({required this.month, required this.count});

  final String month;
  final int count;
}
