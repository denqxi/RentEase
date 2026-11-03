import '../../../uploads/domain/entities/uploaded_image.dart';

class SubmittedDocuments {
  const SubmittedDocuments({
    this.diditSessionId,
    this.idSource = 'upload',
    this.documentUrls = const [],
    this.documentPublicIds = const [],
    this.ownershipDocument,
    this.businessPermit,
    this.idFront,
    this.idBack,
  });

  final String? diditSessionId;
  final String idSource;
  final List<String> documentUrls;
  final List<String> documentPublicIds;
  final UploadedImage? ownershipDocument;
  final UploadedImage? businessPermit;
  final UploadedImage? idFront;
  final UploadedImage? idBack;

  bool get isEmpty =>
      diditSessionId == null &&
      documentUrls.isEmpty &&
      ownershipDocument == null &&
      businessPermit == null;
}
