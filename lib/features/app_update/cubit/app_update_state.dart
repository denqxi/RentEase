part of 'app_update_cubit.dart';

enum AppUpdateStatus {
  /// Not checked yet (or the check failed silently).
  idle,
  upToDate,

  /// A newer build exists; the user may postpone.
  available,

  /// Installed build is below `minSupportedBuild`; must update.
  forced,
  downloading,
}

class AppUpdateState extends Equatable {
  const AppUpdateState({
    this.status = AppUpdateStatus.idle,
    this.info,
    this.currentVersion,
    this.currentBuild,
    this.progress = 0,
    this.bannerDismissed = false,
    this.errorMessage = '',
  });

  final AppUpdateStatus status;
  final AppUpdateInfo? info;
  final String? currentVersion;
  final int? currentBuild;

  /// Download progress, 0.0 to 1.0.
  final double progress;
  final bool bannerDismissed;
  final String errorMessage;

  bool get hasUpdate =>
      status == AppUpdateStatus.available ||
      status == AppUpdateStatus.forced ||
      (status == AppUpdateStatus.downloading && info != null);

  bool get showBanner =>
      (status == AppUpdateStatus.available && !bannerDismissed) ||
      status == AppUpdateStatus.forced;

  AppUpdateState copyWith({
    AppUpdateStatus? status,
    AppUpdateInfo? info,
    String? currentVersion,
    int? currentBuild,
    double? progress,
    bool? bannerDismissed,
    String? errorMessage,
  }) =>
      AppUpdateState(
        status: status ?? this.status,
        info: info ?? this.info,
        currentVersion: currentVersion ?? this.currentVersion,
        currentBuild: currentBuild ?? this.currentBuild,
        progress: progress ?? this.progress,
        bannerDismissed: bannerDismissed ?? this.bannerDismissed,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => <Object?>[
        status,
        info?.latestBuild,
        currentVersion,
        currentBuild,
        progress,
        bannerDismissed,
        errorMessage,
      ];
}
