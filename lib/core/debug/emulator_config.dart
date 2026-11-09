import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Debug-only switch that points the app at the Firebase Emulator Suite
/// (CLAUDE.md "Performance Testing": never measure against production):
///
/// ```
/// flutter run --dart-define=USE_EMULATOR=true \
///   --dart-define=EMULATOR_HOST=192.168.1.x   # the PC's LAN IP
/// ```
///
/// It is a no-op in release builds, two ways: `kDebugMode` is a compile-time
/// `false` there (so this body is tree-shaken out), and without the
/// dart-define `USE_EMULATOR` is `false` anyway.
const bool useEmulator = bool.fromEnvironment('USE_EMULATOR');
const String emulatorHost = String.fromEnvironment(
  'EMULATOR_HOST',
  // Android emulator's alias for the host PC; a physical phone needs the
  // PC's LAN IP.
  defaultValue: '10.0.2.2',
);

/// Call once, right after Firebase.initializeApp and before any Firestore
/// or Auth use.
Future<void> connectToEmulatorsIfRequested() async {
  if (!kDebugMode || !useEmulator) return;
  FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
  await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
  debugPrint('Using Firebase Emulator Suite at $emulatorHost');
}
