import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/theme/app_theme.dart';
import 'package:rentease/features/admin/view/pending_verifications_screen.dart';

void main() {
  testWidgets('viewer shows error message, public id and actions', (
    tester,
  ) async {
    var approved = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: DocumentViewerDialog(
          title: 'Government ID - Maria Santos',
          url: 'https://invalid.invalid/x.jpg',
          reference: 'rentease/docs/abc123',
          onApprove: () => approved = true,
          onReject: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(documentLoadErrorMessage), findsOneWidget);
    expect(find.text('rentease/docs/abc123'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.tap(find.text('Approve'));
    expect(approved, isTrue);
  });

  testWidgets('viewer hides actions when none given', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: DocumentViewerDialog(title: 't', url: 'u', reference: 'r'),
      ),
    );
    expect(find.text('Approve'), findsNothing);
    expect(find.text('Reject'), findsNothing);
  });
}
