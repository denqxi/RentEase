import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:rentease/core/constants/app_colors.dart';

/// Centralized utility for checking location services, requesting app permissions,
/// prompting dialogs with direct redirects to device/app settings, and retrieving
/// current GPS coordinates.
class LocationPermissionHelper {
  LocationPermissionHelper._();

  /// Requests location access and returns the current coordinates [LatLng].
  ///
  /// - If location services (GPS) are turned off on the device, shows a dialog
  ///   prompting the user to turn it on with an "Open Settings" button that redirects
  ///   to device location settings (`Geolocator.openLocationSettings()`).
  /// - If permission is denied, requests system permission.
  /// - If permission is permanently denied (`deniedForever`), shows a dialog
  ///   with an "Open Settings" button that redirects to app settings (`Geolocator.openAppSettings()`).
  /// - If permission is granted and service is enabled, returns [LatLng].
  /// - Returns `null` if the user declines, cancels, or times out.
  static Future<LatLng?> getCurrentLocation(
    BuildContext context, {
    String? customPurposeMessage,
  }) async {
    try {
      // 1. Check if location services (GPS hardware toggle) are enabled on the device
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          await showLocationServiceDialog(
            context,
            message: customPurposeMessage,
          );
        }
        return null;
      }

      // 2. Check current app permission status
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Location permission was denied. Tap on the map to choose a position manually.',
                ),
                backgroundColor: AppColors.slate900,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return null;
        }
      }

      // 3. If permanently denied, redirect to App Settings
      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          await showPermissionDeniedDialog(
            context,
            message: customPurposeMessage,
          );
        }
        return null;
      }

      // 4. Fetch the high-accuracy position with an 8-second timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw Exception('Location request timed out'),
      );

      return LatLng(position.latitude, position.longitude);
    } on LocationServiceDisabledException {
      if (context.mounted) {
        await showLocationServiceDialog(
          context,
          message: customPurposeMessage,
        );
      }
      return null;
    } on PermissionDeniedException {
      if (context.mounted) {
        await showPermissionDeniedDialog(
          context,
          message: customPurposeMessage,
        );
      }
      return null;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('locationservicedisabled') ||
          (errorStr.contains('location service') && errorStr.contains('disabled'))) {
        if (context.mounted) {
          await showLocationServiceDialog(
            context,
            message: customPurposeMessage,
          );
        }
      } else if (errorStr.contains('permissiondenied') ||
          errorStr.contains('permission denied')) {
        if (context.mounted) {
          await showPermissionDeniedDialog(
            context,
            message: customPurposeMessage,
          );
        }
      } else if (errorStr.contains('timeout')) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location request timed out. Please check your GPS signal or tap on the map.',
              ),
              backgroundColor: AppColors.slate900,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not retrieve your location. Please ensure GPS is active or tap on the map.',
              ),
              backgroundColor: AppColors.slate900,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
      return null;
    }
  }

  /// Dialog shown when device location services (GPS) are turned off.
  /// Provides an "Open Settings" button directing straight to device location settings.
  static Future<void> showLocationServiceDialog(
    BuildContext context, {
    String? message,
  }) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_off_rounded, color: AppColors.amber700, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Location Turned Off',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.slate900,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message ??
              'Your device location (GPS) is turned off. Please turn it on in settings to pinpoint your location on the map.',
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            color: AppColors.slate600,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w600,
                color: AppColors.slate500,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await Geolocator.openLocationSettings();
              } catch (_) {}
            },
            child: const Text(
              'Open Settings',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w700,
                color: AppColors.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dialog shown when location permission is permanently denied.
  /// Provides an "Open Settings" button directing to the app's permission settings.
  static Future<void> showPermissionDeniedDialog(
    BuildContext context, {
    String? message,
  }) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_person_rounded, color: AppColors.primaryDeep, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Permission Needed',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.slate900,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message ??
              'Location permission is disabled for RentEase. Please allow location access in your device settings to locate your position.',
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            color: AppColors.slate600,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w600,
                color: AppColors.slate500,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await Geolocator.openAppSettings();
              } catch (_) {}
            },
            child: const Text(
              'Open Settings',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w700,
                color: AppColors.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
