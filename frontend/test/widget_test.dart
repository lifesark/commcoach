// This is a basic Flutter widget test for CommCoach app.

import 'package:flutter_test/flutter_test.dart';
import 'package:commcoach/main.dart';

void main() {
  testWidgets('CommCoach app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CommCoachApp());

    // Verify that the app initializes without errors.
    // Note: Since the app uses routing and requires Supabase initialization,
    // more comprehensive tests should be added with proper mocking.
    expect(find.byType(CommCoachApp), findsOneWidget);
  });
}
