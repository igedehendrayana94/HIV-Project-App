import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth_state.dart';
import '../../../core/theme.dart';
import '../../../shared/ambient_glow.dart';
import '../../../shared/app_card.dart';
import '../../../shared/i18n.dart';
import '../../admin/reminders/reminders_patient_picker_screen.dart';
import '../../patient/registration/register_patient_screen.dart';
import '../screening/screening_patient_picker_screen.dart';

// Landing tab inside ProviderShell (see provider_shell.dart) — Consultations/Reports/Account
// are now real bottom-nav tabs; this hub keeps only the lower-frequency destinations.
class ProviderHomeScreen extends ConsumerWidget {
  const ProviderHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final items = [
      (Icons.fact_check_outlined, AppStrings.t('newScreening'),
          () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScreeningPatientPickerScreen()))),
      (Icons.person_add_outlined, AppStrings.t('registerPatient'),
          () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterPatientScreen(title: 'Register Patient')))),
      (Icons.notifications_active_outlined, AppStrings.t('medicationReminders'),
          () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RemindersPatientPickerScreen()))),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('appName'))),
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientGlow()),
          ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(AppStrings.greeting(user?.name ?? ''), style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.md),
              for (final (i, item) in items.indexed) ...[
                AppCard(
                  onTap: item.$3,
                  child: Row(
                    children: [
                      Icon(item.$1),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(item.$2)),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ).animate(delay: (i * 60).ms).fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
                if (i != items.length - 1) const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
