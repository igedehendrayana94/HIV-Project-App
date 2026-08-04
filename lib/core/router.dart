import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_state.dart';
import 'locale_state.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/landing/landing_screen.dart';
import '../features/admin/admin_shell.dart';
import '../features/patient/patient_shell.dart';
import '../features/provider/provider_shell.dart';
import '../features/provider/consultations/consultation_thread_screen.dart';

// Module-level (not created inside routerProvider) so its identity survives the router being
// torn down/recreated on every auth/locale change (see the ref.watch(localeProvider) comment
// below) — a push-notification tap needs a stable way to reach the current navigator/context
// from outside the widget tree, where a route id isn't otherwise reachable.
final rootNavigatorKey = GlobalKey<NavigatorState>();

// Client-side reimplementation of src/proxy.ts's redirect rules (no middleware layer exists
// in Flutter). Rebuilds whenever authProvider changes — acceptable for auth transitions
// (login/logout), which are rare compared to normal in-app navigation. Role-specific
// StatefulShellRoute branches (persistent bottom nav, see *_shell.dart) are picked per the
// current role here since the whole router is already rebuilt on every auth change anyway —
// no need for a separate role-dispatcher widget the way the old flat "/home" route needed.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final role = authState.value?.role;
  // AppStrings.locale is a bare static field — mutating it doesn't itself rebuild anything,
  // and every screen's own build() reads it without watching localeProvider (only the
  // Account screen does, for its own toggle button). Combined with the per-role
  // StatefulShellRoute.indexedStack keeping every tab's widget alive/cached, a screen that
  // isn't currently on-screen when the user toggles language never gets a rebuild at all —
  // it stays frozen showing whatever locale it first rendered in. Watching localeProvider
  // here forces GoRouter itself (and every cached shell branch under it) to be torn down
  // and recreated on toggle, which is what actually makes every screen re-render fresh
  // against the new locale — a plain root-level rebuild doesn't reach into GoRouter's own
  // persistent page cache. Trade-off: toggling language also resets navigation back to the
  // shell's home tab, since the recreated router starts over at initialLocation.
  ref.watch(localeProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      if (authState.isLoading) return null;
      final loggedIn = authState.value != null;
      final onPreAuthScreen = state.matchedLocation == '/' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';
      if (!loggedIn) return onPreAuthScreen ? null : '/';
      if (onPreAuthScreen) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LandingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      // Reachable regardless of which role's shell is active — the only way a cold-started
      // push-notification tap (see push_notifications.dart) can deep-link into a thread,
      // since ConsultationThreadScreen otherwise only exists behind an imperative
      // Navigator.push from inside the inbox/chat screens (no go_router path of its own).
      GoRoute(
        path: '/consultations/:id',
        builder: (context, state) => ConsultationThreadScreen(
          consultationId: int.parse(state.pathParameters['id']!),
          isProviderView: role != 'PATIENT',
        ),
      ),
      if (role == 'PATIENT') ...patientShellRoutes(),
      if (role == 'PROVIDER') ...providerShellRoutes(),
      if (role == 'ADMIN') ...adminShellRoutes(),
      if (role == null)
        GoRoute(path: '/home', builder: (context, state) => const Scaffold(body: Center(child: CircularProgressIndicator()))),
    ],
  );
});
