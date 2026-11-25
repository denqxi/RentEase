import '../../uploads/presentation/cubit/image_upload_cubit.dart';

/// Slot names on the verification screen, by index.
const _documentNames = [
  'front of your ID',
  'back of your ID',
  'ownership document',
  'business permit',
];

/// Why "Submit for verification" can't be pressed yet, worded for the owner,
/// or null when it can.
///
/// With Didit the ID photo slots (0 and 1) aren't used: the ID check must be
/// finished and no optional document may be uploading or broken. Without it,
/// both ID photos are required.
String? documentSubmitBlocker(
  ImageUploadState uploads, {
  required bool useDidit,
  bool idCheckStarted = false,
  String? idCheckStatus,
}) {
  if (useDidit) {
    if (!idCheckStarted) return 'Start the ID check above to submit.';
    switch (idCheckStatus) {
      case 'Approved' || 'In Review':
        break;
      case 'Declined':
        return "The ID check didn't pass. Try it again to submit.";
      case 'Abandoned' || 'Expired' || 'Kyc Expired':
        return 'The ID check expired. Start a new one to submit.';
      default:
        return 'Finish the ID check above to submit.';
    }
  }

  final used = [
    for (var i = useDidit ? 2 : 0; i < uploads.slots.length; i++) i,
  ];
  List<String> namesWhere(bool Function(int) test) => [
    for (final i in used)
      if (test(i)) _documentNames[i],
  ];

  final failed = namesWhere(
    (i) => uploads.slots[i].status == SlotStatus.failure,
  );
  if (failed.isNotEmpty) {
    return "The ${_list(failed)} didn't upload. Retry or remove "
        '${failed.length == 1 ? 'it' : 'them'} to submit.';
  }
  final uploading = namesWhere(
    (i) => uploads.slots[i].status == SlotStatus.uploading,
  );
  if (uploading.isNotEmpty) {
    return 'Wait for the ${_list(uploading)} to finish uploading.';
  }
  if (!useDidit) {
    final required = uploads.requiredSlots ?? const <int>{};
    final missing = namesWhere(
      (i) =>
          required.contains(i) &&
          uploads.slots[i].status != SlotStatus.success,
    );
    if (missing.isNotEmpty) return 'Add the ${_list(missing)} to submit.';
    // Covers any other readiness rule the upload state applies.
    if (!uploads.isReady) return 'Add the required documents to submit.';
  }
  return null;
}

String _list(List<String> names) => names.length < 2
    ? names.join()
    : '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
