import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Small pulsing indicator for anything actively polling — mirrors the web app's
// ConsultationRow.tsx urgency-pulse precedent (a small motion cue reads as "live" without
// the whole-row oscillation that fights readability, per that component's own reasoning).
class LiveDot extends StatelessWidget {
  final Color? color;
  const LiveDot({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final dotColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeOut(duration: 900.ms, curve: Curves.easeInOut);
  }
}
