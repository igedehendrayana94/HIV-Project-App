import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/async_error_view.dart';

// Provider/Admin set this (web app's /reminders page) — PATIENT is read-only here, matching
// POST /api/reminders staying Provider/Admin-only server-side.
final reminderProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final res = await dio.get('/reminders');
  return res.data['reminder'] as Map<String, dynamic>?;
});

class ReminderScreen extends ConsumerWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderAsync = ref.watch(reminderProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Medication Reminder')),
      body: reminderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AsyncErrorView(message: apiErrorMessage(e), onRetry: () => ref.invalidate(reminderProvider)),
        data: (reminder) {
          final active = reminder != null && reminder['active'] == true;
          return RefreshIndicator(
            onRefresh: () => ref.refresh(reminderProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: !active
                  ? [
                      const SizedBox(height: 120),
                      const Center(child: Text('No active reminder set by your provider yet.')),
                    ]
                  : [
                      const Text('Reminder Times', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(reminder['times'] as String? ?? '-'),
                      if (reminder['notes'] != null) ...[
                        const SizedBox(height: 16),
                        const Text('Notes', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(reminder['notes'] as String),
                      ],
                      if (reminder['startDate'] != null) ...[
                        const SizedBox(height: 16),
                        const Text('Effective From', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(DateTime.parse(reminder['startDate'] as String).toLocal().toString().split(' ').first),
                      ],
                    ],
            ),
          );
        },
      ),
    );
  }
}
