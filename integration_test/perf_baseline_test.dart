// On-device Firestore read/write measurement (CLAUDE.md "Performance
// Testing"). EMULATOR ONLY: refuses to run without USE_EMULATOR=true.
//
// Prerequisites (repo root): emulators running and seeded, see
// perf-tests/README.md. Then:
//   node perf-tests/collect.js --label baseline --host <PC LAN IP>
// which runs this file on the connected phone and appends the rows to
// perf-tests/results/baseline-reads.csv.
//
// Every row is printed as `PERFCSV,<label>,<scenario>,<matches>,<run>,
// <reads>,<cacheReads>,<writes>,<estRuleReads>,<topReadTags>`.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:rentease/core/debug/emulator_config.dart';
import 'package:rentease/core/debug/perf_counter.dart';
import 'package:rentease/features/home/cubit/home_cubit.dart';
import 'package:rentease/features/home/view/home_screen.dart';
import 'package:rentease/features/matching/data/repositories/filtering_repository_impl.dart';
import 'package:rentease/features/matching/data/repositories/topsis_repository_impl.dart';
import 'package:rentease/features/matching/domain/services/filtering_service.dart';
import 'package:rentease/features/matching/domain/services/topsis_service.dart';
import 'package:rentease/features/profile/cubit/edit_preferences_cubit.dart';
import 'package:rentease/features/tenant_onboarding/data/repositories/tenant_profile_repository_impl.dart';
import 'package:rentease/firebase_options.dart';
import 'package:rentease/main.dart' show buildRentEaseRoot;

const _label = String.fromEnvironment('PERF_LABEL', defaultValue: 'baseline');
const _password = String.fromEnvironment(
  'PERF_PASSWORD',
  defaultValue: 'perf-test-only',
);
const _runs = int.fromEnvironment('PERF_RUNS', defaultValue: 3);

/// Comma-separated subsets for a trial run, e.g. PERF_MATCHES=400 and
/// PERF_SCENARIOS=cold_open. Empty = everything.
const _onlyMatches = String.fromEnvironment('PERF_MATCHES');
const _onlyScenarios = String.fromEnvironment('PERF_SCENARIOS');

bool _wanted(String list, String value) =>
    list.isEmpty || list.split(',').map((s) => s.trim()).contains(value);

/// Seeded tenants (perf-tests/seed.js): matches -> budget.
const _allTenants = {20: 2500, 100: 3500, 400: 5000};
final _tenants = {
  for (final e in _allTenants.entries)
    if (_wanted(_onlyMatches, '${e.key}')) e.key: e.value,
};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (!useEmulator) {
      fail(
        'Refusing to run: pass --dart-define=USE_EMULATOR=true '
        '(perf tests never run against production).',
      );
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await connectToEmulatorsIfRequested();
  });

  for (final entry in _tenants.entries) {
    final matches = entry.key;
    final budget = entry.value;
    testWidgets('tenant with $matches matches', (tester) async {
      await FirebaseAuth.instance.signOut();
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'perf.tenant$matches@example.test',
        password: _password,
      );
      final uid = cred.user!.uid;

      // Warm-up: the first open after seeding creates the matches; every
      // recorded open is a returning tenant's.
      await _coldStart(tester);

      for (
        var run = 1;
        _wanted(_onlyScenarios, 'cold_open') && run <= _runs;
        run++
      ) {
        await _coldStart(tester);
        _emit('cold_open', matches, run);
      }

      for (
        var run = 1;
        _wanted(_onlyScenarios, 'pull_to_refresh') && run <= _runs;
        run++
      ) {
        final home = tester.element(find.byType(HomeScreen));
        final cubit = home.read<HomeCubit>();
        PerfCounter.reset();
        await cubit.refresh();
        await _waitQuiet(tester, quiet: const Duration(seconds: 2));
        _emit('pull_to_refresh', matches, run);
      }

      // Profile save, measured alone (app tree disposed): the same cubit
      // and call the Edit constraints screen uses, saving unchanged values.
      await tester.pumpWidget(const SizedBox());
      for (
        var run = 1;
        _wanted(_onlyScenarios, 'profile_save') && run <= _runs;
        run++
      ) {
        final cubit = EditPreferencesCubit(
          uid: uid,
          repository: TenantProfileRepositoryImpl(),
          filteringService: FilteringService(
            repository: FilteringRepositoryImpl(),
          ),
          topsisService: TopsisService(repository: TopsisRepositoryImpl()),
        );
        await _until(() => cubit.state.profile != null);
        PerfCounter.reset();
        await cubit.saveConstraints(
          maxBudget: budget,
          requiredGender: 'Any',
          needsWifi: false,
          maxDistanceKm: 10,
        );
        _emit('profile_save', matches, run);
        await cubit.close();
      }
    }, timeout: const Timeout(Duration(minutes: 30)));
  }
}

/// Simulates a cold app start: dispose the app, drop Firestore's local
/// cache, then pump the real root widget and wait until Firestore traffic
/// stops.
Future<void> _coldStart(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  await FirebaseFirestore.instance.terminate();
  await FirebaseFirestore.instance.clearPersistence();
  FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
  PerfCounter.reset();
  await tester.pumpWidget(buildRentEaseRoot());
  await _waitQuiet(tester);
  if (find.byType(HomeScreen).evaluate().isEmpty) {
    fail('Home did not open after a cold start (check the seeded tenant).');
  }
}

/// Pumps until no Firestore read/write has happened for [quiet].
Future<void> _waitQuiet(
  WidgetTester tester, {
  Duration quiet = const Duration(seconds: 5),
  Duration max = const Duration(minutes: 5),
}) async {
  final total = Stopwatch()..start();
  var last = PerfCounter.events;
  final idle = Stopwatch()..start();
  while (total.elapsed < max) {
    await tester.pump(const Duration(milliseconds: 100));
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (PerfCounter.events != last) {
      last = PerfCounter.events;
      idle.reset();
    } else if (idle.elapsed >= quiet) {
      return;
    }
  }
  fail('Firestore traffic did not settle within $max');
}

Future<void> _until(bool Function() done) async {
  for (var i = 0; i < 200 && !done(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  if (!done()) fail('Timed out waiting for the profile to load');
}

/// Reads made by firestore.rules (get()/exists()) are billed but invisible
/// to the client. Estimate: each bScore = 1 match write reads its property
/// doc, plus ~3 shared docs (tenant profile, prefs, user) per 15-write batch;
/// each delete batch reads the user doc once (notSuspended).
int _estimatedRuleReads() {
  final w = PerfCounter.writesByTag;
  int perBatch(int n, int shared) => n + shared * ((n + 14) ~/ 15);
  final sets = w['matching.filterSet'] ?? 0;
  final ci = w['matching.topsisCiWrite'] ?? 0;
  final deletes = w['matching.filterDelete'] ?? 0;
  return perBatch(sets, 3) + perBatch(ci, 3) + (deletes + 14) ~/ 15;
}

void _emit(String scenario, int matches, int run) {
  final top = PerfCounter.readsByTag.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final tags = top.take(4).map((e) => '${e.key}=${e.value}').join(' ');
  // ignore: avoid_print
  print(
    'PERFCSV,$_label,$scenario,$matches,$run,${PerfCounter.totalReads},'
    '${PerfCounter.totalCacheReads},${PerfCounter.totalWrites},'
    '${_estimatedRuleReads()},$tags',
  );
}
