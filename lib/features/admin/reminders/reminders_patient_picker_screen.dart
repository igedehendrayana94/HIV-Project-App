import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../shared/app_card.dart';
import '../../../shared/async_error_view.dart';
import '../../../shared/empty_state.dart';
import '../../../shared/i18n.dart';
import 'patients_list_provider.dart';
import 'set_reminder_screen.dart';

class RemindersPatientPickerScreen extends ConsumerStatefulWidget {
  const RemindersPatientPickerScreen({super.key});

  @override
  ConsumerState<RemindersPatientPickerScreen> createState() => _RemindersPatientPickerScreenState();
}

class _RemindersPatientPickerScreenState extends ConsumerState<RemindersPatientPickerScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientsListProvider);
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('medicationReminders'))),
      body: patientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            AsyncErrorView(message: apiErrorMessage(e), onRetry: () => ref.invalidate(patientsListProvider)),
        data: (patients) {
          if (patients.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => ref.refresh(patientsListProvider.future),
              child: ListView(
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  EmptyState(icon: Icons.people_outline, message: AppStrings.t('noPatientsYet')),
                ],
              ),
            );
          }
          final q = _query.trim().toLowerCase();
          final filtered =
              q.isEmpty ? patients : patients.where((p) => p.name.toLowerCase().contains(q)).toList();
          return RefreshIndicator(
            onRefresh: () => ref.refresh(patientsListProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // No i18n key for a patient search hint — left as a plain English literal.
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(labelText: 'Search patient by name'),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: AppSpacing.md),
                if (filtered.isEmpty)
                  const EmptyState(icon: Icons.search_off, message: 'No patients match your search.')
                else
                  for (final (i, p) in filtered.indexed) ...[
                    AppCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SetReminderScreen(patientId: p.id, patientName: p.name)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'P${p.rank.toString().padLeft(4, '0')}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ).animate(delay: (i * 40).ms).fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
                    if (i != filtered.length - 1) const SizedBox(height: AppSpacing.sm),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}
