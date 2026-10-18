import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../owner_onboarding/widgets/listing_form_widgets.dart';
import '../../owner_onboarding/widgets/listing_location_picker.dart';
import '../../uploads/data/repositories/cloudinary_image_upload_repository.dart';
import '../../uploads/domain/entities/uploaded_image.dart';
import '../../uploads/presentation/cubit/image_upload_cubit.dart';
import '../../uploads/presentation/widgets/image_upload_slot.dart';

const List<String> kBuildingTypes = [
  'Boarding House',
  'Dormitory',
  'Apartment',
  'Condo',
  'Others',
];

/// Bottom sheet to edit building/property metadata (Name, Type, Address, Map Pin, and Cover Photo).
Future<void> showEditPropertySheet({
  required BuildContext context,
  required String initialName,
  required String? initialType,
  required String initialAddress,
  required LatLng? initialLocation,
  String? initialCoverPhotoUrl,
  String? initialCoverPublicId,
  required Future<void> Function({
    required String name,
    required String type,
    required String address,
    required LatLng location,
    UploadedImage? coverPhoto,
  }) onSave,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    enableDrag: false,
    backgroundColor: context.appColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _EditPropertySheet(
      initialName: initialName,
      initialType: initialType,
      initialAddress: initialAddress,
      initialLocation: initialLocation,
      initialCoverPhotoUrl: initialCoverPhotoUrl,
      initialCoverPublicId: initialCoverPublicId,
      onSave: onSave,
    ),
  );
}

class _EditPropertySheet extends StatefulWidget {
  const _EditPropertySheet({
    required this.initialName,
    required this.initialType,
    required this.initialAddress,
    required this.initialLocation,
    this.initialCoverPhotoUrl,
    this.initialCoverPublicId,
    required this.onSave,
  });

  final String initialName;
  final String? initialType;
  final String initialAddress;
  final LatLng? initialLocation;
  final String? initialCoverPhotoUrl;
  final String? initialCoverPublicId;
  final Future<void> Function({
    required String name,
    required String type,
    required String address,
    required LatLng location,
    UploadedImage? coverPhoto,
  }) onSave;

  @override
  State<_EditPropertySheet> createState() => _EditPropertySheetState();
}

class _EditPropertySheetState extends State<_EditPropertySheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late String? _type;
  late LatLng? _pin;
  late final ImageUploadCubit _coverUpload;
  bool _saving = false;
  bool _resolving = false;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _addressController = TextEditingController(text: widget.initialAddress);
    _type = (widget.initialType != null && widget.initialType!.trim().isNotEmpty)
        ? widget.initialType
        : kBuildingTypes.first;
    _pin = widget.initialLocation;

    final coverUrl = widget.initialCoverPhotoUrl?.trim();
    _coverUpload = ImageUploadCubit(
      repository: CloudinaryImageUploadRepository(),
      kind: ImageKind.propertyPhoto,
      slotCount: 1,
      minRequired: 1,
      initialImages: [
        if (coverUrl != null && coverUrl.isNotEmpty)
          UploadedImage(
            url: coverUrl,
            publicId: widget.initialCoverPublicId ?? '',
          ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _coverUpload.close();
    super.dispose();
  }

  bool get _hasChanges {
    if (_nameController.text.trim() != widget.initialName.trim()) return true;

    final initialType =
        (widget.initialType != null && widget.initialType!.trim().isNotEmpty)
            ? widget.initialType
            : kBuildingTypes.first;
    if (_type != initialType) return true;

    if (_addressController.text.trim() != widget.initialAddress.trim()) {
      return true;
    }

    if (_pin == null && widget.initialLocation != null) return true;
    if (_pin != null && widget.initialLocation == null) return true;
    if (_pin != null && widget.initialLocation != null) {
      if ((_pin!.latitude - widget.initialLocation!.latitude).abs() > 0.0001 ||
          (_pin!.longitude - widget.initialLocation!.longitude).abs() > 0.0001) {
        return true;
      }
    }

    if (_coverUpload.state.isUploading) return true;
    final currentImages = _coverUpload.state.images;
    final initialUrl = widget.initialCoverPhotoUrl?.trim() ?? '';
    if (initialUrl.isEmpty) {
      if (currentImages.isNotEmpty) return true;
    } else {
      if (currentImages.isEmpty) return true;
      if (currentImages.first.url != initialUrl) return true;
    }

    return false;
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasChanges) return true;

    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Discard changes?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.destructive,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return discard ?? false;
  }

  bool get _canSave =>
      !_saving &&
      !_resolving &&
      _nameController.text.trim().isNotEmpty &&
      _type != null &&
      _type!.trim().isNotEmpty &&
      _addressController.text.trim().isNotEmpty &&
      _pin != null &&
      _coverUpload.state.isReady;

  Future<void> _handleSave() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    try {
      final images = _coverUpload.state.images;
      await widget.onSave(
        name: _nameController.text.trim(),
        type: _type!,
        address: _addressController.text.trim(),
        location: _pin!,
        coverPhoto: images.isNotEmpty ? images.first : null,
      );
      if (!mounted) return;
      _allowPop = true;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update property: $e'),
          backgroundColor: AppColors.destructive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop || !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscard();
        if (shouldPop && context.mounted) {
          _allowPop = true;
          Navigator.of(context).pop();
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Edit property',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () async {
                      final shouldPop = await _confirmDiscard();
                      if (shouldPop && context.mounted) {
                        _allowPop = true;
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ),
              Text(
                'Update building name, type, address, location pin, and cover photo.',
                style: AppTextStyles.caption(context),
              ),
              const SizedBox(height: AppSpacing.lg),
              LabelledField(
                label: 'Property name',
                child: AppTextField(
                  controller: _nameController,
                  hintText: 'e.g. GL Boardinghouse',
                  inputFormatters: [LengthLimitingTextInputFormatter(120)],
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              LabelledField(
                label: 'Property type',
                child: PropertyTypeDropdown(
                  value: _type,
                  hint: 'Select property type',
                  options: kBuildingTypes,
                  onChanged: (v) => setState(() => _type = v),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ListingLocationPicker(
                addressController: _addressController,
                pin: _pin,
                onPinChanged: (p) => setState(() => _pin = p),
                onChanged: (resolving) => setState(() => _resolving = resolving),
              ),
              const SizedBox(height: AppSpacing.md),
              LabelledField(
                label: 'Property cover photo',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BlocBuilder<ImageUploadCubit, ImageUploadState>(
                      bloc: _coverUpload,
                      builder: (context, state) => SizedBox(
                        width: 112,
                        child: ImageUploadSlot(
                          slot: state.slots.first,
                          emptyLabel: 'Property Cover',
                          onPick: (src) => _coverUpload.pickAndUpload(0, src),
                          onRetry: () => _coverUpload.retry(0),
                          onRemove: () => _coverUpload.remove(0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add 1 cover photo for the property. Each room listing will have its own photos.',
                      style: AppTextStyles.caption(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              BlocBuilder<ImageUploadCubit, ImageUploadState>(
                bloc: _coverUpload,
                builder: (context, _) => SizedBox(
                  width: double.infinity,
                  child: AppPrimaryButton(
                    label: _saving ? 'Saving...' : 'Save changes',
                    onPressed: _canSave ? _handleSave : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
