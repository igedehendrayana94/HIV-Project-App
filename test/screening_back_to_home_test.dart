import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hiv_project_app/features/patient/screening/result_screen.dart';
import 'package:hiv_project_app/shared/i18n.dart';

// Regression test for a real bug: ScreeningResultScreen's "back to home" button
// did nothing when reached from the Screening tab's own shell-branch root (via
// pushReplacement), because it became the root of that branch's nested Navigator
// and Navigator.popUntil(isFirst) had nothing left to pop. Reproduces the exact
// StatefulShellRoute branch-root shape from lib/features/patient/patient_shell.dart.
void main() {
  testWidgets('back-to-home button navigates to the home branch from a shell-branch root',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/screening',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => Scaffold(body: shell),
          branches: [
            StatefulShellBranch(
              routes: [GoRoute(path: '/home', builder: (_, _) => const Text('HOME SCREEN'))],
            ),
            StatefulShellBranch(
              routes: [GoRoute(path: '/screening', builder: (_, _) => const _FakeScreeningRoot())],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    // Simulate NewScreeningScreen._submit()'s pushReplacement onto the branch root.
    await tester.tap(find.text('SUBMIT'));
    await tester.pumpAndSettle();
    expect(find.byType(ScreeningResultScreen), findsOneWidget);

    await tester.tap(find.text(AppStrings.t('backToHome')));
    await tester.pumpAndSettle();

    expect(find.text('HOME SCREEN'), findsOneWidget);
    expect(find.byType(ScreeningResultScreen), findsNothing);
  });
}

class _FakeScreeningRoot extends StatelessWidget {
  const _FakeScreeningRoot();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const ScreeningResultScreen(
                overallRisk: 'LOW',
                redFlag: false,
                domainScores: {},
              ),
            ),
          ),
          child: const Text('SUBMIT'),
        ),
      ),
    );
  }
}
