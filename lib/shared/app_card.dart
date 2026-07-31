import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'bouncy.dart';

// Standard soft rounded surface — reads theme.dart's cardTheme, so this exists only to
// standardize the padding/tap-target wrapping every screen was hand-rolling slightly
// differently, not to override the shape/color (that stays theme-driven). Tappable cards
// route through Bouncy for spring-scale press feedback — the single place this app's cards
// get "visible animation on any action" without hand-wiring it per screen.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  // Padding defaults to lg (24), not md (16) — the card's corner radius is 20, so a
  // smaller padding let content crowd/visually clip into the rounded top-left corner
  // (reported as "overlapping text and border").
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (onTap == null) {
      return Card(child: Padding(padding: padding, child: child));
    }
    return Bouncy(
      onTap: onTap,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
