import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiv_project_app/core/api_client.dart';
import 'package:hiv_project_app/features/admin/screening_questions/screening_questions_screen.dart';
import 'package:hiv_project_app/shared/i18n.dart';

// Regression test for search + pagination on the admin Screening Questions list — page size
// is 10, so a 15-question fixture forces a real second page and exercises the Next/Previous
// controls, not just render-everything-on-one-page.
class _FakeAdapter implements HttpClientAdapter {
  final List<Map<String, dynamic>> questions;
  _FakeAdapter(this.questions);

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/screening/domains' && options.method == 'GET') {
      return _json({'domains': []});
    }
    if (options.path == '/admin/screening-questions' && options.method == 'GET') {
      return _json({'questions': questions});
    }
    throw StateError('Unhandled request: ${options.method} ${options.path}');
  }

  ResponseBody _json(Map<String, dynamic> body) {
    final bytes = utf8.encode(jsonEncode(body));
    return ResponseBody.fromBytes(bytes, 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }
}

Map<String, dynamic> _question(int i) => {
      'id': i,
      'domainKey': 'gastrointestinal',
      'key': 'symptom_$i',
      'questionEn': 'Question number $i',
      'questionId': 'Pertanyaan nomor $i',
      'stage2Options': [
        {'labelEn': 'a', 'labelId': 'a', 'score': 1},
      ],
      'redFlagAtScore': null,
    };

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  const secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  testWidgets('paginates 15 questions into pages of 10, Next/Previous work', (tester) async {
    // ListView slivers only mount elements within the viewport+cache extent, regardless of
    // children: vs .builder — a 10-card page plus the pagination row don't fit the default
    // 800x600 test surface, so later items genuinely aren't built (not just offstage).
    // Enlarge the surface so everything on one page fits without needing to scroll.
    tester.view.physicalSize = const Size(800, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fake = _FakeAdapter(List.generate(15, (i) => _question(i)));
    final originalAdapter = dio.httpClientAdapter;
    dio.httpClientAdapter = fake;
    addTearDown(() => dio.httpClientAdapter = originalAdapter);

    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: ScreeningQuestionsScreen())));
    await _settle(tester);

    // Page 1: questions 0-9 shown, 10-14 not.
    expect(find.text('Question number 0', skipOffstage: false), findsOneWidget);
    expect(find.text('Question number 9', skipOffstage: false), findsOneWidget);
    expect(find.text('Question number 10', skipOffstage: false), findsNothing);
    expect(find.text(AppStrings.pageOf(1, 2), skipOffstage: false), findsOneWidget);

    // Previous/Next live in the Scaffold's bottomNavigationBar now (icon buttons with a
    // tooltip, not a labeled TextButton) — found by tooltip since that's their accessible name.
    var prevButton = tester.widget<IconButton>(find.ancestor(of: find.byTooltip(AppStrings.t('previous'), skipOffstage: false), matching: find.byType(IconButton)));
    expect(prevButton.onPressed, isNull, reason: 'Previous should be disabled on page 1');

    // Invoke Next directly rather than simulate a tap — same reasoning as the edit-flow test:
    // exact hit-test offsets through a long scrolled list aren't the thing under test here.
    tester.widget<IconButton>(find.ancestor(of: find.byTooltip(AppStrings.t('next'), skipOffstage: false), matching: find.byType(IconButton))).onPressed!();
    await _settle(tester);

    // Page 2: questions 10-14 shown, 0-9 not.
    expect(find.text('Question number 10', skipOffstage: false), findsOneWidget);
    expect(find.text('Question number 14', skipOffstage: false), findsOneWidget);
    expect(find.text('Question number 0', skipOffstage: false), findsNothing);
    expect(find.text(AppStrings.pageOf(2, 2), skipOffstage: false), findsOneWidget);

    // Next is disabled on the last page.
    final nextButton = tester.widget<IconButton>(find.ancestor(of: find.byTooltip(AppStrings.t('next'), skipOffstage: false), matching: find.byType(IconButton)));
    expect(nextButton.onPressed, isNull);

    // Back to page 1 via Previous.
    prevButton = tester.widget<IconButton>(find.ancestor(of: find.byTooltip(AppStrings.t('previous'), skipOffstage: false), matching: find.byType(IconButton)));
    prevButton.onPressed!();
    await _settle(tester);
    expect(find.text('Question number 0', skipOffstage: false), findsOneWidget);
    expect(find.text(AppStrings.pageOf(1, 2), skipOffstage: false), findsOneWidget);
  });

  testWidgets('search filters the list and resets to page 1', (tester) async {
    tester.view.physicalSize = const Size(800, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fake = _FakeAdapter(List.generate(15, (i) => _question(i)));
    final originalAdapter = dio.httpClientAdapter;
    dio.httpClientAdapter = fake;
    addTearDown(() => dio.httpClientAdapter = originalAdapter);

    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: ScreeningQuestionsScreen())));
    await _settle(tester);

    // Go to page 2 first, to prove searching resets back to page 1.
    tester.widget<IconButton>(find.ancestor(of: find.byTooltip(AppStrings.t('next'), skipOffstage: false), matching: find.byType(IconButton))).onPressed!();
    await _settle(tester);
    expect(find.text('Question number 10', skipOffstage: false), findsOneWidget);

    // Search for a specific question ("14" only matches one, by number in the text).
    await tester.enterText(find.byType(TextField), '14');
    await _settle(tester);

    expect(find.text('Question number 14', skipOffstage: false), findsOneWidget);
    expect(find.text('Question number 0', skipOffstage: false), findsNothing);
    expect(find.text('Question number 10', skipOffstage: false), findsNothing);
    // Single result — no pagination controls shown (bottomNavigationBar is null).
    expect(find.byTooltip(AppStrings.t('previous'), skipOffstage: false), findsNothing);

    // Search for something matching nothing.
    await tester.enterText(find.byType(TextField), 'zzz_no_match');
    await _settle(tester);
    expect(find.text(AppStrings.t('noQuestionsMatchSearch'), skipOffstage: false), findsOneWidget);
  });
}
