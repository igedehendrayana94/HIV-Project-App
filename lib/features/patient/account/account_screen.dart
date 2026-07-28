import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../core/auth_state.dart';
import '../../../shared/i18n.dart';

// Photo upload (the web app's Preferences page supports a base64 avatar) is deliberately
// skipped here — image_picker + base64 encoding is a real chunk of extra work for a first
// pass; add it when there's a concrete request for it.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  final _password = TextEditingController();
  bool _saving = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).value;
    _name = TextEditingController(text: user?.name ?? '');
    _email = TextEditingController(text: user?.email ?? '');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    try {
      await ref.read(authProvider.notifier).updateProfile(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
          );
      _password.clear();
      setState(() => _success = 'Saved.');
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Role: ${user?.role ?? ''}', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: AppStrings.t('name')),
                validator: (v) => (v == null || v.isEmpty) ? AppStrings.t('name') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: AppStrings.t('email')),
                validator: (v) => (v == null || v.isEmpty) ? AppStrings.t('email') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password (leave blank to keep current)'),
                validator: (v) => (v != null && v.isNotEmpty && v.length < 8)
                    ? 'Password must be at least 8 characters'
                    : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              if (_success != null) ...[
                const SizedBox(height: 16),
                Text(_success!, style: const TextStyle(color: Colors.green)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.read(authProvider.notifier).logout(),
                child: Text(AppStrings.t('logout')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
