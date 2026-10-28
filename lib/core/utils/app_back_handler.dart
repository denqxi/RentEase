import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Handles system back navigation on Android root screens by moving the
/// task to the background rather than killing the Activity.
abstract final class AppBackHandler {
  static const MethodChannel _channel = MethodChannel('com.example.rentease/app');

  /// Minimizes the application to background without destroying MainActivity.
  /// Falls back to [SystemNavigator.pop] if the platform channel fails.
  static Future<void> minimizeOrPop() async {
    if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
      try {
        final handled = await _channel.invokeMethod<bool>('moveToBackground');
        if (handled == true) return;
      } catch (_) {
        // Fall back to standard pop
      }
    }
    await SystemNavigator.pop();
  }
}
