import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/url_opener.dart';

/// "Contact" row for an accepted thread: the other party's phone with Call
/// and Copy buttons. Renders nothing when [phone] is null/empty (not shared
/// yet).
class ContactRow extends StatelessWidget {
  const ContactRow({
    required this.phone,
    this.urlOpener = const UrlLauncherOpener(),
    super.key,
  });

  final String? phone;
  final UrlOpener urlOpener;

  @override
  Widget build(BuildContext context) {
    final number = phone?.trim() ?? '';
    if (number.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadii.field),
      ),
      child: Row(
        children: [
          Icon(Icons.phone_outlined, size: 18, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Contact', style: AppTextStyles.caption(context)),
                Text(
                  number,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Call',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Icon(Icons.call_outlined, color: AppColors.accent),
            onPressed: () => _call(context, number),
          ),
          IconButton(
            tooltip: 'Copy',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Icon(Icons.copy_outlined, color: AppColors.accent),
            onPressed: () => _copy(context, number),
          ),
        ],
      ),
    );
  }

  Future<void> _call(BuildContext context, String number) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await urlOpener.open(
      Uri(scheme: 'tel', path: number.replaceAll(RegExp(r'[^0-9+]'), '')),
    );
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open the dialer.')),
      );
    }
  }

  Future<void> _copy(BuildContext context, String number) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: number));
    messenger.showSnackBar(
      const SnackBar(content: Text('Phone number copied.')),
    );
  }
}
