// Loads the bundled DM Sans font so widget-test screenshots render the real
// typeface instead of the default tofu/block glyphs (flutter_test doesn't
// load app fonts by default).
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUpAll(() async {
    final loader = FontLoader('DM Sans');
    for (final file in Directory('assets/fonts').listSync()) {
      if (file is File && file.path.endsWith('.ttf')) {
        final bytes = file.readAsBytesSync();
        loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      }
    }
    await loader.load();
  });
  await testMain();
}
