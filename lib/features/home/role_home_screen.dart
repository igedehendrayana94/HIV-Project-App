import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_state.dart';
import '../../shared/i18n.dart';
import '../patient/home/patient_home_screen.dart';
import '../provider/home/provider_home_screen.dart';

// Dispatches to the real per-role home once it exists. PATIENT (Phase 2) and PROVIDER
// (Phase 3) are built; Admin (Phase 4) still falls through to the placeholder below.
class RoleHomeScreen extends ConsumerWidget {
  const RoleHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    if (user?.role == 'PATIENT') return const PatientHomeScreen();
    if (user?.role == 'PROVIDER') return const ProviderHomeScreen();

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('appName'))),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Signed in as ${user?.name ?? ''}'),
            Text('Role: ${user?.role ?? ''}'),
            const SizedBox(height: 8),
            const Text('This role\'s screens are not built yet.'),
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
