import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/current_uid.dart';
import '../data/repositories/inquiry_repository_impl.dart';
import '../domain/services/inquiry_service.dart';
import 'inquiry_thread_screen.dart';

/// "Send Inquiry" from any listing screen: opens (or reuses) the tenant's
/// inquiry for this property via [InquiryService], then shows the live
/// thread. [matchId] defaults to the `{tenantId}_{propertyId}` convention
/// FilteringService writes match docs under.
Future<void> startInquiry(
  BuildContext context, {
  required String propertyId,
  String? matchId,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final uid = currentUidOrNull(context);
  if (uid == null) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Sign in to send an inquiry.')),
    );
    return;
  }

  try {
    final inquiryId = await InquiryService(
      repository: InquiryRepositoryImpl(),
    ).sendInquiry(tenantId: uid, matchId: matchId ?? '${uid}_$propertyId');
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            InquiryThreadScreen(inquiryId: inquiryId, isOwner: false),
      ),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.destructive,
      ),
    );
  }
}
