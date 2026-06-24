import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/features/registration/cubit/registration_cubit.dart';
import 'package:rentease/features/registration/model/lifestyle_preference.dart';
import 'package:rentease/features/registration/model/property_type.dart';
import 'package:rentease/features/registration/model/registration_step.dart';
import 'package:rentease/features/registration/model/user_role.dart';

void main() {
  group('RegistrationCubit', () {
    test('starts on the role step with no role chosen', () {
      final cubit = RegistrationCubit();
      expect(cubit.state.step, RegistrationStep.role);
      expect(cubit.state.data.role, isNull);
      expect(cubit.state.canContinueFromRole, isFalse);
      cubit.close();
    });

    blocTest<RegistrationCubit, RegistrationState>(
      'selectRole records the role and enables continue',
      build: RegistrationCubit.new,
      act: (cubit) => cubit.selectRole(UserRole.landlord),
      expect: () => <Matcher>[
        isA<RegistrationState>()
            .having((s) => s.data.role, 'role', UserRole.landlord)
            .having((s) => s.canContinueFromRole, 'canContinue', true),
      ],
    );

    blocTest<RegistrationCubit, RegistrationState>(
      'next/back walk forward and backward through the steps',
      build: RegistrationCubit.new,
      act: (cubit) => cubit
        ..next() // role -> account
        ..next() // account -> about
        ..back(), // about -> account
      expect: () => <Matcher>[
        isA<RegistrationState>().having((s) => s.step, 'step',
            RegistrationStep.account),
        isA<RegistrationState>().having((s) => s.step, 'step',
            RegistrationStep.about),
        isA<RegistrationState>().having((s) => s.step, 'step',
            RegistrationStep.account),
      ],
    );

    blocTest<RegistrationCubit, RegistrationState>(
      'next does nothing past the final step',
      build: RegistrationCubit.new,
      seed: () => const RegistrationState(step: RegistrationStep.success),
      act: (cubit) => cubit.next(),
      expect: () => const <RegistrationState>[],
    );

    blocTest<RegistrationCubit, RegistrationState>(
      'toggleLifestyle adds then removes a preference',
      build: RegistrationCubit.new,
      act: (cubit) => cubit
        ..toggleLifestyle(LifestylePreference.familyFriendly)
        ..toggleLifestyle(LifestylePreference.familyFriendly),
      expect: () => <Matcher>[
        isA<RegistrationState>().having(
          (s) => s.data.lifestyles,
          'lifestyles',
          <LifestylePreference>{LifestylePreference.familyFriendly},
        ),
        isA<RegistrationState>().having(
          (s) => s.data.lifestyles,
          'lifestyles',
          isEmpty,
        ),
      ],
    );

    blocTest<RegistrationCubit, RegistrationState>(
      'field updates and preference setters mutate data',
      build: RegistrationCubit.new,
      act: (cubit) => cubit
        ..updateFirstName('Jane')
        ..updateBudget(2200)
        ..selectPropertyType(PropertyType.studio)
        ..setNonSmoker(false),
      expect: () => <Matcher>[
        isA<RegistrationState>()
            .having((s) => s.data.firstName, 'firstName', 'Jane'),
        isA<RegistrationState>().having((s) => s.data.budget, 'budget', 2200),
        isA<RegistrationState>().having(
            (s) => s.data.propertyType, 'propertyType', PropertyType.studio),
        isA<RegistrationState>()
            .having((s) => s.data.nonSmoker, 'nonSmoker', false),
      ],
    );

    blocTest<RegistrationCubit, RegistrationState>(
      'restart returns to the initial state',
      build: RegistrationCubit.new,
      seed: () => const RegistrationState(step: RegistrationStep.success),
      act: (cubit) => cubit.restart(),
      expect: () => <Matcher>[
        isA<RegistrationState>()
            .having((s) => s.step, 'step', RegistrationStep.role),
      ],
    );
  });
}
