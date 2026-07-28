import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiv_project_app/main.dart';

void main() {
  testWidgets('app boots to the login screen when logged out', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MediCareHivApp()));
    await tester.pump();
    expect(find.text('Log In'), findsOneWidget);
  });
}
