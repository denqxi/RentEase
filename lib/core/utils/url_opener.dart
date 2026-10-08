import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a web page (or a `tel:` dialer link). Abstract so tests can fake it.
abstract class UrlOpener {
  /// Returns true when the page was opened.
  Future<bool> open(Uri uri);
}

/// Opens in an in-app browser tab (Chrome Custom Tab on Android), falling
/// back to the external browser.
class UrlLauncherOpener implements UrlOpener {
  const UrlLauncherOpener();

  @override
  Future<bool> open(Uri uri) async {
    // Allow-list: only https web pages and tel: dialer links ever launch.
    if (uri.scheme != 'https' && uri.scheme != 'tel') return false;
    // Phone dialer links open in the dialer app, not an in-app browser tab.
    if (uri.scheme == 'tel') {
      try {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    }
    try {
      if (await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) return true;
    } catch (_) {
      // Fall through to the external browser.
    }
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

const MethodChannel _emailChannel = MethodChannel('com.example.rentease/email_app');

/// Opens the device's Gmail or default email client directly to the inbox
/// without opening compose or redirecting to a web browser.
Future<bool> openEmailApp() async {
  // 1. Android: use native method channel to launch the Gmail app directly
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      final opened = await _emailChannel.invokeMethod<bool>('openEmailApp');
      if (opened == true) return true;
    } catch (_) {}

    // Android direct Gmail app URI fallback (never opens browser)
    try {
      final gmailUri = Uri.parse('android-app://com.google.android.gm');
      final opened = await launchUrl(
        gmailUri,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      if (opened) return true;
    } catch (_) {}
  }

  // 2. iOS: direct app URL schemes that open the app directly to inbox without composing
  final iosSchemes = <Uri>[
    Uri.parse('googlegmail:///'),
    Uri.parse('message://'),
    Uri.parse('ms-outlook://'),
    Uri.parse('ymail://'),
  ];

  for (final uri in iosSchemes) {
    try {
      if (await canLaunchUrl(uri)) {
        final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (opened) return true;
      }
    } catch (_) {}
  }

  // Do not redirect to a web browser
  return false;
}
