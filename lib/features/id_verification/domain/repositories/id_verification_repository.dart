/// A Didit hosted verification session: [url] is opened for the owner,
/// [sessionId] is stored so the admin can look up the result later.
class IdVerificationSession {
  const IdVerificationSession({required this.sessionId, required this.url});

  final String sessionId;
  final String url;
}

/// Didit's decision for a session, as the admin sees it. Image fields are
/// short-lived links: display them right away, never store them.
class IdVerificationDecision {
  const IdVerificationDecision({
    required this.status,
    this.frontImage,
    this.backImage,
    this.portraitImage,
    this.selfieImage,
    this.fullName,
    this.dateOfBirth,
    this.documentNumber,
    this.documentType,
    this.expirationDate,
    this.faceMatchScore,
    this.livenessStatus,
  });

  /// 'Approved', 'Declined', 'In Review', 'In Progress', 'Not Started', ...
  final String status;
  final String? frontImage;
  final String? backImage;
  final String? portraitImage;
  final String? selfieImage;
  final String? fullName;
  final String? dateOfBirth;
  final String? documentNumber;
  final String? documentType;
  final String? expirationDate;
  final double? faceMatchScore;
  final String? livenessStatus;

  bool get hasIdImages => frontImage != null || backImage != null;
}

/// Automated ID check (Didit). Assists admin review only; it never changes
/// `verificationStatus`, which stays admin-controlled.
abstract class IdVerificationRepository {
  /// Starts a session for the owner [uid] (sent as Didit `vendor_data`).
  Future<IdVerificationSession> createSession(String uid);

  /// Didit's decision status for [sessionId]: 'Not Started', 'In Progress',
  /// 'In Review', 'Approved', 'Declined', 'Abandoned', 'Expired', ...
  Future<String> fetchStatus(String sessionId);

  /// Full decision (status, ID images, extracted details, face match).
  /// Kept in memory while the app runs; [refresh] fetches it again, e.g.
  /// after the image links expire.
  Future<IdVerificationDecision> fetchDecision(
    String sessionId, {
    bool refresh = false,
  });
}
