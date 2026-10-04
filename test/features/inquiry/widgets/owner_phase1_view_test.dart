import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/firestore/models/models.dart';
import 'package:rentease/core/theme/app_theme.dart';
import 'package:rentease/features/inquiry/cubit/inquiry_thread_cubit.dart';
import 'package:rentease/features/inquiry/widgets/owner_phase1_view.dart';

class _FakeThreadCubit extends Cubit<InquiryThreadState>
    implements InquiryThreadCubit {
  _FakeThreadCubit(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('owner Phase 1 summary never shows an emergency contact', (
    tester,
  ) async {
    final state = InquiryThreadState(
      isLoading: false,
      inquiry: const InquiryDoc(
        inquiryId: 'i1',
        matchId: 'm1',
        tenantId: 't1',
        ownerId: 'o1',
        propertyId: 'p1',
        tenantCiSnapshot: 0.8,
        stage: 1,
        initiatedBy: 'tenant',
        status: 'pending',
        ownerDecision: 'pending',
        autoInfoSent: true,
      ),
      tenantProfile: TenantProfileDoc.fromMap('t1', {
        'school': 'USEP',
        // A legacy, not-yet-migrated value must still never be rendered.
        'emergencyContact': 'Rosa Santos 09171234567',
      }),
    );
    final cubit = _FakeThreadCubit(state);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: BlocProvider<InquiryThreadCubit>.value(
            value: cubit,
            child: const OwnerPhase1View(),
          ),
        ),
      ),
    );

    expect(find.text('USEP'), findsOneWidget);
    expect(find.textContaining('Emergency'), findsNothing);
    expect(find.textContaining('Rosa Santos'), findsNothing);
  });
}
