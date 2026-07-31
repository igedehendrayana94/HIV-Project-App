import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../shared/app_card.dart';
import '../../../shared/async_error_view.dart';
import '../../../shared/empty_state.dart';
import '../../../shared/i18n.dart';

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
      appBar: AppBar(title: Text(AppStrings.t('medicationReminder'))),
      body: reminderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AsyncErrorView(message: apiErrorMessage(e), onRetry: () => ref.invalidate(reminderProvider)),
        data: (reminder) {
          final active = reminder != null && reminder['active'] == true;
          return RefreshIndicator(
            onRefresh: () => ref.refresh(reminderProvider.future),
            child: !active
                ? ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                      EmptyState(
                        icon: Icons.notifications_off_outlined,
                        message: AppStrings.t('noActiveReminderPatient'),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reminder Times', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: AppSpacing.xs),
                            Text(reminder['times'] as String? ?? '-'),
                            if (reminder['notes'] != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              Text('Notes', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: AppSpacing.xs),
                              Text(reminder['notes'] as String),
                            ],
                            if (reminder['startDate'] != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              Text('Effective From', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: AppSpacing.xs),
                              Text(DateTime.parse(reminder['startDate'] as String).toLocal().toString().split(' ').first),
                            ],
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
