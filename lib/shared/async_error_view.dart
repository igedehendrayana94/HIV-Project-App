import 'package:flutter/material.dart';
import 'i18n.dart';

// One consistent error state for every FutureProvider `.when()` error branch — was a bare
// Center(Text(...)) with no way to recover short of leaving and re-entering the screen.
class AsyncErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AsyncErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: Text(AppStrings.t('retry'))),
          ],
        ),
      ),
    );
  }
}
