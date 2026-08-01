import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../shared/app_card.dart';
import '../../../shared/i18n.dart';

// Mirrors RegisterPatientForm.tsx (web) — POST /api/patients links the new Patient row to
// the caller's own account for a PATIENT session. A newly-approved patient account has no
// Patient record yet, so screening/chat/history all 404 with "No patient record linked"
// until this runs once. Timezone auto-detection (the web form uses
// Intl.supportedValuesOf("timeZone") + browser locale) has no equivalent one-liner in
// Flutter without adding a package — defaults to Asia/Jakarta (this project's locale) as an
// editable field instead; add device-timezone detection if that default proves wrong often.
class RegisterPatientScreen extends StatefulWidget {
  // POST /api/patients auto-links to the caller's own account only for a PATIENT session;
  // Provider/Admin get a plain unlinked registration — same endpoint, backend branches on
  // role, only the title needs to read differently here. An i18n key name (not literal text)
  // so the title stays locale-correct — a raw string param can't react to the EN/ID toggle.
  final String? titleKey;

  const RegisterPatientScreen({super.key, this.titleKey});

  @override
  State<RegisterPatientScreen> createState() => _RegisterPatientScreenState();
}

class _RegisterPatientScreenState extends State<RegisterPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _timezone = TextEditingController(text: 'Asia/Jakarta');
  DateTime? _dob;
  bool _saving = false;
  String? _error;

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 30),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _dob == null) {
      setState(() => _error = _dob == null ? AppStrings.t('dateOfBirthRequired') : null);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await dio.post('/patients', data: {
        'name': _name.text.trim(),
        if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
        if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
        'dateOfBirth': _dob!.toIso8601String(),
        'timezone': _timezone.text.trim(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titleKey != null ? AppStrings.t(widget.titleKey!) : AppStrings.t('registerAsPatient')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: InputDecoration(labelText: AppStrings.t('fullName')),
                      validator: (v) => (v == null || v.isEmpty) ? AppStrings.t('fullNameRequired') : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: AppStrings.t('emailOptional')),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(labelText: AppStrings.t('phoneOptional')),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_dob == null ? AppStrings.t('dateOfBirth') : _dob!.toIso8601String().split('T').first),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _pickDob,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _timezone,
                      decoration: InputDecoration(labelText: AppStrings.t('timezoneHint')),
                      validator: (v) => (v == null || v.isEmpty) ? AppStrings.t('timezoneRequired') : null,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(AppStrings.t('register')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
