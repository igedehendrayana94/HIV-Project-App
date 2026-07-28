import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/async_error_view.dart';
import '../../../shared/risk.dart';
import 'history_provider.dart';

class ScreeningHistoryScreen extends ConsumerWidget {
  const ScreeningHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(screeningHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Screening History')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            AsyncErrorView(message: apiErrorMessage(e), onRetry: () => ref.invalidate(screeningHistoryProvider)),
        data: (assessments) {
          if (assessments.isEmpty) {
            return const Center(child: Text('No screenings yet.'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(screeningHistoryProvider.future),
            child: ListView.separated(
              itemCount: assessments.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final a = assessments[i];
                final info = riskInfo[a.overallRisk]!;
                return ListTile(
                  title: Text('${info.emoji} ${info.label}'),
                  subtitle: Text(a.createdAt.toLocal().toString()),
                  trailing: a.redFlag
                      ? Text('RED FLAG', style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12))
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
