import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/i18n.dart';
import 'account/account_screen.dart';
import 'chat/chat_screen.dart';
import 'home/patient_home_screen.dart';
import 'reminders/reminder_screen.dart';
import 'screening/new_screening_screen.dart';

// Persistent bottom-nav shell for the PATIENT role — replaces the old flat "/home" route +
// push-only home-screen-as-hub pattern. Each branch keeps its own navigation stack, so
// screens reached by pushing from within a tab (History from Screening, Register Patient
// from Home) are unaffected — only the top-level "which screen am I on" model changed.
List<RouteBase> patientShellRoutes() => [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => _PatientScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const PatientHomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/screening', builder: (_, _) => const NewScreeningScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/chat', builder: (_, _) => const ChatScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/reminder', builder: (_, _) => const ReminderScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/account', builder: (_, _) => const AccountScreen())]),
        ],
      ),
    ];

class _PatientScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const _PatientScaffold({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: AppStrings.t('home')),
          NavigationDestination(icon: const Icon(Icons.fact_check_outlined), selectedIcon: const Icon(Icons.fact_check), label: AppStrings.t('screening')),
          NavigationDestination(icon: const Icon(Icons.chat_bubble_outline), selectedIcon: const Icon(Icons.chat_bubble), label: AppStrings.t('chatTab')),
          NavigationDestination(icon: const Icon(Icons.notifications_outlined), selectedIcon: const Icon(Icons.notifications), label: AppStrings.t('reminderTab')),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: AppStrings.t('accountTab')),
        ],
      ),
    );
  }
}
