import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/async_error_view.dart';
import '../../../shared/i18n.dart';
import '../../../shared/risk_pill.dart';
import 'my_reports_provider.dart';

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(myReportsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('reports'))),
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            AsyncErrorView(message: apiErrorMessage(e), onRetry: () => ref.invalidate(myReportsProvider)),
        data: (reports) => RefreshIndicator(
          onRefresh: () => ref.refresh(myReportsProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(AppStrings.t('riskDistribution'), style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              if (reports.distribution.isEmpty)
                Text(AppStrings.t('noScreeningsYet'))
              else
                Card(
                  child: Column(
                    children: reports.distribution
                        .map((d) => ListTile(
                              title: RiskPill(risk: d.overallRisk),
                              trailing: Text('${d.count}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ))
                        .toList(),
                  ),
                ),
              const SizedBox(height: 24),
              Text(AppStrings.t('myScreeningHistory'), style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              if (reports.screenings.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text(AppStrings.t('noScreeningsYet'))),
                )
              else
                Card(
                  child: Column(
                    children: reports.screenings
                        .map((s) => ListTile(
                              title: Text(s.patientName),
                              subtitle: Text(_formatDate(s.createdAt)),
                              trailing: RiskPill(risk: s.overallRisk),
                            ))
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
