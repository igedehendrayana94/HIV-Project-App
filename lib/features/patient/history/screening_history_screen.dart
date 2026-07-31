import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../shared/async_error_view.dart';
import '../../../shared/empty_state.dart';
import '../../../shared/risk.dart';
import '../../../shared/risk_pill.dart';
import 'history_provider.dart';

const _riskFilters = ['All', 'LOW', 'MEDIUM', 'HIGH', 'EMERGENCY'];

class ScreeningHistoryScreen extends ConsumerStatefulWidget {
  const ScreeningHistoryScreen({super.key});

  @override
  ConsumerState<ScreeningHistoryScreen> createState() => _ScreeningHistoryScreenState();
}

class _ScreeningHistoryScreenState extends ConsumerState<ScreeningHistoryScreen> {
  String _riskFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(screeningHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Screening History')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            AsyncErrorView(message: apiErrorMessage(e), onRetry: () => ref.invalidate(screeningHistoryProvider)),
        data: (assessments) {
          if (assessments.isEmpty) {
            return const Center(child: Text('No screenings yet.'));
          }
          final filtered = _riskFilter == 'All'
              ? assessments
              : assessments.where((a) => a.overallRisk == _riskFilter).toList();
          return RefreshIndicator(
            onRefresh: () => ref.refresh(screeningHistoryProvider.future),
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _riskFilters.length,
                      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
                      itemBuilder: (context, i) {
                        final f = _riskFilters[i];
                        final label = f == 'All' ? f : riskInfo[f]?.label ?? f;
                        return ChoiceChip(
                          label: Text(label),
                          selected: _riskFilter == f,
                          onSelected: (_) => setState(() => _riskFilter = f),
                        );
                      },
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.xl),
                    child: EmptyState(icon: Icons.search_off, message: 'No screenings match this filter.'),
                  )
                else
                  ...[
                    for (var i = 0; i < filtered.length; i++) ...[
                      ListTile(
                        title: RiskPill(risk: filtered[i].overallRisk),
                        subtitle: Text(filtered[i].createdAt.toLocal().toString()),
                        trailing: filtered[i].redFlag
                            ? Text('RED FLAG',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(color: Theme.of(context).colorScheme.error))
                            : null,
                      ),
                      if (i != filtered.length - 1) const Divider(height: 1),
                    ],
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}
