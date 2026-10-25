import 'package:shared_preferences/shared_preferences.dart';

/// Remembers on this device that the intro carousel was already shown, so
/// returning (signed-out) users go straight to sign-in after the splash.
abstract final class OnboardingSeenStore {
  static const _key = 'onboarding_seen';

  /// Defaults to false (show the carousel) if storage can't be read.
  static Future<bool> hasSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (_) {
      // Non-critical: the carousel just shows again next launch.
    }
  }
}
