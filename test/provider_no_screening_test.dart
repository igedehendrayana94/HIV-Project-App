import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiv_project_app/features/provider/home/provider_home_screen.dart';
import 'package:hiv_project_app/shared/i18n.dart';

// Regression check for the "Provider can no longer conduct a screening" removal — confirms
// ProviderHomeScreen's card list no longer offers "New Screening" (the removed card), while
// its other two cards (Register Patient, Medication Reminders) still render correctly, proving
// the screen itself isn't just broken/empty.
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

  testWidgets('Provider home no longer offers New Screening', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ProviderHomeScreen()),
      ),
    );
    await _settle(tester);

    expect(find.text(AppStrings.t('newScreening')), findsNothing);
    expect(find.text(AppStrings.t('registerPatient')), findsOneWidget);
    expect(find.text(AppStrings.t('medicationReminders')), findsOneWidget);
  });
}
