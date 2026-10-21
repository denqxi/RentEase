import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/firestore/firestore_collections.dart';
import '../../../core/firestore/models/models.dart';
import '../../home/view/property_detail_screen.dart';
import '../../inquiry/view/inquiry_thread_screen.dart';
import '../../landlord_home/view/property_manager_screen.dart';
import '../model/activity_item.dart';

/// Centralized role-strict navigation router for notifications.
/// Guarantees that owners NEVER view tenant screens, and vice versa.
class NotificationRouter {
  const NotificationRouter._();

  static Future<void> navigate({
    required BuildContext context,
    required ActivityItem item,
    required bool isOwner,
  }) async {
    final relatedId = item.relatedId;
    final relatedType = item.relatedType;
    final rawType = item.rawType;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    bool effectiveIsOwner = isOwner;

    // 1. Inquiry / Message / Invitation / Rating
    final isInquiryRelated = relatedType == 'inquiry' ||
        const {
          'inquiry',
          'inquiry_accepted',
          'inquiry_declined',
          'invitation',
          'invitation_accepted',
          'invitation_declined',
          'message',
          'rating',
        }.contains(rawType);

    if (isInquiryRelated && relatedId != null && relatedId.isNotEmpty) {
      try {
        final inqSnap = await FirebaseFirestore.instance
            .collection(FirestoreCollections.inquiries)
            .doc(relatedId)
            .get();
        if (inqSnap.exists) {
          final data = inqSnap.data();
          final ownerId = data?['ownerId'] as String?;
          final tenantId = data?['tenantId'] as String?;
          if (currentUid != null) {
            if (currentUid == ownerId) {
              effectiveIsOwner = true;
            } else if (currentUid == tenantId) {
              effectiveIsOwner = false;
            }
          }
        }
      } catch (_) {}

      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => InquiryThreadScreen(
            inquiryId: relatedId,
            isOwner: effectiveIsOwner,
          ),
        ),
      );
      return;
    }

    // 2. Property related
    if (relatedType == 'property' && relatedId != null && relatedId.isNotEmpty) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection(FirestoreCollections.properties)
            .doc(relatedId)
            .get();
        if (!context.mounted) return;
        if (snap.exists) {
          final prop = PropertyDoc.fromSnapshot(snap);
          if (currentUid != null && prop.ownerId == currentUid) {
            effectiveIsOwner = true;
          }
          if (effectiveIsOwner) {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PropertyManagerScreen(
                  initialProperty: prop,
                  initialRooms: const [],
                ),
              ),
            );
            return;
          }
        }
      } catch (_) {}

      if (!context.mounted) return;
      if (!effectiveIsOwner) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PropertyDetailScreen(
              propertyId: relatedId,
            ),
          ),
        );
        return;
      }
    }

    // 3. Fallback: if there is an inquiry id, open thread
    if (relatedId != null && relatedId.isNotEmpty) {
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => InquiryThreadScreen(
            inquiryId: relatedId,
            isOwner: effectiveIsOwner,
          ),
        ),
      );
    }
  }
}
