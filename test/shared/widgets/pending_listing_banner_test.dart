import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/constants/app_colors.dart';
import 'package:rentease/core/theme/app_theme.dart';
import 'package:rentease/shared/widgets/pending_listing_banner.dart';

Future<void> _pump(WidgetTester t, String? status) => t.pumpWidget(
  MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: PendingListingBanner(status: status)),
  ),
);

void main() {
  testWidgets('none shows the get-badge copy', (t) async {
    await _pump(t, 'none');
    expect(find.text(PendingListingBanner.noneMessage), findsOneWidget);
    expect(find.textContaining('Get the Verified badge'), findsOneWidget);
  });

  testWidgets('pending keeps the pending copy', (t) async {
    await _pump(t, 'pending');
    expect(find.text(PendingListingBanner.pendingMessage), findsOneWidget);
  });

  testWidgets('rejected shows destructive copy and color', (t) async {
    await _pump(t, 'rejected');
    expect(find.text(PendingListingBanner.rejectedMessage), findsOneWidget);
    final box = t.widget<Container>(find.byType(Container).first);
    final deco = box.decoration! as BoxDecoration;
    expect((deco.border! as Border).top.color, AppColors.destructive);
  });
}
