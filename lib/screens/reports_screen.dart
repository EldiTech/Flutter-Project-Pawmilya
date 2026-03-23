import 'package:flutter/material.dart';
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
        title: const Text('Reports'),
        backgroundColor: Colors.white,
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          final stats = provider.stats;
          final monthly = _buildMonthlyBreakdown(provider.applications);
          final maxCount = monthly.fold<int>(1, (max, item) => item.count > max ? item.count : max);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ReportCard(title: 'Total Adoptions', value: '${stats.totalAdoptions}'),
                  _ReportCard(title: 'Success Rate', value: '${stats.successRate}%'),
                  _ReportCard(title: 'Pending Apps', value: '${stats.pendingApplications}'),
                  _ReportCard(title: 'Active Employees', value: '${stats.activeEmployees}'),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Approved Applications',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    ...monthly.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 36,
                              child: Text(item.month),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  value: item.count / maxCount,
                                  minHeight: 12,
                                  color: AppColors.primary,
                                  backgroundColor: AppColors.warmAccent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 24,
                              child: Text(
                                '${item.count}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthCount {
  const _MonthCount({required this.month, required this.count});

  final String month;
  final int count;
}
