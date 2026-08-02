import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiv_project_app/core/api_client.dart';
import 'package:hiv_project_app/features/admin/screening_questions/screening_questions_screen.dart';

// Regression test for the admin "Edit screening question" feature — drives the real screen
// (list -> tap edit -> prefilled form -> change a field -> save) through Flutter's test
// framework rather than an OS-level tap on a simulator (unreliable in this project's dev
// environment, see HIV-Project-App/CLAUDE.md's Environment section), with a fake HttpClientAdapter
// standing in for the real backend so the assertions are deterministic.
class _FakeAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  Map<String, dynamic>? lastPatchBody;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    if (options.path == '/screening/domains' && options.method == 'GET') {
      return _json({
        'domains': [
          {
            'key': 'gastrointestinal',
            'label': {'en': 'Gastrointestinal', 'id': 'Gastrointestinal'},
            'symptoms': [],
          },
        ],
      });
    }

    if (options.path == '/admin/screening-questions' && options.method == 'GET') {
      return _json({
        'questions': [
          {
            'id': 1,
            'domainKey': 'gastrointestinal',
            'key': 'nausea_custom',
            'questionEn': 'Old question text',
            'questionId': 'Teks pertanyaan lama',
            'stage2Options': [
              {'labelEn': 'a', 'labelId': 'a', 'score': 1},
              {'labelEn': 'b', 'labelId': 'b', 'score': 2},
              {'labelEn': 'c', 'labelId': 'c', 'score': 3},
              {'labelEn': 'd', 'labelId': 'd', 'score': 4},
            ],
            'redFlagAtScore': null,
          },
        ],
      });
    }

    if (options.path == '/admin/screening-questions/1' && options.method == 'PATCH') {
      lastPatchBody = options.data as Map<String, dynamic>;
      return _json({'ok': true, 'question': lastPatchBody});
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

// CircularProgressIndicator's AnimationController.repeat() schedules frames forever while
// visible, so pumpAndSettle (which waits for zero pending frames) hangs on any loading state —
// bounded pumps instead, giving async fetches room to resolve without demanding animations stop.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  // api_client.dart's request interceptor awaits TokenStorage.read() (flutter_secure_storage)
  // on every call — that's a platform MethodChannel with no real implementation in a plain
  // widget test, so it never resolves and the FutureProvider hangs forever. Mock it to return
  // null (no stored token), same as a logged-out app cold start.
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

  testWidgets('editing an existing screening question prefills the form and PATCHes', (tester) async {
    final fake = _FakeAdapter();
    final originalAdapter = dio.httpClientAdapter;
    dio.httpClientAdapter = fake;
    addTearDown(() => dio.httpClientAdapter = originalAdapter);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ScreeningQuestionsScreen()),
      ),
    );
    await _settle(tester);

    // List loaded with the one fake question.
    expect(find.text('Old question text'), findsOneWidget);

    // Tap its edit icon.
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await _settle(tester);

    // Form is prefilled from the existing question.
    expect(find.widgetWithText(TextFormField, 'Old question text'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Teks pertanyaan lama'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'nausea_custom'), findsOneWidget);

    // Change the English question text.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Old question text'),
      'New question text',
    );

    // Save is the last field in a long ListView, past the app's custom page-transition overlay
    // geometry — rather than fight scroll/hit-test offsets through that, invoke the button's
    // onPressed directly. Exercises the same _submit() logic a real tap would (validation,
    // PATCH body, invalidate, pop); only the literal tap-gesture recognition is skipped.
    final saveButton = tester.widget<FilledButton>(find.byType(FilledButton, skipOffstage: false));
    saveButton.onPressed!();
    await _settle(tester);

    // PATCH actually fired against the right id, with the edited value.
    expect(fake.lastPatchBody, isNotNull);
    expect(fake.lastPatchBody!['questionEn'], 'New question text');
    expect(fake.requests.any((r) => r.method == 'PATCH' && r.path == '/admin/screening-questions/1'), isTrue);

    // Popped back to the list, which re-fetched (ref.invalidate) rather than showing stale data.
    expect(find.byType(ScreeningQuestionsScreen), findsOneWidget);
    final getCount = fake.requests
        .where((r) => r.method == 'GET' && r.path == '/admin/screening-questions')
        .length;
    expect(getCount, greaterThanOrEqualTo(2), reason: 'list should re-fetch after a successful edit');
  });
}
