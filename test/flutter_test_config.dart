// Loads a real system font under the "DM Sans" family name so widget-test
// screenshots render legible text instead of the default tofu/block glyphs
// (flutter_test doesn't load any real fonts by default, and google_fonts
// can't reach the network in this environment to fetch the real typeface).
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUpAll(() async {
    final loader = FontLoader('DM Sans');
    final bytes = File(r'C:\Windows\Fonts\segoeui.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  });
  await testMain();
}
