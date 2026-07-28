import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth_state.dart';
import '../../../shared/i18n.dart';
import '../../patient/account/account_screen.dart';
import '../../provider/consultations/consultations_inbox_screen.dart';
import '../reminders/reminders_patient_picker_screen.dart';
import '../reports/reports_screen.dart';
import '../screening_questions/screening_questions_screen.dart';
import '../symptom_rules/symptom_rules_screen.dart';
import '../users/users_screen.dart';

// Admin gets everything Provider has (Live Consultations, reused directly from the provider
// feature — same screens, same access) plus the admin-only management screens below.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t('appName')),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Hi, ${user?.name ?? ''}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _NavCard(
            icon: Icons.forum_outlined,
            title: 'Live Consultations',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConsultationsInboxScreen())),
          ),
          _NavCard(
            icon: Icons.people_outline,
            title: 'Users',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UsersScreen())),
          ),
          _NavCard(
            icon: Icons.fact_check_outlined,
            title: 'Screening Questions',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScreeningQuestionsScreen())),
          ),
          _NavCard(
            icon: Icons.rule_outlined,
            title: 'Symptom Rules',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SymptomRulesScreen())),
          ),
          _NavCard(
            icon: Icons.notifications_active_outlined,
            title: 'Medication Reminders',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const RemindersPatientPickerScreen())),
          ),
          _NavCard(
            icon: Icons.file_download_outlined,
            title: 'Reports',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportsScreen())),
          ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _NavCard({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
