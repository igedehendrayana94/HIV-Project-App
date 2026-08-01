import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../core/auth_state.dart';
import '../../../core/locale_state.dart';
import '../../../core/theme.dart';
import '../../../shared/app_card.dart';
import '../../../shared/confirm_dialog.dart';
import '../../../shared/i18n.dart';
import '../../../shared/password_field.dart';

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
  final _oldPassword = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _changePassword = false;
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
            password: _changePassword ? _password.text : null,
            oldPassword: _changePassword ? _oldPassword.text : null,
          );
      _oldPassword.clear();
      _password.clear();
      _confirmPassword.clear();
      setState(() {
        _changePassword = false;
        _success = AppStrings.t('saved');
      });
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final locale = ref.watch(localeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('account'))),
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
                    Text('${AppStrings.t('role')}: ${user?.role ?? ''}', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _name,
                      decoration: InputDecoration(labelText: AppStrings.t('name')),
                      validator: (v) => (v == null || v.isEmpty) ? AppStrings.t('name') : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: AppStrings.t('email')),
                      validator: (v) => (v == null || v.isEmpty) ? AppStrings.t('email') : null,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // A macOS/iOS system password-autofill suggestion can silently populate an
                    // obscured field even without the user typing anything — gating the actual
                    // submit behind this explicit toggle (not just "field is non-empty") is what
                    // stops an unwanted suggestion from ever getting sent as a real password change.
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(AppStrings.t('changePassword')),
                      value: _changePassword,
                      onChanged: (v) => setState(() {
                        _changePassword = v;
                        if (!v) {
                          _oldPassword.clear();
                          _password.clear();
                          _confirmPassword.clear();
                        }
                      }),
                    ),
                    if (_changePassword) ...[
                      const SizedBox(height: AppSpacing.xs),
                      PasswordField(
                        controller: _oldPassword,
                        autofillHints: const [],
                        labelText: AppStrings.t('currentPassword'),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? AppStrings.t('currentPasswordRequired') : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      PasswordField(
                        controller: _password,
                        autofillHints: const [],
                        labelText: AppStrings.t('newPassword'),
                        validator: (v) =>
                            (v == null || v.length < 8) ? AppStrings.t('passwordMinLength') : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      PasswordField(
                        controller: _confirmPassword,
                        autofillHints: const [],
                        labelText: AppStrings.t('confirmNewPassword'),
                        validator: (v) =>
                            (v != _password.text) ? AppStrings.t('newPasswordsDoNotMatch') : null,
                      ),
                    ],
                  ],
                ),
              ).animate(delay: 60.ms).fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Row(
                  children: [
                    Expanded(child: Text(AppStrings.t('language'), style: Theme.of(context).textTheme.titleMedium)),
                    SegmentedButton<AppLocale>(
                      segments: const [
                        ButtonSegment(value: AppLocale.id, label: Text('ID')),
                        ButtonSegment(value: AppLocale.en, label: Text('EN')),
                      ],
                      selected: {locale},
                      onSelectionChanged: (_) => ref.read(localeProvider.notifier).toggle(),
                    ),
                  ],
                ),
              ).animate(delay: 120.ms).fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              if (_success != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_success!, style: const TextStyle(color: Colors.green)),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(AppStrings.t('save')),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () async {
                  final ok = await confirmAction(
                    context,
                    title: AppStrings.t('areYouSure'),
                    message: AppStrings.t('logoutConfirmMessage'),
                    confirmLabel: AppStrings.t('logout'),
                  );
                  if (ok) ref.read(authProvider.notifier).logout();
                },
                child: Text(AppStrings.t('logout')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
