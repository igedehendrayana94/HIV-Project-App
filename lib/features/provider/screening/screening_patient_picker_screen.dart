import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../shared/app_card.dart';
import '../../../shared/async_error_view.dart';
import '../../../shared/empty_state.dart';
import '../../../shared/i18n.dart';
import '../../admin/reminders/patients_list_provider.dart';
import '../../patient/screening/new_screening_screen.dart';

// Mirrors screening/new/page.tsx's ADMIN/PROVIDER patient picker (web locks PATIENT to
// getSessionPatient() instead — that's PatientHomeScreen's unparameterized NewScreeningScreen).
class ScreeningPatientPickerScreen extends ConsumerStatefulWidget {
  const ScreeningPatientPickerScreen({super.key});

  @override
  ConsumerState<ScreeningPatientPickerScreen> createState() => _ScreeningPatientPickerScreenState();
}

class _ScreeningPatientPickerScreenState extends ConsumerState<ScreeningPatientPickerScreen> {
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
      appBar: AppBar(title: Text(AppStrings.t('newScreening'))),
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
                  const SizedBox(height: 120),
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
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(labelText: AppStrings.t('searchPatientByName')),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: AppSpacing.md),
                if (filtered.isEmpty)
                  EmptyState(icon: Icons.search_off, message: AppStrings.t('noPatientsMatchSearch'))
                else
                  for (var i = 0; i < filtered.length; i++) ...[
                    AppCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NewScreeningScreen(patientId: filtered[i].id, patientName: filtered[i].name),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(filtered[i].name, style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: AppSpacing.xs),
                                Text('P${filtered[i].rank.toString().padLeft(4, '0')}',
                                    style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ).animate(delay: (i * 60).ms).fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
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
