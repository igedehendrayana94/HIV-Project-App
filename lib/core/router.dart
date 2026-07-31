import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_state.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/landing/landing_screen.dart';
import '../features/admin/admin_shell.dart';
import '../features/patient/patient_shell.dart';
import '../features/provider/provider_shell.dart';

// Client-side reimplementation of src/proxy.ts's redirect rules (no middleware layer exists
// in Flutter). Rebuilds whenever authProvider changes — acceptable for auth transitions
// (login/logout), which are rare compared to normal in-app navigation. Role-specific
// StatefulShellRoute branches (persistent bottom nav, see *_shell.dart) are picked per the
// current role here since the whole router is already rebuilt on every auth change anyway —
// no need for a separate role-dispatcher widget the way the old flat "/home" route needed.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final role = authState.value?.role;

  return GoRouter(
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
      if (role == 'PATIENT') ...patientShellRoutes(),
      if (role == 'PROVIDER') ...providerShellRoutes(),
      if (role == 'ADMIN') ...adminShellRoutes(),
      if (role == null)
        GoRoute(path: '/home', builder: (context, state) => const Scaffold(body: Center(child: CircularProgressIndicator()))),
    ],
  );
});
