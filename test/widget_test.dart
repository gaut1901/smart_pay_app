import 'package:flutter_test/flutter_test.dart';
import 'package:smartpay_flutter/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartPayApp());

    // Verify that login screen is shown (contains "Login" text or similar)
    expect(find.textContaining('Login'), findsAtLeast(1));
  });
}
