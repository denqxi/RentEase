import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../cubit/app_update_cubit.dart';

/// "New version" pop-up for the sign-in screen (no Profile tab exists before
/// login, so unlike [UpdateBanner] it carries its own Update button).
/// Automatically dismisses after 30 seconds unless update is forced.
/// Renders nothing when [AppUpdateCubit] is not in the tree (e.g. tests).
class SignInUpdateBanner extends StatefulWidget {
  const SignInUpdateBanner({super.key});

  @override
  State<SignInUpdateBanner> createState() => _SignInUpdateBannerState();
}

class _SignInUpdateBannerState extends State<SignInUpdateBanner> {
  Timer? _autoDismissTimer;

  void _syncTimer(AppUpdateState state, AppUpdateCubit cubit) {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;

    final forced = state.status == AppUpdateStatus.forced ||
        (state.info != null && (state.currentBuild ?? 0) < state.info!.minSupportedBuild);

    if (state.hasUpdate && !state.bannerDismissed && !forced) {
      _autoDismissTimer = Timer(const Duration(seconds: 30), () {
        if (mounted) {
          cubit.dismissBanner();
        }
      });
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppUpdateCubit cubit;
    try {
      cubit = context.read<AppUpdateCubit>();
    } on Object {
      return const SizedBox.shrink();
    }
    return BlocConsumer<AppUpdateCubit, AppUpdateState>(
      bloc: cubit,
      listenWhen: (prev, curr) =>
          prev.bannerDismissed != curr.bannerDismissed ||
          prev.status != curr.status ||
          prev.hasUpdate != curr.hasUpdate,
      listener: (context, state) => _syncTimer(state, cubit),
      builder: (context, state) {
        final info = state.info;
        if (!state.hasUpdate || info == null) return const SizedBox.shrink();
        if (state.bannerDismissed &&
            state.status == AppUpdateStatus.available) {
          return const SizedBox.shrink();
        }
        final forced = state.status == AppUpdateStatus.forced ||
            (state.currentBuild ?? 0) < info.minSupportedBuild;
        final downloading = state.status == AppUpdateStatus.downloading;

        if (_autoDismissTimer == null && !forced && !downloading) {
          _syncTimer(state, cubit);
        }

        return SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Material(
              color: AppColors.primaryDeep,
              elevation: 6,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
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
                                downloading
                                    ? 'Downloading… ${(state.progress * 100).round()}%'
                                    : 'v${info.latestVersion} is ready to install',
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 12,
                                  color: AppColors.surface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!downloading)
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryDeep,
                              backgroundColor: AppColors.surface,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              minimumSize: const Size(0, 34),
                            ),
                            onPressed: () {
                              _autoDismissTimer?.cancel();
                              cubit.startUpdate();
                            },
                            child: Text(
                              state.errorMessage.isEmpty ? 'Update' : 'Retry',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (!forced && !downloading)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.surface,
                              size: 20,
                            ),
                            onPressed: () {
                              _autoDismissTimer?.cancel();
                              cubit.dismissBanner();
                            },
                          )
                        else
                          const SizedBox(width: 8),
                      ],
                    ),
                    if (downloading)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 8, 8, 2),
                        child: LinearProgressIndicator(
                          value: state.progress > 0 ? state.progress : null,
                          minHeight: 5,
                          color: AppColors.surface,
                          backgroundColor: AppColors.skyFill,
                        ),
                      ),
                    if (state.errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 6, 8, 0),
                        child: Text(
                          state.errorMessage,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11.5,
                            color: AppColors.surface,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
