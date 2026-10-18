import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/firestore/models/models.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../uploads/data/repositories/cloudinary_image_upload_repository.dart';
import '../../uploads/domain/entities/uploaded_image.dart';
import '../../uploads/domain/repositories/image_upload_repository.dart';
import '../../uploads/presentation/cubit/image_upload_cubit.dart';
import '../../uploads/presentation/widgets/image_upload_slot.dart';
import 'listing_form_widgets.dart';
import 'listing_location_picker.dart';

/// Property types offered for an entire place / a new building.
const List<String> kPropertyTypes = [
  'Boarding House',
  'Dormitory',
  'Apartment',
  'Condo',
  'Others',
];

/// A building the owner can add rooms to. Derived from the owner's existing
/// room listings (grouped by `parentPropertyId`), or created in the wizard via
/// "+ Add New Property" (persisted with its first room).
class SavedBuilding {
  const SavedBuilding({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    this.type,
    this.coverPhoto,
    this.isNew = false,
  });

  final String id;
  final String name;
  final String? type;
  final String address;
  final LatLng location;

  /// Cover photo for the property/building (separate from individual room photos).
  final UploadedImage? coverPhoto;

  /// True until its first room has been posted.
  final bool isNew;

  /// Groups the owner's room listings into buildings. Only rooms carrying a
  /// `parentPropertyId` are grouped; the earliest listing's data is used.
  static List<SavedBuilding> fromListings(List<PropertyDoc> listings) {
    final byId = <String, SavedBuilding>{};
    for (final p in listings) {
      final id = p.parentPropertyId;
      if (!p.isRoom || id == null || id.isEmpty) continue;
      final existingCoverUrl = p.effectiveBuildingCoverPhoto;
      byId.putIfAbsent(
        id,
        () => SavedBuilding(
          id: id,
          name: (p.propertyName?.trim().isNotEmpty ?? false)
              ? p.propertyName!.trim()
              : p.title,
          type: p.propertyType,
          address: p.address,
          location: LatLng(p.location.latitude, p.location.longitude),
          coverPhoto: existingCoverUrl != null
              ? UploadedImage(
                  url: existingCoverUrl,
                  publicId: p.propertyCoverPublicId ??
                      (p.photoPublicIds.isNotEmpty
                          ? p.photoPublicIds.first
                          : ''),
                )
              : null,
        ),
      );
    }
    final list = byId.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }
}

/// Bottom sheet for "+ Add New Property": name, type, address, map pin, and
/// property cover photo. Returns the new [SavedBuilding] or null.
Future<SavedBuilding?> showNewPropertySheet(
  BuildContext context, {
  ImageUploadRepository? repository,
}) {
  return showModalBottomSheet<SavedBuilding>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.appColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _NewPropertySheet(repository: repository),
  );
}

class _NewPropertySheet extends StatefulWidget {
  const _NewPropertySheet({this.repository});

  final ImageUploadRepository? repository;

  @override
  State<_NewPropertySheet> createState() => _NewPropertySheetState();
}

class _NewPropertySheetState extends State<_NewPropertySheet> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  String? _type;
  LatLng? _pin;
  bool _resolving = false;

  late final ImageUploadCubit _coverUpload = ImageUploadCubit(
    repository: widget.repository ?? CloudinaryImageUploadRepository(),
    kind: ImageKind.propertyPhoto,
    slotCount: 1,
    minRequired: 1,
  );

  bool get _canSave =>
      !_resolving &&
      _nameController.text.trim().isNotEmpty &&
      _type != null &&
      _type!.trim().isNotEmpty &&
      _addressController.text.trim().isNotEmpty &&
      _pin != null &&
      _coverUpload.state.isReady;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _coverUpload.close();
    super.dispose();
  }

  void _save() {
    final images = _coverUpload.state.images;
    Navigator.of(context).pop(
      SavedBuilding(
        // Client-generated id; becomes the parentPropertyId of its rooms.
        id: 'b${DateTime.now().microsecondsSinceEpoch}',
        name: _nameController.text.trim(),
        type: _type,
        address: _addressController.text.trim(),
        location: _pin!,
        coverPhoto: images.isNotEmpty ? images.first : null,
        isNew: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Add new property',
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
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Text(
              'Save the building once, then add as many rooms as you like.',
              style: AppTextStyles.caption(context),
            ),
            const SizedBox(height: AppSpacing.lg),
            LabelledField(
              label: 'Property name',
              child: AppTextField(
                controller: _nameController,
                hintText: 'e.g. GL Boardinghouse',
                // Matches the 120-char cap in firestore.rules.
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
                options: kPropertyTypes,
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
              builder: (context, _) => AppPrimaryButton(
                label: 'Save property',
                onPressed: _canSave ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
