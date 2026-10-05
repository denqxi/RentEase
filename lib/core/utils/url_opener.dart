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

/// Opens the device's default email client (e.g. Mail, Gmail) to the inbox
/// without composing a new email.
Future<bool> openEmailApp() async {
  // On iOS, message:// opens the Mail app directly to the inbox.
  final iosMailUri = Uri.parse('message://');
  try {
    if (await canLaunchUrl(iosMailUri)) {
      return await launchUrl(iosMailUri, mode: LaunchMode.externalApplication);
    }
  } catch (_) {}

  // General mailto: scheme with no recipient or parameters.
  final mailtoUri = Uri(scheme: 'mailto');
  try {
    if (await canLaunchUrl(mailtoUri)) {
      return await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
    }
    return await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
  } catch (_) {}

  // Webmail fallback
  try {
    final webmailUri = Uri.parse('https://mail.google.com');
    return await launchUrl(webmailUri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
