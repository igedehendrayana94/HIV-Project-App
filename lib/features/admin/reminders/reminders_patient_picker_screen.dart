import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/async_error_view.dart';
import 'patients_list_provider.dart';
import 'set_reminder_screen.dart';

class RemindersPatientPickerScreen extends ConsumerWidget {
  const RemindersPatientPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(patientsListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Medication Reminders')),
      body: patientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            AsyncErrorView(message: apiErrorMessage(e), onRetry: () => ref.invalidate(patientsListProvider)),
        data: (patients) => RefreshIndicator(
          onRefresh: () => ref.refresh(patientsListProvider.future),
          child: patients.isEmpty
              ? ListView(
                  children: const [SizedBox(height: 120), Center(child: Text('No patients yet.'))],
                )
              : ListView(
                  children: patients
                      .map((p) => ListTile(
                            title: Text(p.name),
                            subtitle: Text('P${p.rank.toString().padLeft(4, '0')}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => SetReminderScreen(patientId: p.id, patientName: p.name)),
                            ),
                          ))
                      .toList(),
                ),
        ),
      ),
    );
  }
}
