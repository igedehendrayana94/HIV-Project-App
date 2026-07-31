import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth_state.dart';
import '../../../core/theme.dart';
import '../../../shared/ambient_glow.dart';
import '../../../shared/app_card.dart';
import '../../../shared/i18n.dart';
import '../history/screening_history_screen.dart';
import '../registration/register_patient_screen.dart';

// Landing tab inside PatientShell (see patient_shell.dart) — Screening/Chat/Reminder/Account
// are now real bottom-nav tabs, not cards here; this stays a light hub for the survey
// explainer plus the two genuinely one-off/secondary destinations (register, history).
class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
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
              AppCard(
                child: Text(AppStrings.t('surveyExplanation'), style: Theme.of(context).textTheme.bodyMedium),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScreeningHistoryScreen())),
                child: Row(
                  children: [
                    const Icon(Icons.history),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(AppStrings.t('screeningHistory'))),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ).animate(delay: 80.ms).fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterPatientScreen())),
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(AppStrings.t('registerAsPatient'))),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ).animate(delay: 140.ms).fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
            ],
          ),
        ],
      ),
    );
  }
}
