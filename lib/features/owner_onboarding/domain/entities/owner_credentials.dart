/// Documents a verified owner shares with tenants (only while
/// "Show credentials" is on; firestore.rules deny the reads otherwise).
/// The ID is never part of this.
class OwnerCredentials {
  const OwnerCredentials({this.businessPermitUrl, this.ownershipDocumentUrl});

  final String? businessPermitUrl;
  final String? ownershipDocumentUrl;

  bool get isEmpty => businessPermitUrl == null && ownershipDocumentUrl == null;
}
