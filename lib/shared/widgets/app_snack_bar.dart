import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

enum AppSnackKind { info, success, error }

/// The one way to show a snackbar, for quick confirmations and failures the
/// user can ignore or retry. Field-level problems belong inline on the field
/// (`AppTextField.errorText`), not here.
///
/// Every snackbar gets an icon (never colour alone), stays long enough to
/// read, and replaces whatever is showing instead of queueing behind it.
abstract final class AppSnackBar {
  static void show(
    ScaffoldMessengerState messenger,
    String message, {
    AppSnackKind kind = AppSnackKind.info,
    SnackBarAction? action,
    Duration? duration,
  }) {
    final isError = kind == AppSnackKind.error;
    final (icon, iconColor, label) = switch (kind) {
      AppSnackKind.error => (
        Icons.error_outline_rounded,
        AppColors.onInk,
        'Error',
      ),
      AppSnackKind.success => (
        Icons.check_circle_outline_rounded,
        AppColors.matchHigh,
        'Success',
      ),
      AppSnackKind.info => (
        Icons.info_outline_rounded,
        AppColors.onInk,
        'Notice',
      ),
    };
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isError ? AppColors.destructive : AppColors.slate900,
          // Long enough to read; longer when there is something to tap.
          duration:
              duration ??
              Duration(seconds: action != null ? 8 : (isError ? 6 : 4)),
          action: action,
          content: Row(
            children: [
              Icon(icon, color: iconColor, size: 20, semanticLabel: label),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    color: AppColors.onInk,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  static void error(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) => show(
    ScaffoldMessenger.of(context),
    message,
    kind: AppSnackKind.error,
    action: action,
  );

  static void success(BuildContext context, String message) =>
      show(ScaffoldMessenger.of(context), message, kind: AppSnackKind.success);

  static void info(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) => show(ScaffoldMessenger.of(context), message, action: action);
}
