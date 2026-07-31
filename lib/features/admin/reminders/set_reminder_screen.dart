import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../shared/i18n.dart';

class SetReminderScreen extends StatefulWidget {
  final int patientId;
  final String patientName;
  const SetReminderScreen({super.key, required this.patientId, required this.patientName});

  @override
  State<SetReminderScreen> createState() => _SetReminderScreenState();
}

class _SetReminderScreenState extends State<SetReminderScreen> {
  final _times = TextEditingController();
  final _notes = TextEditingController();
  bool _active = true;
  DateTime? _startDate;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await dio.get('/reminders', queryParameters: {'patientId': widget.patientId});
      final reminder = res.data['reminder'] as Map<String, dynamic>?;
      if (reminder != null) {
        _times.text = reminder['times'] as String? ?? '';
        _notes.text = reminder['notes'] as String? ?? '';
        _active = reminder['active'] as bool? ?? true;
        if (reminder['startDate'] != null) _startDate = DateTime.parse(reminder['startDate'] as String);
      }
    } catch (e) {
      _error = apiErrorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_times.text.trim().isEmpty) {
      // No i18n key exists for this validation message — left as plain English.
      setState(() => _error = 'Reminder times are required');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await dio.post('/reminders', data: {
        'patientId': widget.patientId,
        'active': _active,
        'times': _times.text.trim(),
        if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
        if (_startDate != null) 'startDate': _startDate!.toIso8601String(),
      });
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${AppStrings.t('reminderFor')} ${widget.patientName}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: ListView(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppStrings.t('active')),
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                  ),
                  // Extra breathing room between the on/off toggle and the schedule fields.
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _times,
                    decoration: InputDecoration(labelText: AppStrings.t('timesLabel')),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _notes,
                    decoration: InputDecoration(labelText: AppStrings.t('notesOptional')),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    // No i18n key exists for this label — left as plain English.
                    title: Text(_startDate == null
                        ? 'Effective From (optional)'
                        : _startDate!.toIso8601String().split('T').first),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (picked != null) setState(() => _startDate = picked);
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(AppStrings.t('save')),
                  ),
                ],
              ),
            ),
    );
  }
}
