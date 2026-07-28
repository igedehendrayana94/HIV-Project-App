import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/async_error_view.dart';
import 'consultation_thread_screen.dart';
import 'consultations_provider.dart';
import 'models.dart';

const _urgencyColors = {
  'EMERGENCY': Colors.red,
  'URGENT': Colors.orange,
  'ROUTINE': Colors.blueGrey,
};

class ConsultationsInboxScreen extends ConsumerWidget {
  const ConsultationsInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(consultationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Live Consultations')),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            AsyncErrorView(message: apiErrorMessage(e), onRetry: () => ref.invalidate(consultationsProvider)),
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.refresh(consultationsProvider.future),
          child: items.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 120),
                    Center(child: Text('No open consultations.')),
                  ],
                )
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => _ConsultationRow(item: items[i]),
                ),
        ),
      ),
    );
  }
}

class _ConsultationRow extends ConsumerWidget {
  final ConsultationSummary item;
  const _ConsultationRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _urgencyColors[item.urgency],
        child: Text(item.urgency[0]),
      ),
      title: Text(item.patientName),
      subtitle: Text(
        '${item.status}${item.assignedProviderName != null ? " · ${item.assignedProviderName}" : " · unclaimed"}',
      ),
      trailing: Text(item.createdAt.toLocal().toString().split(' ').first),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ConsultationThreadScreen(consultationId: item.id)),
        );
        ref.invalidate(consultationsProvider);
      },
    );
  }
}
