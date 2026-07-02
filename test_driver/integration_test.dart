import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Host-side driver: receives screenshots taken on the device and writes
/// them to `screenshots/device/(name).png`. Run with:
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/screenshots_test.dart -d emulator-5554
Future<void> main() async {
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final file = File('screenshots/device/$name.png');
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      // ignore: avoid_print
      print('saved screenshots/device/$name.png');
      return true;
    },
  );
}
