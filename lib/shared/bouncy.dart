import 'package:flutter/material.dart';

// Spring-scale press feedback for any tappable widget — Flutter has no CSS-`:active`
// equivalent, so this is the one shared wrapper every tappable surface routes through
// instead of each widget hand-rolling its own AnimationController. Scales down on
// tap-down, springs back on release/cancel.
class Bouncy extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const Bouncy({super.key, required this.child, this.onTap});

  @override
  State<Bouncy> createState() => _BouncyState();
}

class _BouncyState extends State<Bouncy> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    lowerBound: 0.0,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _down(_) => _controller.animateTo(0.95, curve: Curves.easeOut);
  void _up(_) => _controller.animateTo(1.0, curve: Curves.elasticOut, duration: const Duration(milliseconds: 350));
  void _cancel() => _controller.animateTo(1.0, curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : _down,
      onTapUp: widget.onTap == null ? null : _up,
      onTapCancel: widget.onTap == null ? null : _cancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(scale: _controller.value, child: child),
        child: widget.child,
      ),
    );
  }
}
