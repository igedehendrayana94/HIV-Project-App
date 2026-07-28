import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_state.dart';
import '../../shared/i18n.dart';

// Placeholder post-login landing screen — Phase 2 (Patient), Phase 3 (Provider), and Phase 4
// (Admin) each replace this with their real role-specific home. Kept here so Phase 1's
// auth flow is verifiable end-to-end on its own.
class RoleHomeScreen extends ConsumerWidget {
  const RoleHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('appName'))),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Signed in as ${user?.name ?? ''}'),
            Text('Role: ${user?.role ?? ''}'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              child: Text(AppStrings.t('logout')),
            ),
          ],
        ),
      ),
    );
  }
}
