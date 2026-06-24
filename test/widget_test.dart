import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/features/onboarding/view/onboarding_screen.dart';

void main() {
  testWidgets('OnboardingScreen shows the first page and advances on Next',
      (WidgetTester tester) async {
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(onComplete: () => completed = true),
      ),
    );

    // First page content and CTA are visible.
    expect(find.text('Find the right home'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    // Tapping Next advances to the second page.
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Matched to your lifestyle'), findsOneWidget);

    // Skip exits the flow without reaching the last page.
    await tester.tap(find.text('Skip'));
    await tester.pump();
    expect(completed, isTrue);
  });
}
