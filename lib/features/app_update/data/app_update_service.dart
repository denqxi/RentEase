import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../model/app_update_info.dart';

/// Installed app version (from pubspec `version: name+build`).
class InstalledVersion {
  const InstalledVersion({required this.version, required this.build});

  final String version;
  final int build;
}

/// Reads the installed version and the published `version.json`.
/// Abstract so tests can fake it.
abstract class AppUpdateService {
  Future<InstalledVersion?> installedVersion();

  /// Returns null on any failure (offline, 404, bad JSON): updates are
  /// best-effort and must never disturb the app.
  Future<AppUpdateInfo?> fetchLatest();
}

class GithubAppUpdateService implements AppUpdateService {
  const GithubAppUpdateService();

  /// Public raw file in the APK repo. Raw files are cached ~5 min by GitHub.
  static const String versionJsonUrl =
      'https://raw.githubusercontent.com/JoshDumadapat/RentEaseApk/main/version.json';

  @override
  Future<InstalledVersion?> installedVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final build = int.tryParse(info.buildNumber);
      if (build == null) return null;
      return InstalledVersion(version: info.version, build: build);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AppUpdateInfo?> fetchLatest() async {
    try {
      final response = await http
          .get(Uri.parse(versionJsonUrl))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      return AppUpdateInfo.tryParse(jsonDecode(response.body));
    } catch (_) {
      return null;
    }
  }
}
