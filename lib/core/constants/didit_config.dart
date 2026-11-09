/// Didit ID verification settings (https://docs.didit.me).
///
/// Passed at build time so the key is not committed:
///   flutter build apk --release \
///     --dart-define=DIDIT_API_KEY=... --dart-define=DIDIT_WORKFLOW_ID=...
///
/// Caveat: there is no backend (no Cloud Functions), so the key still ships
/// inside the APK and can be extracted. Didit only assists the admin: the
/// result is shown on the pending verifications screen, and the admin still
/// approves. Nothing is auto-approved from the client.
class DiditConfig {
  const DiditConfig._();

  /// Master switch. Didit is disabled for now: owners upload ID photos and
  /// the admin reviews them. Set to true (and pass the dart-defines) to
  /// turn it back on.
  static const bool enabled = false;

  static const String apiKey = String.fromEnvironment('DIDIT_API_KEY');
  static const String workflowId = String.fromEnvironment('DIDIT_WORKFLOW_ID');

  static const String baseUrl = 'https://verification.didit.me/v3';

  /// False when Didit is disabled or the build was made without the
  /// dart-defines; the Didit step is then hidden instead of failing.
  static bool get isConfigured =>
      enabled && apiKey.isNotEmpty && workflowId.isNotEmpty;
}
