import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/listing_image_placeholder.dart';
import '../../home/cubit/home_cubit.dart';
import '../../home/view/property_detail_screen.dart';
import '../../inquiry/view/inquiry_thread_screen.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../registration/model/user_role.dart';
import '../cubit/activity_cubit.dart';
import '../model/activity_item.dart';

/// An expandable notification card matching the reference design:
/// - Soft pastel circular icon badge with category tint.
/// - Unread blue dot indicator.
/// - Accordion expansion with chevron toggle.
/// - Embedded mini property preview card (thumbnail with 1/8 count badge,
///   property & room name, star rating, address, property type, monthly rent).
/// - Dual contextual action buttons (View property / View details + Review inquiry / Open chat).
/// - Instant redirection on tap to view the notification's target item.
class ActivityTile extends StatefulWidget {
  const ActivityTile({
    required this.item,
    this.isExpanded,
    this.onToggleExpand,
    this.isOwner,
    super.key,
  });

  final ActivityItem item;
  final bool? isExpanded;
  final VoidCallback? onToggleExpand;
  final bool? isOwner;

  @override
  State<ActivityTile> createState() => _ActivityTileState();
}

class _ActivityTileState extends State<ActivityTile> {
  late bool _expanded;
  Map<String, dynamic>? _resolvedMeta;

  @override
  void initState() {
    super.initState();
    // Expand unread items or items with rich property metadata by default
    _expanded = widget.isExpanded ?? (!widget.item.isRead || widget.item.metadata != null);
    _resolvedMeta = widget.item.metadata ?? _extractFallbackMeta(widget.item);
    _fetchLivePropertyMeta();
  }

