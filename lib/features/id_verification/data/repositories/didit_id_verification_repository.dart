import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/didit_config.dart';
import '../../domain/repositories/id_verification_repository.dart';

class DiditIdVerificationRepository implements IdVerificationRepository {
  DiditIdVerificationRepository({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Decisions fetched this app run, by session ID. Memory only: nothing
  /// from Didit (ID images, personal details) is written to disk.
  static final Map<String, IdVerificationDecision> _decisionCache = {};

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-api-key': DiditConfig.apiKey,
  };

  @override
  Future<IdVerificationSession> createSession(String uid) async {
    final res = await _client.post(
      Uri.parse('${DiditConfig.baseUrl}/session/'),
      headers: _headers,
      body: jsonEncode({
        'workflow_id': DiditConfig.workflowId,
        'vendor_data': uid,
      }),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Could not start ID verification (${res.statusCode}).');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final sessionId = data['session_id'] as String?;
    final url = data['url'] as String?;
    if (sessionId == null || url == null) {
      throw Exception('Unexpected response from ID verification.');
    }
    return IdVerificationSession(sessionId: sessionId, url: url);
  }

  @override
  Future<String> fetchStatus(String sessionId) async =>
      (await fetchDecision(sessionId, refresh: true)).status;

  @override
  Future<IdVerificationDecision> fetchDecision(
    String sessionId, {
    bool refresh = false,
  }) async {
    final cached = _decisionCache[sessionId];
    if (cached != null && !refresh) return cached;

    final res = await _client.get(
      Uri.parse('${DiditConfig.baseUrl}/session/$sessionId/decision/'),
      headers: _headers,
    );
    if (res.statusCode == 404) {
      return const IdVerificationDecision(status: 'Not found');
    }
    if (res.statusCode != 200) {
      throw Exception('Could not load ID check result (${res.statusCode}).');
    }
    final decision = _parse(jsonDecode(res.body) as Map<String, dynamic>);
    // Only cache final results; unfinished sessions keep changing.
    if (decision.status == 'Approved' || decision.status == 'Declined') {
      _decisionCache[sessionId] = decision;
    }
    return decision;
  }

  /// Per-feature results are arrays (id_verifications[], liveness_checks[],
  /// face_matches[]); the first entry is used.
  static IdVerificationDecision _parse(Map<String, dynamic> data) {
    Map<String, dynamic>? first(String key) {
      final list = data[key];
      if (list is List && list.isNotEmpty && list.first is Map) {
        return Map<String, dynamic>.from(list.first as Map);
      }
      return null;
    }

    String? str(Map<String, dynamic>? m, String key) {
      final v = m?[key];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    final id = first('id_verifications');
    final liveness = first('liveness_checks');
    final faceMatch = first('face_matches');
    final firstName = str(id, 'first_name');
    final lastName = str(id, 'last_name');
    final joinedName = [firstName, lastName].whereType<String>().join(' ');

    return IdVerificationDecision(
      status: data['status'] as String? ?? 'Unknown',
      frontImage: str(id, 'front_image'),
      backImage: str(id, 'back_image'),
      portraitImage: str(id, 'portrait_image'),
      selfieImage: str(liveness, 'reference_image'),
      fullName: str(id, 'full_name') ?? (joinedName.isEmpty ? null : joinedName),
      dateOfBirth: str(id, 'date_of_birth'),
      documentNumber: str(id, 'document_number'),
      documentType: str(id, 'document_type'),
      expirationDate: str(id, 'expiration_date'),
      faceMatchScore: (faceMatch?['score'] as num?)?.toDouble(),
      livenessStatus: str(liveness, 'status'),
    );
  }
}
