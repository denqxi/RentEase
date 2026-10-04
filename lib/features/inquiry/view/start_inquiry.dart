import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/current_uid.dart';
import '../../activity/data/repositories/notification_repository_impl.dart';
import '../data/repositories/inquiry_repository_impl.dart';
import '../domain/services/inquiry_service.dart';
import '../widgets/contact_consent_notice.dart';
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

  // Consent notice: the phone number is only shared once the owner accepts.
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Send inquiry?'),
      content: const ContactConsentNotice(sharedWith: 'the owner'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(color: ctx.appColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            'Send inquiry',
            style: TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  try {
    final inquiryId = await InquiryService(
      repository: InquiryRepositoryImpl(),
      notifications: NotificationRepositoryImpl(),
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
