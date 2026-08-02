import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiv_project_app/main.dart';
import 'package:hiv_project_app/shared/i18n.dart';

void main() {
  testWidgets('app boots to the landing screen when logged out', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MediCareHivApp()));
    await tester.pump();
    expect(find.text(AppStrings.t('landingSignIn')), findsOneWidget);
    expect(find.text(AppStrings.t('landingCreateAccount')), findsOneWidget);
    // The landing page's staggered .animate(delay: ...) entrance effects schedule one-shot
    // Future.delayed timers (up to ~400ms) — flush those by advancing time, then unmount so
    // AmbientGlow's two infinite repeat() animations dispose their tickers too. Otherwise
    // flutter_test's pending-timer leak check fails the test even though nothing is wrong.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox());
  });
}
