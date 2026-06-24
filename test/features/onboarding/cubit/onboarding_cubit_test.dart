import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/features/onboarding/cubit/onboarding_cubit.dart';

void main() {
  group('OnboardingCubit', () {
    test('starts on the first page with all pages loaded', () {
      final cubit = OnboardingCubit();
      expect(cubit.state.currentPage, 0);
      expect(cubit.state.pages, isNotEmpty);
      expect(cubit.state.isLastPage, isFalse);
      cubit.close();
    });

    blocTest<OnboardingCubit, OnboardingState>(
      'nextPage advances to the following page',
      build: OnboardingCubit.new,
      act: (cubit) => cubit.nextPage(),
      expect: () => <Matcher>[
        isA<OnboardingState>().having((s) => s.currentPage, 'currentPage', 1),
      ],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'nextPage does nothing on the last page',
      build: OnboardingCubit.new,
      seed: () => OnboardingState(
        currentPage: OnboardingCubit().state.pageCount - 1,
        pages: OnboardingCubit().state.pages,
      ),
      act: (cubit) => cubit.nextPage(),
      expect: () => const <OnboardingState>[],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'skip jumps straight to the last page',
      build: OnboardingCubit.new,
      act: (cubit) => cubit.skip(),
      expect: () => <Matcher>[
        isA<OnboardingState>().having((s) => s.isLastPage, 'isLastPage', true),
      ],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'pageChanged updates the current page',
      build: OnboardingCubit.new,
      act: (cubit) => cubit.pageChanged(2),
      expect: () => <Matcher>[
        isA<OnboardingState>().having((s) => s.currentPage, 'currentPage', 2),
      ],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'pageChanged to the same page emits nothing',
      build: OnboardingCubit.new,
      act: (cubit) => cubit.pageChanged(0),
      expect: () => const <OnboardingState>[],
    );
  });
}
