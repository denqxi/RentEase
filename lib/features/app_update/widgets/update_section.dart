import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../cubit/app_update_cubit.dart';

/// Replaces the static "RentEase prototype · v1.0" footer on the profile
/// screens: shows the real installed version and, when a newer build is
/// published, the release notes and an Update button (below Log out, so it
/// can't be mistaken for it). Needs [AppUpdateCubit] above it in the tree.
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
              if (info.notes.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  info.notes,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.slate500,
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
