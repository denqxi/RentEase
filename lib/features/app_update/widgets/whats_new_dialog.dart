import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../model/app_update_info.dart';

/// Centered floating card dialog displaying structured release notes (What's New).
/// Floats in the center of the screen with a blurred, dimmed backdrop.
class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({
    required this.info,
    this.onUpdate,
    super.key,
  });

  final AppUpdateInfo info;
  final VoidCallback? onUpdate;

  /// Shows the centered floating card overlay.
  static Future<void> show(
    BuildContext context, {
    required AppUpdateInfo info,
    VoidCallback? onUpdate,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (_) => WhatsNewDialog(
        info: info,
        onUpdate: onUpdate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 380,
            maxHeight: 560,
          ),
          child: Dialog(
            backgroundColor: AppColors.surface,
            elevation: 12,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(
                color: AppColors.fieldBorder,
                width: 0.8,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Header Row ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'v${info.latestVersion}',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Title & Subtitle ──
                  const Text(
                    "What's New in RentEase",
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Release Notes & Updates',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.fieldBorder),
                  const SizedBox(height: 14),

                  // ── Scrollable Body ──
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. New Features Section
                          if (info.features.isNotEmpty) ...[
                            _buildSectionHeader('NEW FEATURES'),
                            const SizedBox(height: 8),
                            for (final item in info.features) _buildBulletItem(item),
                            const SizedBox(height: 14),
                          ],

                          // 2. Fixes & Improvements Section
                          if (info.fixes.isNotEmpty) ...[
                            _buildSectionHeader('BUG FIXES & IMPROVEMENTS'),
                            const SizedBox(height: 8),
                            for (final item in info.fixes) _buildBulletItem(item),
                            const SizedBox(height: 14),
                          ],

                          // 3. Fallback for plain text notes if structured is empty
                          if (!info.hasStructuredNotes && info.notes.isNotEmpty) ...[
                            _buildSectionHeader('UPDATES'),
                            const SizedBox(height: 8),
                            Text(
                              info.notes,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                height: 1.4,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  const Divider(height: 1, color: AppColors.fieldBorder),
                  const SizedBox(height: 14),

                  // ── Bottom Action Buttons ──
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDeep,
                        foregroundColor: AppColors.surface,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onUpdate?.call();
                      },
                      icon: const Icon(Icons.system_update_rounded, size: 18),
                      label: Text(
                        'Update to v${info.latestVersion}',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.textSecondary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        color: AppColors.primaryDeep,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 7, right: 10),
            decoration: const BoxDecoration(
              color: AppColors.primaryDeep,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
