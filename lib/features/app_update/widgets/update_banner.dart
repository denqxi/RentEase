import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../shell/cubit/shell_cubit.dart';
import '../cubit/app_update_cubit.dart';

/// Floating "new version" pop-up shown at the top of the app shells.
/// Tapping it opens the Profile tab, where the Update button lives.
/// Needs [AppUpdateCubit] and [ShellCubit] above it in the tree.
class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppUpdateCubit, AppUpdateState>(
      builder: (context, state) {
        final info = state.info;
        if (!state.showBanner || info == null) return const SizedBox.shrink();
        final forced = state.status == AppUpdateStatus.forced;

        return SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Material(
              color: AppColors.primaryDeep,
              elevation: 6,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () =>
                    context.read<ShellCubit>().selectTab(ShellTab.profile),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.system_update_rounded,
                        color: AppColors.surface,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              forced
                                  ? 'Update required'
                                  : 'New version available',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.surface,
                              ),
                            ),
                            Text(
                              'v${info.latestVersion} · Tap to update in Profile',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                color: AppColors.surface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!forced)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.surface,
                            size: 20,
                          ),
                          onPressed: () =>
                              context.read<AppUpdateCubit>().dismissBanner(),
                        )
                      else
                        const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
