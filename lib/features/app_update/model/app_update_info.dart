/// Latest-release info published in `version.json` (RentEaseApk repo).
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.latestVersion,
    required this.latestBuild,
    required this.minSupportedBuild,
    required this.apkUrl,
    this.notes = '',
  });

  final String latestVersion;
  final int latestBuild;

  /// Installed builds below this number must update (non-dismissible).
  final int minSupportedBuild;
  final String apkUrl;
  final String notes;

  /// Returns null when the JSON is malformed, so a bad file never crashes.
  static AppUpdateInfo? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final version = json['latestVersion'];
    final build = json['latestBuild'];
    final url = json['apkUrl'];
    if (version is! String || build is! int || url is! String) return null;
    final minBuild = json['minSupportedBuild'];
    final notes = json['notes'];
    return AppUpdateInfo(
      latestVersion: version,
      latestBuild: build,
      minSupportedBuild: minBuild is int ? minBuild : 1,
      apkUrl: url,
      notes: notes is String ? notes : '',
    );
  }
}
