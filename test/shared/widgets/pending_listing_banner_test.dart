import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/constants/app_colors.dart';
import 'package:rentease/core/theme/app_theme.dart';
import 'package:rentease/shared/widgets/pending_listing_banner.dart';

// One instance for every pump: `AppTheme.light` is a getter that builds a new
// ThemeData, which would make MaterialApp's AnimatedTheme tween (and schedule
// frames) on each re-pump, masking the banner's own ticker state.
final ThemeData _theme = AppTheme.light;

Future<void> _pump(WidgetTester t, String? status) => t.pumpWidget(
  MaterialApp(
    theme: _theme,
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

  testWidgets('rejected schedules no frames; pending keeps spinning', (t) async {
    await _pump(t, 'rejected');
    await t.pump();
    expect(t.binding.hasScheduledFrame, isFalse);

    await _pump(t, 'pending');
    await t.pump();
    expect(t.binding.hasScheduledFrame, isTrue);

    // Switching back to rejected stops the ticker again.
    await _pump(t, 'rejected');
    await t.pump();
    expect(t.binding.hasScheduledFrame, isFalse);
  });
}
