import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../cubit/app_update_cubit.dart';
import 'whats_new_dialog.dart';

/// Replaces the static "RentEase prototype · v1.0" footer on the profile
/// screens: shows the real installed version and, when a newer build is
/// published, a "View What's New" card overlay trigger and an Update button.
class UpdateSection extends StatelessWidget {
  const UpdateSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppUpdateCubit, AppUpdateState>(
      builder: (context, state) {
        final version = state.currentVersion;
        final label = version == null
            ? 'RentEase'
            : 'RentEase · v$version (${state.currentBuild})';
        final info = state.info;
        final downloading = state.status == AppUpdateStatus.downloading;

        return Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.slate400,
              ),
            ),
            const SizedBox(height: 10),
            if (state.hasUpdate && info != null) ...[
              Text(
                'Version ${info.latestVersion} is available',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDeep,
                ),
              ),
              if (info.hasAnyNotes) ...[
                const SizedBox(height: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => WhatsNewDialog.show(
                    context,
                    info: info,
                    onUpdate: () => context.read<AppUpdateCubit>().startUpdate(),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryDeep.withValues(alpha: 0.15),
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 14,
                          color: AppColors.primaryDeep,
                        ),
                        SizedBox(width: 5),
                        Text(
                          "View What's New",
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 15,
                          color: AppColors.primaryDeep,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              if (downloading) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: state.progress > 0 ? state.progress : null,
                    minHeight: 6,
                    color: AppColors.primaryDeep,
                    backgroundColor: AppColors.skyFill,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Downloading… ${(state.progress * 100).round()}%',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    color: AppColors.slate500,
                  ),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDeep,
                      foregroundColor: AppColors.surface,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () =>
                        context.read<AppUpdateCubit>().startUpdate(),
                    icon: const Icon(Icons.system_update_rounded, size: 18),
                    label: Text(
                      state.errorMessage.isEmpty
                          ? 'Update to v${info.latestVersion}'
                          : 'Retry update',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              if (state.errorMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  state.errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    color: AppColors.destructive,
                  ),
                ),
              ],
            ] else if (state.status == AppUpdateStatus.upToDate)
              const Text(
                "You're on the latest version",
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  color: AppColors.slate400,
                ),
              ),
          ],
        );
      },
    );
  }
}
