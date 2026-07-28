import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_state.dart';
import '../admin/home/admin_home_screen.dart';
import '../patient/home/patient_home_screen.dart';
import '../provider/home/provider_home_screen.dart';

// Dispatches to the real per-role home — all three (Patient, Provider, Admin) are built.
class RoleHomeScreen extends ConsumerWidget {
  const RoleHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authProvider).value?.role;
    return switch (role) {
      'PATIENT' => const PatientHomeScreen(),
      'PROVIDER' => const ProviderHomeScreen(),
      'ADMIN' => const AdminHomeScreen(),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}
