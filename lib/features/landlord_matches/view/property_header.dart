import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/firestore/models/models.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../../../shared/widgets/listing_image_placeholder.dart';

/// Slim header naming the listing whose tenants are shown, with its rent and
/// the one control this screen needs: the rental status. Tapping it opens the
/// property, where the photos and full details live.
class PropertyHeader extends StatelessWidget {
  const PropertyHeader({
    required this.property,
    required this.displayName,
    required this.onOpen,
    required this.onSetStatus,
    super.key,
  });

  final PropertyDoc property;
  final String displayName;
  final VoidCallback onOpen;

  /// Saves 'available' or 'booked'; throws when the write fails.
  final Future<void> Function(String status) onSetStatus;

  static String _money(num value) => value.round().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final building = property.propertyName?.trim() ?? '';
    final secondary = [
      if (building.isNotEmpty && building != displayName) building,
      '₱${_money(property.monthlyRent)} / month',
    ].join(' · ');
    final status = property.vacancyStatus.isNotEmpty
        ? property.vacancyStatus
        : (property.isAvailable ? 'available' : 'booked');
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!largeText) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox.square(
                    dimension: 56,
                    child: ListingImagePlaceholder(
                      seed: property.propertyId.hashCode % 5 + 1,
                      photoUrl: property.photos.isNotEmpty
                          ? property.photos.first
                          : property.effectiveBuildingCoverPhoto,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      secondary,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12.5,
                        color: colors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _statusMenu(context, status),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: colors.hint),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusMenu(BuildContext context, String status) {
    final colors = context.appColors;
    final available = status == 'available';
    TextStyle text(FontWeight weight) => TextStyle(
      fontFamily: 'DM Sans',
      fontSize: 12.5,
      fontWeight: weight,
      color: colors.textPrimary,
    );

    return PopupMenuButton<String>(
      tooltip: 'Change rental status',
      onSelected: (next) => _confirm(context, status, next),
      color: colors.surface,
      itemBuilder: (_) => [
        for (final (value, label) in const [
          ('available', 'Available'),
          ('booked', 'Occupied'),
        ])
          PopupMenuItem(
            value: value,
            child: Text(
              label,
              style: text(
                (value == 'available') == available
                    ? FontWeight.w800
                    : FontWeight.w500,
              ),
            ),
          ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: available ? AppColors.matchHigh : colors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                available ? 'Available' : 'Occupied',
                style: text(FontWeight.w700),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    String current,
    String next,
  ) async {
    if (next == current) return;
    final label = next == 'available' ? 'Available' : 'Occupied';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text('Change status to $label?'),
        content: Text(
          next == 'available'
              ? 'Marking this listing as Available will display it in tenant '
                    'search results and allow compatible tenants to send '
                    'inquiries.'
              : 'Marking this listing as Occupied will hide it from public '
                    'search results and prevent new tenant inquiries.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Mark as $label'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await onSetStatus(next);
      AppSnackBar.show(
        messenger,
        'Rental status updated to $label.',
        kind: AppSnackKind.success,
      );
    } catch (_) {
      AppSnackBar.show(
        messenger,
        "Couldn't update the status. Check your connection and try again.",
        kind: AppSnackKind.error,
      );
    }
  }
}
