import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'risk.dart';

// Consolidates the risk-level chip that was hand-rolled slightly differently in
// screening_history_screen.dart (plain "emoji + label" Text), patient_detail_screen.dart
// (same pattern), and my_reports_screen.dart's own local _RiskBadge widget — one soft pill
// instead of three near-duplicate implementations. Text uses theme.dart's labelSmall (one
// consistent 12px small-label size) instead of a one-off inline fontSize.
class RiskPill extends StatelessWidget {
  final String risk; // key into shared/risk.dart's riskInfo
  const RiskPill({super.key, required this.risk});

  @override
  Widget build(BuildContext context) {
    final info = riskInfo[risk];
    if (info == null) return Text(risk);
    final labelStyle = Theme.of(context).textTheme.labelSmall!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(info.emoji, style: labelStyle),
          const SizedBox(width: AppSpacing.xs),
          Text(info.label, style: labelStyle.copyWith(color: info.color)),
        ],
      ),
    );
  }
}
