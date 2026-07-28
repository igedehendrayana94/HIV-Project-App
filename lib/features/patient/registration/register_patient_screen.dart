import 'package:flutter/material.dart';
import '../../../core/api_client.dart';

// Mirrors RegisterPatientForm.tsx (web) — POST /api/patients links the new Patient row to
// the caller's own account for a PATIENT session. A newly-approved patient account has no
// Patient record yet, so screening/chat/history all 404 with "No patient record linked"
// until this runs once. Timezone auto-detection (the web form uses
// Intl.supportedValuesOf("timeZone") + browser locale) has no equivalent one-liner in
// Flutter without adding a package — defaults to Asia/Jakarta (this project's locale) as an
// editable field instead; add device-timezone detection if that default proves wrong often.
class RegisterPatientScreen extends StatefulWidget {
  const RegisterPatientScreen({super.key});

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
      setState(() => _error = _dob == null ? 'Date of birth is required' : null);
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
      appBar: AppBar(title: const Text('Register as Patient')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => (v == null || v.isEmpty) ? 'Full Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email (optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone (optional)'),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_dob == null ? 'Date of Birth' : _dob!.toIso8601String().split('T').first),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDob,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timezone,
                decoration: const InputDecoration(labelText: 'Timezone (IANA, e.g. Asia/Jakarta)'),
                validator: (v) => (v == null || v.isEmpty) ? 'Timezone is required' : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
