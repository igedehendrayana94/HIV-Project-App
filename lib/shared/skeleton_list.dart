import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme.dart';

// Shimmering placeholder rows for a screen's initial load — swapped in for a bare
// CircularProgressIndicator on the highest-traffic list screens (home tabs, consultations
// inbox, history). Reads as "the content is already loading, not the app is stuck."
class SkeletonList extends StatelessWidget {
  final int count;
  const SkeletonList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF1E4E8),
      highlightColor: const Color(0xFFFBF3F5),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, _) => Container(
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
        ),
      ),
    );
  }
}
