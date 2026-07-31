import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';

// Slow ambient motion behind a screen's content — mirrors the web app's landing-page
// HeroGlow (same reasoning: signals "live product" instantly, motivated motion not
// decoration). Meant to sit behind content via a Stack, not as a standalone widget.
class AmbientGlow extends StatelessWidget {
  const AmbientGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [kVibrantPrimary.withValues(alpha: 0.16), Colors.transparent]),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(
                  begin: 1.0,
                  end: 1.15,
                  duration: 4000.ms,
                  curve: Curves.easeInOut,
                ),
          ),
          Positioned(
            top: 40,
            right: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [kBrandSoft.withValues(alpha: 0.22), Colors.transparent]),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(
                  begin: 1.0,
                  end: 1.2,
                  duration: 5000.ms,
                  curve: Curves.easeInOut,
                ),
          ),
        ],
      ),
    );
  }
}
