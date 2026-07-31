import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../shared/app_card.dart';
import '../../../shared/async_error_view.dart';
import '../../../shared/confirm_dialog.dart';
import '../../../shared/empty_state.dart';
import '../../../shared/i18n.dart';
import '../../../shared/live_dot.dart';
import 'consultation_thread_screen.dart';
import 'consultations_provider.dart';
import 'models.dart';

const _urgencyColors = {
  'EMERGENCY': Colors.red,
  'URGENT': Colors.orange,
  'ROUTINE': Colors.blueGrey,
};

// StatefulWidget so this screen can own a Timer for silent background polling — same 8s
// interval as this app's web sibling's consultation-queue poll (consultation_thread_screen.dart
// polls its own thread at 10s since that's an active two-way chat; this is a queue glance).
class ConsultationsInboxScreen extends ConsumerStatefulWidget {
  const ConsultationsInboxScreen({super.key});

  @override
  ConsumerState<ConsultationsInboxScreen> createState() => _ConsultationsInboxScreenState();
}

const _urgencyFilters = ['All', 'EMERGENCY', 'URGENT', 'ROUTINE'];

class _ConsultationsInboxScreenState extends ConsumerState<ConsultationsInboxScreen> {
  Timer? _timer;
  String _urgencyFilter = 'All';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => ref.invalidate(consultationsProvider));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(consultationsProvider);
    // Keep showing the last-known list while a background poll is in flight instead of
    // flashing the loading spinner every 8s — only fall back to the full loading/error
    // states when there's no data to show yet.
    final items = listAsync.value;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppStrings.t('liveConsultations')),
            const SizedBox(width: AppSpacing.sm),
            const LiveDot(),
          ],
        ),
      ),
      body: items == null
          ? listAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AsyncErrorView(
                  message: apiErrorMessage(e), onRetry: () => ref.invalidate(consultationsProvider)),
              data: (_) => const SizedBox.shrink(),
            )
          : _buildList(items),
    );
  }

  Widget _buildList(List<ConsultationSummary> items) {
    final filtered =
        _urgencyFilter == 'All' ? items : items.where((i) => i.urgency == _urgencyFilter).toList();
    return RefreshIndicator(
      onRefresh: () => ref.refresh(consultationsProvider.future),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // No i18n keys for these urgency filter labels — left as plain English.
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _urgencyFilters.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, i) {
                final f = _urgencyFilters[i];
                return ChoiceChip(
                  label: Text(f == 'All' ? f : '${f[0]}${f.substring(1).toLowerCase()}'),
                  selected: _urgencyFilter == f,
                  onSelected: (_) => setState(() => _urgencyFilter = f),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (filtered.isEmpty)
            EmptyState(
              icon: Icons.forum_outlined,
              message: items.isEmpty ? AppStrings.t('noOpenConsultations') : 'No matching consultations.',
            )
          else
            for (var i = 0; i < filtered.length; i++) ...[
              _ConsultationRow(item: filtered[i], index: i),
              if (i != filtered.length - 1) const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _ConsultationRow extends ConsumerWidget {
  final ConsultationSummary item;
  final int index;
  const _ConsultationRow({required this.item, required this.index});

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAction(
      context,
      title: AppStrings.t('areYouSure'),
      message: AppStrings.t('rejectConfirmMessage'),
      confirmLabel: AppStrings.t('reject'),
      destructive: true,
    );
    if (!ok) return;
    if (!context.mounted) return;
    try {
      await dio.post('/consultations/${item.id}/reject');
      ref.invalidate(consultationsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urgencyColor = _urgencyColors[item.urgency] ?? Colors.blueGrey;
    // Reject is only valid for an unclaimed, still-OPEN row — same guard the backend
    // enforces (consultations/[id]/reject/route.ts) — once claimed the only path forward is
    // the thread screen's Claim → Mark Resolved flow, not this.
    final canReject = item.assignedProviderName == null && item.status == 'OPEN';
    return AppCard(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ConsultationThreadScreen(consultationId: item.id)),
        );
        ref.invalidate(consultationsProvider);
      },
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: urgencyColor,
            child: Text(item.urgency[0], style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.patientName, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: urgencyColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: Text(item.urgency,
                          style: Theme.of(context).textTheme.labelSmall!.copyWith(color: urgencyColor)),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        // ponytail: "unclaimed" has no i18n key in i18n.dart — left as an
                        // English literal per the no-new-keys rule.
                        '${item.status}${item.assignedProviderName != null ? " · ${item.assignedProviderName}" : " · unclaimed"}',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.createdAt.toLocal().toString().split(' ').first,
                  style: Theme.of(context).textTheme.bodySmall),
              if (canReject)
                IconButton(
                  icon: Icon(Icons.close, color: Theme.of(context).colorScheme.error),
                  tooltip: AppStrings.t('reject'),
                  onPressed: () => _reject(context, ref),
                )
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ],
      ),
    ).animate(delay: (index * 60).ms).fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }
}
