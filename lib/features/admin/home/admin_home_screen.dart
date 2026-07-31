import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth_state.dart';
import '../../../core/theme.dart';
import '../../../shared/ambient_glow.dart';
import '../../../shared/app_card.dart';
import '../../../shared/i18n.dart';
import '../reminders/reminders_patient_picker_screen.dart';
import '../reports/reports_screen.dart';
import '../screening_questions/screening_questions_screen.dart';
import '../symptom_rules/symptom_rules_screen.dart';

// Landing tab inside AdminShell (see admin_shell.dart) — Consultations/Users/Account are now
// real bottom-nav tabs; this hub keeps the lower-frequency admin config/report screens.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final items = [
      (Icons.fact_check_outlined, AppStrings.t('screeningQuestions'),
          () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScreeningQuestionsScreen()))),
      (Icons.rule_outlined, AppStrings.t('symptomRules'),
          () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SymptomRulesScreen()))),
      (Icons.notifications_active_outlined, AppStrings.t('medicationReminders'),
          () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RemindersPatientPickerScreen()))),
      (Icons.file_download_outlined, AppStrings.t('reports'),
          () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportsScreen()))),
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
