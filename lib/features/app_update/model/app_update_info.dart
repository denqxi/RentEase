/// Latest-release info published in `version.json` (RentEaseApk repo).
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.latestVersion,
    required this.latestBuild,
    required this.minSupportedBuild,
    required this.apkUrl,
    this.notes = '',
    this.features = const [],
    this.fixes = const [],
  });

  final String latestVersion;
  final int latestBuild;

  /// Installed builds below this number must update (non-dismissible).
  final int minSupportedBuild;
  final String apkUrl;

  /// Plain string notes (legacy or fallback).
  final String notes;

  /// Structured "NEW FEATURES" list.
  final List<String> features;

  /// Structured "BUG FIXES & IMPROVEMENTS" list.
  final List<String> fixes;

  /// True if either features or fixes has items.
  bool get hasStructuredNotes => features.isNotEmpty || fixes.isNotEmpty;

  /// True if any notes (structured or plain text) exist.
  bool get hasAnyNotes => hasStructuredNotes || notes.trim().isNotEmpty;

  /// Returns null when the JSON is malformed, so a bad file never crashes.
  static AppUpdateInfo? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final version = json['latestVersion'];
    final build = json['latestBuild'];
    final url = json['apkUrl'];
    if (version is! String || build is! int || url is! String) return null;
    final minBuild = json['minSupportedBuild'];

    String plainNotes = '';
    List<String> features = const [];
    List<String> fixes = const [];

    final rawNotes = json['notes'];
    if (rawNotes is Map) {
      features = _parseList(rawNotes['features']);
      fixes = _parseList(rawNotes['fixes']);
      // Optional plain notes if provided
      if (rawNotes['summary'] is String) {
        plainNotes = rawNotes['summary'] as String;
      }
    } else if (rawNotes is String) {
      plainNotes = rawNotes;
    }

    return AppUpdateInfo(
      latestVersion: version,
      latestBuild: build,
      minSupportedBuild: minBuild is int ? minBuild : 1,
      apkUrl: url,
      notes: plainNotes,
      features: features,
      fixes: fixes,
    );
  }

  static List<String> _parseList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
