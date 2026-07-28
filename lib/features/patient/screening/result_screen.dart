import 'package:flutter/material.dart';
import '../../../shared/risk.dart';

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
      appBar: AppBar(title: const Text('Screening Result')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: info.color.withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${info.emoji} ${info.label}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: info.color)),
                  if (redFlag) ...[
                    const SizedBox(height: 4),
                    Text('RED FLAG', style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold)),
                  ],
                  const SizedBox(height: 12),
                  Text(info.actions),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Recommendations', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...info.recommendations.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [const Text('• '), Expanded(child: Text(r))],
                ),
              )),
          const SizedBox(height: 24),
          Text('Domain Scores', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...domainScores.entries.map((e) {
            final v = e.value as Map<String, dynamic>;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(e.key),
              trailing: Text('${v['tierLabel']} (${v['score']})'),
            );
          }),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }
}
