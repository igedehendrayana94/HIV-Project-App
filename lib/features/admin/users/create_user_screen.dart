import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../shared/i18n.dart';
import '../../../shared/password_field.dart';
import 'users_provider.dart';

// Skips the optional "link to an existing unlinked patient" convenience the web
// admin form has — a PATIENT account can always self-register via the Patient app's
// "Register as Patient" screen after approval instead. Add linking here if that
// proves to be a real workflow gap.
class CreateUserScreen extends ConsumerStatefulWidget {
  const CreateUserScreen({super.key});

  @override
  ConsumerState<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends ConsumerState<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'PROVIDER';
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await dio.post('/admin/users', data: {
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'role': _role,
      });
      ref.invalidate(adminUsersProvider);
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
      appBar: AppBar(title: Text(AppStrings.t('createAccount'))),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Identity group
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: AppStrings.t('fullName')),
                validator: (v) => (v == null || v.isEmpty) ? AppStrings.t('fullNameRequired') : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: AppStrings.t('email')),
                validator: (v) => (v == null || v.isEmpty) ? AppStrings.t('emailRequired') : null,
              ),
              // Extra breathing room between the identity fields and the credentials group.
              const SizedBox(height: AppSpacing.lg),
              PasswordField(
                controller: _password,
                labelText: AppStrings.t('password'),
                validator: (v) => (v == null || v.length < 8) ? AppStrings.t('atLeast8Chars') : null,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: InputDecoration(labelText: AppStrings.t('role')),
                items: [
                  DropdownMenuItem(value: 'ADMIN', child: Text(AppStrings.t('roleAdmin'))),
                  DropdownMenuItem(value: 'PROVIDER', child: Text(AppStrings.t('roleProvider'))),
                  DropdownMenuItem(value: 'PATIENT', child: Text(AppStrings.t('rolePatient'))),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(AppStrings.t('create')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
