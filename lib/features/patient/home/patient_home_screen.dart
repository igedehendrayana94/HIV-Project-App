import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth_state.dart';
import '../../../shared/i18n.dart';
import '../account/account_screen.dart';
import '../chat/chat_screen.dart';
import '../history/screening_history_screen.dart';
import '../reminders/reminder_screen.dart';
import '../screening/new_screening_screen.dart';

// Mirrors (protected)/dashboard/page.tsx's PATIENT view: the survey-explanation box + a
// "talk to the AI chatbot" card — plus quick links to the other Patient-role screens
// (New Screening, History, Reminder, Account), which the web app reaches via the sidebar
// instead of a dashboard card since it has permanent nav chrome and this doesn't yet.
class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key});

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
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'This app uses a two-stage survey: first a Yes/No for each symptom, then a '
                '1–4 severity rating if you answered Yes. Your responses help your care team '
                'spot ARV side effects early.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text('Need help now?'),
              subtitle: const Text('Talk to our AI symptom-triage assistant.'),
              trailing: FilledButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatScreen())),
                child: const Text('Start Chat'),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _NavCard(
            icon: Icons.fact_check_outlined,
            title: 'New Screening',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewScreeningScreen())),
          ),
          _NavCard(
            icon: Icons.history,
            title: 'Screening History',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScreeningHistoryScreen())),
          ),
          _NavCard(
            icon: Icons.notifications_active_outlined,
            title: 'Medication Reminder',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReminderScreen())),
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
