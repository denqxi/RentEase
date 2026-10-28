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
        home: const DocumentViewerDialog(title: 't', url: 'u', reference: 'r'),
      ),
    );
    expect(find.text('Approve'), findsNothing);
    expect(find.text('Reject'), findsNothing);
  });

  testWidgets(
    'viewer with secondary side allows toggling between front and back',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const DocumentViewerDialog(
            title: 'Government ID (Front) - Maria Santos',
            url: 'https://invalid.invalid/front.jpg',
            reference: 'docs/front123',
            secondaryTitle: 'Government ID (Back) - Maria Santos',
            secondaryUrl: 'https://invalid.invalid/back.jpg',
            secondaryReference: 'docs/back456',
            primaryLabel: 'Front side',
            secondaryLabel: 'Back side',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially on Front side
      expect(find.text('Government ID (Front) - Maria Santos'), findsOneWidget);
      expect(find.text('docs/front123'), findsOneWidget);
      expect(find.text('Front side'), findsOneWidget);
      expect(find.text('Back side'), findsOneWidget);

      // Tap Back side
      await tester.tap(find.text('Back side'));
      await tester.pumpAndSettle();

      expect(find.text('Government ID (Back) - Maria Santos'), findsOneWidget);
      expect(find.text('docs/back456'), findsOneWidget);

      // Tap Front side
      await tester.tap(find.text('Front side'));
      await tester.pumpAndSettle();

      expect(find.text('Government ID (Front) - Maria Santos'), findsOneWidget);
      expect(find.text('docs/front123'), findsOneWidget);
    },
  );

  testWidgets(
    'viewer opens with secondary side when initialSideIsSecondary is true',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const DocumentViewerDialog(
            title: 'Government ID (Front) - Maria Santos',
            url: 'https://invalid.invalid/front.jpg',
            reference: 'docs/front123',
            secondaryTitle: 'Government ID (Back) - Maria Santos',
            secondaryUrl: 'https://invalid.invalid/back.jpg',
            secondaryReference: 'docs/back456',
            initialSideIsSecondary: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Government ID (Back) - Maria Santos'), findsOneWidget);
      expect(find.text('docs/back456'), findsOneWidget);
    },
  );
}
