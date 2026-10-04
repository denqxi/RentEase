import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/constants/app_links.dart';
import 'package:rentease/core/theme/app_theme.dart';
import 'package:rentease/core/utils/url_opener.dart';
import 'package:rentease/features/admin/view/pending_verifications_screen.dart';

class _FakeOpener implements UrlOpener {
  _FakeOpener({this.result = true});
  final bool result;
  final opened = <Uri>[];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return result;
  }
}

const _label = 'Check business permit (NegosyoKonek)';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('tap opens the NegosyoKonek URI and shows owner name', (
    tester,
  ) async {
    final opener = _FakeOpener();
    await tester.pumpWidget(
      _wrap(
        BusinessPermitCheckButton(ownerName: 'Maria Santos', urlOpener: opener),
      ),
    );
    expect(find.text('Owner: Maria Santos'), findsOneWidget);
    await tester.tap(find.text(_label));
    await tester.pump();
    expect(opener.opened, [Uri.parse(AppLinks.dtiNegosyoKonekSearch)]);
  });

  testWidgets('shows destructive SnackBar when it cannot open', (tester) async {
    final opener = _FakeOpener(result: false);
    await tester.pumpWidget(
      _wrap(
        BusinessPermitCheckButton(ownerName: 'Ana Reyes', urlOpener: opener),
      ),
    );
    await tester.tap(find.text(_label));
    await tester.pump();
    expect(find.textContaining('Could not open'), findsOneWidget);
  });

  testWidgets('viewer shows button only for the permit', (tester) async {
    final opener = _FakeOpener();
    Widget viewer({bool permit = false}) => MaterialApp(
      theme: AppTheme.light,
      home: DocumentViewerDialog(
        title: 't',
        url: 'u',
        reference: 'r',
        permitCheck: permit
            ? (ownerName: 'Juan dela Cruz', urlOpener: opener)
            : null,
      ),
    );
    await tester.pumpWidget(viewer());
    expect(find.text(_label), findsNothing);
    await tester.pumpWidget(viewer(permit: true));
    expect(find.text(_label), findsOneWidget);
    await tester.tap(find.text(_label));
    await tester.pump();
    expect(opener.opened, hasLength(1));
  });
}
