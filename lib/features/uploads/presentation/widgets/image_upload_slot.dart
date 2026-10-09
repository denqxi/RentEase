import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/uploaded_image.dart';
import '../cubit/image_upload_cubit.dart';

/// One upload slot: empty (tap to choose gallery/camera), uploading
/// (thumbnail + spinner), success (thumbnail + remove) or failure
/// (message + retry/remove). Purely presentational; actions go to callbacks.
class ImageUploadSlot extends StatelessWidget {
  const ImageUploadSlot({
    required this.slot,
    required this.onPick,
    required this.onRetry,
    required this.onRemove,
    this.height = 88,
    this.emptyIcon = Icons.add_a_photo_outlined,
    this.emptyLabel,
    this.showPreview = true,
    this.onMoveEarlier,
    this.onReplace,
    super.key,
  });

  /// Optional extras on a successful slot (null = not shown): move one place
  /// toward the cover, and replace the photo with a new pick.
  final VoidCallback? onMoveEarlier;
  final ValueChanged<PickSource>? onReplace;

  /// When false (private documents) no image is rendered; an "Uploaded"
  /// indicator with the file name is shown instead.
  final bool showPreview;

  final UploadSlot slot;
  final ValueChanged<PickSource> onPick;
  final VoidCallback onRetry;
  final VoidCallback onRemove;
  final double height;
  final IconData emptyIcon;
  final String? emptyLabel;

  Future<void> _choose(BuildContext context, [ValueChanged<PickSource>? cb]) async {
    final source = await showModalBottomSheet<PickSource>(
      context: context,
      backgroundColor: context.appColors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(ctx).pop(PickSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(ctx).pop(PickSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source != null) (cb ?? onPick)(source);
  }

  @override
  Widget build(BuildContext context) {
    final status = slot.status;
    final borderColor = switch (status) {
      SlotStatus.success => AppColors.accent,
      SlotStatus.failure => AppColors.destructive,
      _ => context.appColors.fieldBorder,
    };

    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: status == SlotStatus.success
            ? AppColors.accentSoft
            : context.appColors.fieldFill,
        borderRadius: BorderRadius.circular(AppRadii.field),
        border: Border.all(
          color: borderColor,
          width: status == SlotStatus.empty ? 1 : 1.5,
        ),
      ),
      child: switch (status) {
        SlotStatus.empty => InkWell(
          onTap: () => _choose(context),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(emptyIcon, color: context.appColors.hint, size: 22),
                if (emptyLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    emptyLabel!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context),
                  ),
                ],
              ],
            ),
          ),
        ),
        SlotStatus.uploading => Stack(
          fit: StackFit.expand,
          children: [
            _thumb(context),
            ColoredBox(color: AppColors.ink.withValues(alpha: 0.45)),
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.onInk,
                ),
              ),
            ),
          ],
        ),
        SlotStatus.success => Stack(
          fit: StackFit.expand,
          children: [
            _thumb(context),
            Positioned(
              top: 2,
              right: 2,
              child: _iconButton(Icons.close, onRemove, 'Remove photo'),
            ),
            if (onReplace != null)
              Positioned(
                top: 2,
                left: 2,
                child: _iconButton(
                  Icons.edit_outlined,
                  () => _choose(context, onReplace),
                  'Replace photo',
                ),
              ),
            if (onMoveEarlier != null)
              Positioned(
                bottom: 2,
                right: 2,
                child: _iconButton(
                  Icons.arrow_back_rounded,
                  onMoveEarlier!,
                  'Move earlier',
                ),
              ),
            const Positioned(
              bottom: 4,
              left: 4,
              child: Icon(
                Icons.check_circle_rounded,
                color: AppColors.matchHigh,
                size: 18,
              ),
            ),
          ],
        ),
        SlotStatus.failure => Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                slot.error ?? 'Upload failed',
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(
                  context,
                ).copyWith(color: AppColors.destructive),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (slot.localPath != null)
                    TextButton(
                      onPressed: onRetry,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('Retry'),
                    ),
                  TextButton(
                    onPressed: onRemove,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      foregroundColor: AppColors.destructive,
                    ),
                    child: const Text('Remove'),
                  ),
                ],
              ),
            ],
          ),
        ),
      },
    );
  }

  Widget _thumb(BuildContext context) => !showPreview
      ? Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.description_outlined,
                  color: AppColors.accent,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  slot.localPath == null
                      ? 'Uploaded'
                      : 'Uploaded: ${slot.localPath!.split(RegExp(r'[\\/]')).last}',
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context),
                ),
              ],
            ),
          ),
        )
      : slot.localPath == null
      ? (slot.image?.url == null
            ? const SizedBox.expand()
            : Image.network(
                slot.image!.url,
                fit: BoxFit.cover,
                cacheWidth: 400,
                errorBuilder: (_, _, _) => const SizedBox.expand(),
              ))
      : kIsWeb
      ? Image.network(
          slot.localPath!,
          fit: BoxFit.cover,
          cacheWidth: 400,
          errorBuilder: (_, _, _) => const SizedBox.expand(),
        )
      : Image.file(
          File(slot.localPath!),
          fit: BoxFit.cover,
          cacheWidth: 400,
          errorBuilder: (_, _, _) => const SizedBox.expand(),
        );

  Widget _iconButton(IconData icon, VoidCallback onTap, [String? label]) =>
      Semantics(
    button: true,
    label: label,
    child: GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.ink.withValues(alpha: 0.65),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: AppColors.onInk),
      ),
    ),
    ),
  );
}
