import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum ApkInstallResult { launched, permissionDenied, failed }

/// Downloads the update APK and hands it to Android's package installer.
/// Abstract so tests can fake it.
abstract class ApkInstaller {
  Future<ApkInstallResult> downloadAndInstall(
    String url, {
    required void Function(double progress) onProgress,
  });
}

class DioApkInstaller implements ApkInstaller {
  const DioApkInstaller();

  @override
  Future<ApkInstallResult> downloadAndInstall(
    String url, {
    required void Function(double progress) onProgress,
  }) async {
    // Only https downloads are ever attempted.
    if (Uri.tryParse(url)?.scheme != 'https') return ApkInstallResult.failed;

    try {
      // "Install unknown apps" for RentEase (Android 8+).
      var status = await Permission.requestInstallPackages.status;
      if (!status.isGranted) {
        status = await Permission.requestInstallPackages.request();
        if (!status.isGranted) return ApkInstallResult.permissionDenied;
      }

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/rentease_update.apk';
      await Dio().download(
        url,
        path,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress(received / total);
        },
      );

      final result = await OpenFilex.open(
        path,
        type: 'application/vnd.android.package-archive',
      );
      return result.type == ResultType.done
          ? ApkInstallResult.launched
          : ApkInstallResult.failed;
    } catch (_) {
      return ApkInstallResult.failed;
    }
  }
}
