import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth_state.dart';
import '../../../shared/i18n.dart';
import '../../patient/account/account_screen.dart';
import '../consultations/consultations_inbox_screen.dart';

class ProviderHomeScreen extends ConsumerWidget {
  const ProviderHomeScreen({super.key});

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
            child: ListTile(
              leading: const Icon(Icons.forum_outlined),
              title: const Text('Live Consultations'),
              subtitle: const Text('Patient chats needing a provider response.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const ConsultationsInboxScreen())),
            ),
          ),
        ],
      ),
    );
  }
}
