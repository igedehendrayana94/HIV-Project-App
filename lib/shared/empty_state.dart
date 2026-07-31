import 'package:flutter/material.dart';
import '../core/theme.dart';

// Replaces every bare "No X yet." Text() across the app — a wall of plain text reads as
// "something's broken" in a health app; icon + reassuring copy reads as "nothing here yet,
// that's fine." Optional CTA for screens where the empty state has an obvious next action
// (e.g. "No screenings yet" → "Start a screening").
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
              child: Icon(icon, size: 30, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.md),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