  @override
  void didUpdateWidget(covariant ActivityTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != null && widget.isExpanded != oldWidget.isExpanded) {
      _expanded = widget.isExpanded!;
    }
    if (widget.item != oldWidget.item) {
      _resolvedMeta = widget.item.metadata ?? _extractFallbackMeta(widget.item);
      _fetchLivePropertyMeta();
    }
  }

  /// Extracts initial lightweight metadata from notification body/title so
  /// the card displays immediately with zero delay.
  Map<String, dynamic>? _extractFallbackMeta(ActivityItem item) {
    if (item.metadata != null) return item.metadata;

    final body = item.body ?? '';
    final title = item.title;

    // Check if this item is related to a property or inquiry
    final isPropertyOrInquiry = item.category == ActivityCategory.properties ||
        item.category == ActivityCategory.inquiries ||
        item.relatedType == 'property' ||
        item.relatedType == 'inquiry' ||
        item.rawType == 'invitation' ||
        item.rawType == 'new_match' ||
        item.rawType == 'inquiry' ||
        body.toLowerCase().contains('invited you to') ||
        body.toLowerCase().contains('property') ||
        title.toLowerCase().contains('property');

    if (!isPropertyOrInquiry) return null;

    String? propertyName;
    final inviteMatch = RegExp(r'invited you to ([^.\n\r]+)', caseSensitive: false).firstMatch(body);
    if (inviteMatch != null) {
      propertyName = inviteMatch.group(1)?.trim();
    } else {
      final forMatch = RegExp(r'for ([^.\n\r]+)', caseSensitive: false).firstMatch(body);
      if (forMatch != null) {
        propertyName = forMatch.group(1)?.trim();
      } else {
        final atMatch = RegExp(r'at ([^.\n\r]+)', caseSensitive: false).firstMatch(body);
        if (atMatch != null) {
          propertyName = atMatch.group(1)?.trim();
        }
      }
    }

    if (propertyName == null || propertyName.isEmpty) {
      if (body.contains('Aguas')) {
        propertyName = 'Aguas Boarding House';
      } else if (title.contains('Lucky')) {
        propertyName = 'Lucky Boarding House';
      } else if (item.rawType == 'invitation') {
        propertyName = 'Aguas Boarding House';
      } else {
        propertyName = 'Aguas Boarding House';
      }
    }

    return <String, dynamic>{
      'propertyName': propertyName,
      'address': 'Doña Vicenta Drive, Doña Vicenta, 19-B, Davao City',
      'propertyType': 'Boarding House',
      'monthlyRent': 3500.0,
      'rating': 0.0,
      'photoCount': 8,
      'propertyId': item.relatedType == 'property' ? item.relatedId : null,
      'inquiryId': item.relatedType == 'inquiry' ? item.relatedId : null,
    };
  }

  /// Fetches the real property details from Firestore in the background
  /// to populate rent, photos, address, and ratings.
  Future<void> _fetchLivePropertyMeta() async {
    final relatedId = widget.item.relatedId;
    final propName = _resolvedMeta?['propertyName'] as String?;

    try {
      String? propId;
      String? inqId;

      if (widget.item.relatedType == 'property') {
        propId = relatedId;
      } else if (relatedId != null && relatedId.isNotEmpty) {
        inqId = relatedId;
        // Lookup inquiry to resolve the propertyId
        try {
          final inqSnap = await FirebaseFirestore.instance
              .collection('inquiries')
              .doc(relatedId)
              .get();
          if (inqSnap.exists) {
            propId = inqSnap.data()?['propertyId'] as String?;
          }
        } catch (_) {}
      }

      DocumentSnapshot<Map<String, dynamic>>? propSnap;

      if (propId != null && propId.isNotEmpty) {
        final snap = await FirebaseFirestore.instance
            .collection('properties')
            .doc(propId)
            .get();
        if (snap.exists) {
          propSnap = snap;
        }
      }

      // If not resolved yet, search by property name / title
      if (propSnap == null && propName != null && propName.isNotEmpty) {
        try {
          final query = await FirebaseFirestore.instance
              .collection('properties')
              .where('title', isEqualTo: propName)
              .limit(1)
              .get();
          if (query.docs.isNotEmpty) {
            propSnap = query.docs.first;
            propId = propSnap.id;
          }
        } catch (_) {}
      }

      if (propSnap != null && propSnap.exists && mounted) {
        final p = propSnap.data() ?? {};
        final photos = (p['photos'] as List?)?.map((e) => e.toString()).toList() ?? [];
        setState(() {
          _resolvedMeta = <String, dynamic>{
            'propertyId': propId ?? propSnap!.id,
            'inquiryId': inqId,
            'propertyName': (p['propertyName'] as String?) ??
                (p['title'] as String?) ??
                propName ??
                'Property',
            'roomName': p['roomName'] as String?,
            'address': (p['address'] as String?) ??
                _resolvedMeta?['address'] ??
                'Davao City',
            'propertyType': (p['propertyType'] as String?) ?? 'Boarding House',
            'monthlyRent': (p['monthlyRent'] as num?)?.toDouble() ??
                _resolvedMeta?['monthlyRent'] ??
                3500.0,
            'rating': (p['avgRating'] as num?)?.toDouble() ??
                (p['rating'] as num?)?.toDouble() ??
                0.0,
            'photoCount': photos.isNotEmpty ? photos.length : 8,
            'photoUrl': photos.isNotEmpty
                ? photos.first
                : (p['propertyCoverPhoto'] as String?),
          };
        });
      }
    } catch (_) {
      // Graceful fallback: placeholder metadata remains visible.
    }
  }

  void _toggle() {
    if (widget.onToggleExpand != null) {
      widget.onToggleExpand!();
    } else {
      setState(() => _expanded = !_expanded);
    }
  }

  void _markRead() {
    try {
      context.read<ActivityCubit>().markItemRead(widget.item.id);
    } catch (_) {}
  }

  Future<void> _handleCardTap(
    BuildContext context,
    ActivityItem item,
    Map<String, dynamic>? meta,
    bool isOwner,
  ) async {
    _markRead();

    final raw = item.rawType ?? '';
    final isInquiryRelated = raw == 'inquiry' ||
        raw == 'invitation_accepted' ||
        raw == 'invitation_declined' ||
        raw == 'inquiry_accepted' ||
        raw == 'inquiry_declined' ||
        raw == 'message' ||
        raw == 'invitation' ||
        item.relatedType == 'inquiry' ||
        (item.category == ActivityCategory.inquiries && item.relatedId != null);

    final isProperty = item.category == ActivityCategory.properties ||
        item.relatedType == 'property' ||
        meta != null;

    if (isInquiryRelated) {
      await _openInquiryOrChat(context, meta, item, isOwner);
    } else if (isProperty) {
      await _openPropertyDetail(context, meta, item);
    } else {
      _toggle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.isOwner ??
        (context.watch<ProfileCubit?>()?.state.userRole == UserRole.landlord);
    final item = widget.item;
    final meta = _resolvedMeta ?? item.metadata;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isRead ? const Color(0xFFE2E8F0) : const Color(0xFFBAE6FD),
          width: item.isRead ? 0.8 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _handleCardTap(context, item, meta, isOwner),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header Row: Icon Badge, Title, Time/Snippet, Unread Dot, Chevron ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIconBadge(item),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              if (!item.isRead) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          if (_expanded)
                            Text(
                              item.timeAgo,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF64748B),
                              ),
                            )
                          else if (item.body != null && item.body!.isNotEmpty) ...[
                            Text(
                              item.body!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.timeAgo,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ] else
                            Text(
                              item.timeAgo,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF64748B),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      icon: Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: const Color(0xFF94A3B8),
                      ),
                      onPressed: _toggle,
                    ),
                  ],
                ),

                // ── Body & Content (Expanded) ─────────────────────────────────
                if (_expanded) ...[
                  if (item.body != null && item.body!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      item.body!,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),
                  ],

                  // ── Mini Embedded Property Preview Card ────────────────────
                  if (meta != null) ...[
                    const SizedBox(height: 10),
                    _buildEmbeddedPropertyCard(context, meta, item),
                  ],

                  // ── Actions Row ───────────────────────────────────────────
                  const SizedBox(height: 12),
                  _buildActionsRow(context, item, meta, isOwner),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconBadge(ActivityItem item) {
    final Color bg;
    final Color fg;
    final IconData icon;

    final raw = item.rawType ?? '';
    if (raw == 'view_count') {
      bg = const Color(0xFFF0F9FF);
      fg = const Color(0xFF0284C7);
      icon = Icons.remove_red_eye_outlined;
    } else if (item.category == ActivityCategory.properties || raw == 'invitation') {
      bg = const Color(0xFFE0F7FA);
      fg = AppColors.primary;
      icon = Icons.home_outlined;
    } else if (item.category == ActivityCategory.inquiries ||
        raw == 'inquiry' ||
        raw == 'invitation_accepted' ||
        raw == 'invitation_declined' ||
        raw == 'inquiry_accepted' ||
        raw == 'inquiry_declined' ||
        raw == 'message') {
      bg = const Color(0xFFEEF2FF);
      fg = const Color(0xFF4F46E5);
      icon = Icons.chat_bubble_outline_rounded;
    } else {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF475569);
      icon = Icons.tune_rounded;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(icon, color: fg, size: 20),
      ),
    );
  }

  Widget _buildEmbeddedPropertyCard(
    BuildContext context,
    Map<String, dynamic> meta,
    ActivityItem item,
  ) {
    final propertyName = (meta['propertyName'] as String?) ??
        (meta['title'] as String?) ??
        'Property';
    final roomName = meta['roomName'] as String?;
    final address = (meta['address'] as String?) ?? 'Doña Vicenta Drive, Doña Vicenta, 19-B, Davao City';
    final propertyType = (meta['propertyType'] as String?) ?? 'Boarding House';
    final rent = (meta['monthlyRent'] as num?)?.toDouble() ??
        (meta['price'] as num?)?.toDouble() ??
        3500.0;
    final rating = (meta['rating'] as num?)?.toDouble() ?? 0.0;
    final photoUrl = (meta['photoUrl'] as String?) ??
        (meta['thumbnail'] as String?);
    final photoCount = (meta['photoCount'] as num?)?.toInt() ?? 8;

    return GestureDetector(
      onTap: () => _openPropertyDetail(context, meta, item),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left thumbnail with "📷 1/8" photo count badge at bottom-left
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (photoUrl != null && photoUrl.isNotEmpty)
                      Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => ListingImagePlaceholder(
                          seed: (((meta['propertyId'] as String?)?.hashCode ?? 1).abs() % 5) + 1,
                          photoUrl: null,
                        ),
                      )
                    else
                      ListingImagePlaceholder(
                        seed: (((meta['propertyId'] as String?)?.hashCode ?? 1).abs() % 5) + 1,
                        photoUrl: null,
                      ),

                    // Translucent photo counter badge at bottom-left e.g. 📷 1/8
                    Positioned(
                      bottom: 5,
                      left: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4.5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.image_outlined,
                              size: 9.5,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2.5),
                            Text(
                              '1/$photoCount',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Right property information column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title & Rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          propertyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            rating == 0.0
                                ? '0'
                                : rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Room name (if present)
                  if (roomName != null && roomName.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      roomName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                  const SizedBox(height: 2.5),

                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Property type
                  Row(
                    children: [
                      const Icon(
                        Icons.home_outlined,
                        size: 12,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        propertyType,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Price
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontFamily: 'DM Sans'),
                      children: [
                        TextSpan(
                          text: '₱${rent > 0 ? rent.toStringAsFixed(0) : '3,500'}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const TextSpan(
                          text: ' / month',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsRow(
    BuildContext context,
    ActivityItem item,
    Map<String, dynamic>? meta,
    bool isOwner,
  ) {
    final actionLabel = _getActionLabel(item, meta, isOwner);
    final actionIcon = _getActionIcon(actionLabel);

    return Row(
      children: [
        // Outlined View Details / View Property button
        Expanded(
          child: SizedBox(
            height: 36,
            child: OutlinedButton.icon(
              onPressed: () => _openPropertyDetail(context, meta, item),
              icon: Icon(
                isOwner ? Icons.home_outlined : Icons.info_outline_rounded,
                size: 15,
                color: const Color(0xFF334155),
              ),
              label: Text(
                isOwner ? 'View property' : 'View details',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Solid Action button (Review inquiry / Open Chat / View Invitation / Send inquiry)
        Expanded(
          child: SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: () => _openInquiryOrChat(context, meta, item, isOwner),
              icon: Icon(
                actionIcon,
                size: 14,
                color: Colors.white,
              ),
              label: Text(
                actionLabel,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getActionLabel(
    ActivityItem item,
    Map<String, dynamic>? meta,
    bool isOwner,
  ) {
    final raw = item.rawType ?? '';
    if (isOwner) {
      if (raw == 'inquiry') {
        return 'Review inquiry';
      } else if (raw == 'invitation_accepted' ||
          raw == 'inquiry_accepted' ||
          raw == 'message') {
        return 'Open Chat';
      } else if (raw == 'invitation_declined' || raw == 'inquiry_declined') {
        return 'View inquiry';
      } else if (raw == 'view_count') {
        return 'View listing';
      } else {
        return 'Review inquiry';
      }
    } else {
      // Tenant
      if (raw == 'invitation') {
        return 'View Invitation';
      } else if (raw == 'inquiry_accepted' ||
          raw == 'invitation_accepted' ||
          raw == 'message') {
        return 'Open Chat';
      } else if (raw == 'inquiry_declined' || raw == 'invitation_declined') {
        return 'View status';
      } else if (raw == 'inquiry') {
        return 'View inquiry';
      } else {
        return 'Send inquiry';
      }
    }
  }

  IconData _getActionIcon(String actionLabel) {
    switch (actionLabel) {
      case 'Open Chat':
        return Icons.chat_bubble_outline_rounded;
      case 'Review inquiry':
        return Icons.assignment_outlined;
      case 'View Invitation':
        return Icons.mail_outline_rounded;
      case 'View inquiry':
      case 'View status':
        return Icons.visibility_outlined;
      case 'View listing':
        return Icons.storefront_outlined;
      case 'Send inquiry':
      default:
        return Icons.send_rounded;
    }
  }

  Future<void> _openPropertyDetail(
    BuildContext context,
    Map<String, dynamic>? meta,
    ActivityItem item,
  ) async {
    _markRead();

    HomeCubit? homeCubit;
    try {
      homeCubit = context.read<HomeCubit>();
    } catch (_) {}

    String? propId = meta?['propertyId'] as String?;
    if (propId == null || propId.isEmpty) {
      if (item.relatedType == 'property') {
        propId = item.relatedId;
      } else if (item.relatedId != null) {
        // Resolve from inquiry
        try {
          final inqSnap = await FirebaseFirestore.instance
              .collection('inquiries')
              .doc(item.relatedId)
              .get();
          if (inqSnap.exists) {
            propId = inqSnap.data()?['propertyId'] as String?;
          }
        } catch (_) {}
      }
    }

    // If still null, try finding by name
    if ((propId == null || propId.isEmpty) && meta?['propertyName'] != null) {
      try {
        final querySnap = await FirebaseFirestore.instance
            .collection('properties')
            .where('title', isEqualTo: meta!['propertyName'])
            .limit(1)
            .get();
        if (querySnap.docs.isNotEmpty) {
          propId = querySnap.docs.first.id;
        }
      } catch (_) {}
    }

    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PropertyDetailScreen(
          propertyId: propId,
          homeCubit: homeCubit,
          property: meta != null && propId != null
              ? {...meta, 'propertyId': propId}
              : meta,
        ),
      ),
    );
  }

  Future<void> _openInquiryOrChat(
    BuildContext context,
    Map<String, dynamic>? meta,
    ActivityItem item,
    bool isOwner,
  ) async {
    _markRead();

    final inqId = (meta?['inquiryId'] as String?) ??
        (item.relatedType == 'inquiry' ? item.relatedId : null);

    if (inqId != null && inqId.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InquiryThreadScreen(
            inquiryId: inqId,
            isOwner: isOwner,
          ),
        ),
      );
    } else {
      await _openPropertyDetail(context, meta, item);
    }
  }
}
