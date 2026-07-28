import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/risk.dart';
import '../../patient/screening/models.dart';

final _patientProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, patientId) async {
  final res = await dio.get('/patients/$patientId');
  return {'patient': res.data['patient'], 'rank': res.data['rank']};
});

final _patientHistoryProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, patientId) async {
  final res = await dio.get('/patients/$patientId/history');
  return {
    'symptomReports': res.data['symptomReports'] as List,
    'screeningAssessments': (res.data['screeningAssessments'] as List)
        .map((a) => ScreeningAssessment.fromJson(a as Map<String, dynamic>))
        .toList(),
  };
});

class PatientDetailScreen extends ConsumerWidget {
  final int patientId;
  const PatientDetailScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(_patientProvider(patientId));
    final historyAsync = ref.watch(_patientHistoryProvider(patientId));

    return Scaffold(
      appBar: AppBar(title: const Text('Patient')),
      body: patientAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(apiErrorMessage(e))),
        data: (data) {
          final patient = data['patient'] as Map<String, dynamic>;
          final code = 'P${(data['rank'] as int).toString().padLeft(4, '0')}';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('${patient['name']} · $code', style: Theme.of(context).textTheme.titleLarge),
              if (patient['phone'] != null) Text(patient['phone'] as String),
              if (patient['email'] != null) Text(patient['email'] as String),
              const SizedBox(height: 24),
              Text('Screening History', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              historyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(apiErrorMessage(e)),
                data: (history) {
                  final assessments = history['screeningAssessments'] as List<ScreeningAssessment>;
                  if (assessments.isEmpty) return const Text('No screenings yet.');
                  return Column(
                    children: assessments.map((a) {
                      final info = riskInfo[a.overallRisk]!;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${info.emoji} ${info.label}'),
                        subtitle: Text(a.createdAt.toLocal().toString()),
                        trailing: a.redFlag
                            ? Text('RED FLAG', style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12))
                            : null,
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
