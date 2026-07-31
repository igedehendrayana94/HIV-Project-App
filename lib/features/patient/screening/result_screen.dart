import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme.dart';
import '../../../shared/app_card.dart';
import '../../../shared/i18n.dart';
import '../../../shared/risk.dart';
import '../../../shared/risk_pill.dart';

class ScreeningResultScreen extends StatelessWidget {
  final String overallRisk;
  final bool redFlag;
  final Map<String, dynamic> domainScores;

  const ScreeningResultScreen({
    super.key,
    required this.overallRisk,
    required this.redFlag,
    required this.domainScores,
  });

  @override
  Widget build(BuildContext context) {
    final info = riskInfo[overallRisk]!;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('screeningResult'))),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RiskPill(risk: overallRisk),
                if (redFlag) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text('RED FLAG',
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold)),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(info.actions),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
          const SizedBox(height: AppSpacing.lg),
          Text('Recommendations', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: info.recommendations
                  .map((r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [const Text('• '), Expanded(child: Text(r))],
                        ),
                      ))
                  .toList(),
            ),
          ).animate(delay: 80.ms).fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
          const SizedBox(height: AppSpacing.lg),
          Text('Domain Scores', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              children: domainScores.entries.map((e) {
                final v = e.value as Map<String, dynamic>;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.key),
                  trailing: Text('${v['tierLabel']} (${v['score']})'),
                );
              }).toList(),
            ),
          ).animate(delay: 140.ms).fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: Text(AppStrings.t('backToHome')),
          ),
        ],
      ),
    );
  }
}
