import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/app_update_service.dart';
import '../model/app_update_info.dart';
import '../services/apk_installer.dart';

part 'app_update_state.dart';

/// Checks `version.json` for a newer build and drives the download + install.
class AppUpdateCubit extends Cubit<AppUpdateState> {
  AppUpdateCubit({
    AppUpdateService service = const GithubAppUpdateService(),
    ApkInstaller installer = const DioApkInstaller(),
    this.minCheckInterval = const Duration(minutes: 30),
  })  : _service = service,
        _installer = installer,
        super(const AppUpdateState());

  final AppUpdateService _service;
  final ApkInstaller _installer;
  final Duration minCheckInterval;
  DateTime? _lastCheck;

  /// Safe to call often (startup / app resume): checks are throttled unless
  /// [force] is true, and failures are silent.
  Future<void> checkForUpdate({bool force = false}) async {
    if (state.status == AppUpdateStatus.downloading) return;
    final last = _lastCheck;
    if (!force &&
        last != null &&
        DateTime.now().difference(last) < minCheckInterval) {
      return;
    }
    _lastCheck = DateTime.now();

    final installed = await _service.installedVersion();
    if (installed == null) return;
    emit(state.copyWith(
      currentVersion: installed.version,
      currentBuild: installed.build,
    ));

    final latest = await _service.fetchLatest();
    if (latest == null) return; // offline / bad file: stay as we were.

    if (latest.latestBuild > installed.build) {
      final forced = installed.build < latest.minSupportedBuild;
      emit(state.copyWith(
        status:
            forced ? AppUpdateStatus.forced : AppUpdateStatus.available,
        info: latest,
        bannerDismissed: false,
      ));
    } else {
      emit(state.copyWith(status: AppUpdateStatus.upToDate));
    }
  }

  /// Downloads the APK, then opens Android's installer (user taps Install).
  Future<void> startUpdate() async {
    final info = state.info;
    if (info == null || state.status == AppUpdateStatus.downloading) return;

    emit(state.copyWith(
      status: AppUpdateStatus.downloading,
      progress: 0,
      errorMessage: '',
    ));
    final result = await _installer.downloadAndInstall(
      info.apkUrl,
      onProgress: (p) => emit(state.copyWith(progress: p)),
    );

    final stillForced = (state.currentBuild ?? 0) < info.minSupportedBuild;
    final back =
        stillForced ? AppUpdateStatus.forced : AppUpdateStatus.available;
    switch (result) {
      case ApkInstallResult.launched:
        // Installer is on screen; if the user cancels, the button stays.
        emit(state.copyWith(status: back, errorMessage: ''));
      case ApkInstallResult.permissionDenied:
        emit(state.copyWith(
          status: back,
          errorMessage:
              'Allow "Install unknown apps" for RentEase, then tap Update again.',
        ));
      case ApkInstallResult.failed:
        emit(state.copyWith(
          status: back,
          errorMessage: "Couldn't download the update. Please try again.",
        ));
    }
  }

  /// Hides the banner for this session (optional updates only).
  void dismissBanner() {
    if (state.status == AppUpdateStatus.forced) return;
    emit(state.copyWith(bannerDismissed: true));
  }
}
