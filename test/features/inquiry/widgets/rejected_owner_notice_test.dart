import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/firestore/models/models.dart';
import 'package:rentease/core/theme/app_theme.dart';
import 'package:rentease/features/inquiry/cubit/inquiry_thread_cubit.dart';
import 'package:rentease/features/inquiry/domain/services/inquiry_service.dart';
import 'package:rentease/features/inquiry/widgets/owner_invite_view.dart';
import 'package:rentease/features/inquiry/widgets/owner_phase1_view.dart';
import 'package:rentease/features/inquiry/widgets/tenant_phase1_view.dart';

class _FakeThreadCubit extends Cubit<InquiryThreadState>
    implements InquiryThreadCubit {
  _FakeThreadCubit(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

InquiryDoc _inquiry({String initiatedBy = 'tenant'}) => InquiryDoc(
  inquiryId: 'i1',
  matchId: 'm1',
  tenantId: 't1',
  ownerId: 'o1',
  propertyId: 'p1',
  tenantCiSnapshot: 0.8,
  stage: 1,
  initiatedBy: initiatedBy,
  status: 'pending',
  ownerDecision: 'pending',
  autoInfoSent: true,
);

Future<void> _pump(WidgetTester tester, InquiryThreadState state, Widget view) {
  tester.view.physicalSize = const Size(320 * 3, 640 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: BlocProvider<InquiryThreadCubit>.value(
          value: _FakeThreadCubit(state),
          child: view,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('rejected owner: Accept/Decline replaced by the notice', (t) async {
    await _pump(
      t,
      InquiryThreadState(
        isLoading: false,
        inquiry: _inquiry(),
        ownerRejected: true,
      ),
      const OwnerPhase1View(),
    );
    expect(find.text(InquiryService.rejectedOwnerMessage), findsOneWidget);
    expect(find.text('Accept'), findsNothing);
    expect(find.text('Decline'), findsNothing);
  });

  testWidgets('non-rejected owner still sees Accept and Decline', (t) async {
    await _pump(
      t,
      InquiryThreadState(isLoading: false, inquiry: _inquiry()),
      const OwnerPhase1View(),
    );
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    expect(find.text(InquiryService.rejectedOwnerMessage), findsNothing);
  });

  testWidgets('rejected owner sees the notice on their invitation view', (t) async {
    await _pump(
      t,
      InquiryThreadState(
        isLoading: false,
        inquiry: _inquiry(initiatedBy: 'owner'),
        ownerRejected: true,
      ),
      const OwnerInviteView(),
    );
    expect(find.text(InquiryService.rejectedOwnerMessage), findsOneWidget);
  });

  testWidgets('tenant: neutral note, no locked input, when the owner is rejected', (
    t,
  ) async {
    await _pump(
      t,
      InquiryThreadState(
        isLoading: false,
        inquiry: _inquiry(),
        ownerRejected: true,
      ),
      const TenantPhase1View(),
    );
    expect(find.text(InquiryService.rejectedOwnerTenantNote), findsOneWidget);
    expect(find.text('Message locked...'), findsNothing);
    expect(find.text(InquiryService.rejectedOwnerMessage), findsNothing);
  });

  testWidgets('tenant with a normal owner keeps the locked input', (t) async {
    await _pump(
      t,
      InquiryThreadState(isLoading: false, inquiry: _inquiry()),
      const TenantPhase1View(),
    );
    expect(find.text('Message locked...'), findsOneWidget);
  });
}
