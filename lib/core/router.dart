import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_state.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/home/role_home_screen.dart';

// Client-side reimplementation of src/proxy.ts's redirect rules (no middleware layer exists
// in Flutter). Rebuilds whenever authProvider changes — acceptable for auth transitions
// (login/logout), which are rare compared to normal in-app navigation.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      if (authState.isLoading) return null;
      final loggedIn = authState.value != null;
      final onAuthScreen = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
      if (!loggedIn) return onAuthScreen ? null : '/login';
      if (onAuthScreen) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(path: '/home', builder: (context, state) => const RoleHomeScreen()),
    ],
  );
});
