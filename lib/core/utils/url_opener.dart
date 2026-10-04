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
