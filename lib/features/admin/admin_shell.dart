import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/i18n.dart';
import '../patient/account/account_screen.dart';
import '../provider/consultations/consultations_inbox_screen.dart';
import 'home/admin_home_screen.dart';
import 'users/users_screen.dart';

List<RouteBase> adminShellRoutes() => [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => _AdminScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const AdminHomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/consultations', builder: (_, _) => const ConsultationsInboxScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/users', builder: (_, _) => const UsersScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/account', builder: (_, _) => const AccountScreen())]),
        ],
      ),
    ];

class _AdminScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const _AdminScaffold({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: AppStrings.t('home')),
          NavigationDestination(icon: const Icon(Icons.forum_outlined), selectedIcon: const Icon(Icons.forum), label: AppStrings.t('consultationsTab')),
          NavigationDestination(icon: const Icon(Icons.people_outline), selectedIcon: const Icon(Icons.people), label: AppStrings.t('users')),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: AppStrings.t('accountTab')),
        ],
      ),
    );
  }
}
