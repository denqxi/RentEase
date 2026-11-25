import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../inquiry/domain/services/inquiry_service.dart';
import '../../inquiry/model/inquiry_summary.dart';

/// Tenant inquiries the owner has not answered yet, shown above the listings.
/// Takes no space when nothing is waiting.
class WaitingInquiriesSection extends StatelessWidget {
  const WaitingInquiriesSection({
    required this.items,
    required this.onOpen,
    required this.onSeeAll,
    super.key,
  });

  /// The whole inbox; only the unanswered ones are shown.
  final List<InquirySummary> items;
  final ValueChanged<InquirySummary> onOpen;
  final VoidCallback onSeeAll;

  static const int _shown = 3;

  /// Tenant-sent and still awaiting accept or decline.
  static List<InquirySummary> waiting(List<InquirySummary> items) => [
    for (final s in items)
      if (InquiryService.isPhase1Pending(s.inquiry) &&
          !InquiryService.isInvite(s.inquiry))
        s,
  ];

  @override
  Widget build(BuildContext context) {
    final pending = waiting(items);
    if (pending.isEmpty) return const SizedBox.shrink();
    final colors = context.appColors;
    TextStyle text(double size, FontWeight weight, Color color) => TextStyle(
      fontFamily: 'DM Sans',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.3,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Waiting for your reply (${pending.length})',
            style: text(16, FontWeight.w800, colors.textPrimary),
          ),
          const SizedBox(height: 8),
          for (final s in pending.take(_shown))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colors.fieldBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onOpen(s),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 20,
                          color: AppColors.matchMedium,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.counterpartName,
                                style: text(
                                  14,
                                  FontWeight.w700,
                                  colors.textPrimary,
                                ),
                              ),
                              Text(
                                '${s.propertyTitle} · ${inquiryDateLabel(s.inquiry.createdAt?.toDate())}',
                                style: text(
                                  12,
                                  FontWeight.w500,
                                  colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: colors.hint,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (pending.length > _shown)
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                'See all ${pending.length} in Inquiries',
                style: text(14, FontWeight.w700, AppColors.accent),
              ),
            ),
        ],
      ),
    );
  }
}
