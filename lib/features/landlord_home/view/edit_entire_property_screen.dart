import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/cloudinary_config.dart';
import '../../../core/firestore/models/models.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../owner_onboarding/widgets/listing_form_widgets.dart';
import '../../owner_onboarding/widgets/listing_location_picker.dart';
import '../../uploads/data/repositories/cloudinary_image_upload_repository.dart';
import '../../uploads/domain/entities/uploaded_image.dart';
import '../../uploads/domain/repositories/image_upload_repository.dart';
import '../../uploads/presentation/cubit/image_upload_cubit.dart';

/// Dedicated screen for editing basic details & photos of an entire-property
/// or room listing.
///
/// Rent, House Rules, and Amenities are edited directly via expandable cards
/// on the Property / Room Management screen.
class EditEntirePropertyScreen extends StatefulWidget {
  const EditEntirePropertyScreen({
    required this.property,
    required this.onSave,
    this.uploadRepository,
    this.initialTabIndex = 0,
    super.key,
  });

  final PropertyDoc property;
  final Future<void> Function(Map<String, dynamic> updates) onSave;
  final ImageUploadRepository? uploadRepository;
  final int initialTabIndex;

  @override
  State<EditEntirePropertyScreen> createState() =>
      _EditEntirePropertyScreenState();
}

class _EditEntirePropertyScreenState extends State<EditEntirePropertyScreen> {
  static const List<String> _propertyTypes = [
    'Boarding House',
    'Dormitory',
    'Apartment',
    'Condo',
    'Others',
  ];

  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _roomNameController;
  late final TextEditingController _addressController;

  // Form State
  late String _propertyType;
  late LatLng _location;

  bool _isSaving = false;
  late final ImageUploadCubit _uploads;

  @override
  void initState() {
    super.initState();
    final p = widget.property;

    final name = (p.propertyName?.trim().isNotEmpty ?? false)
        ? p.propertyName!.trim()
        : p.title;
    final roomName = (p.roomName?.trim().isNotEmpty ?? false)
        ? p.roomName!.trim()
        : p.title;

    _nameController = TextEditingController(text: name);
    _roomNameController = TextEditingController(text: roomName);
    _addressController = TextEditingController(text: p.address);

    _propertyType = (p.propertyType != null && p.propertyType!.trim().isNotEmpty)
        ? p.propertyType!
        : 'Boarding House';
    _location = LatLng(p.location.latitude, p.location.longitude);

    final uploadRepo =
        widget.uploadRepository ?? CloudinaryImageUploadRepository();
    _uploads = ImageUploadCubit(
      repository: uploadRepo,
      kind: ImageKind.propertyPhoto,
      slotCount: CloudinaryConfig.maxPropertyPhotos,
      minRequired: 1,
      initialImages: [
        for (
          var i = 0;
          i < p.photos.length && i < CloudinaryConfig.maxPropertyPhotos;
          i++
        )
          UploadedImage(
            url: p.photos[i],
            publicId: i < p.photoPublicIds.length ? p.photoPublicIds[i] : '',
          ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roomNameController.dispose();
    _addressController.dispose();
    _uploads.close();
    super.dispose();
  }

  bool get _hasChanges {
    final p = widget.property;
    if (p.isRoom) {
      final currentRoomName = (p.roomName?.trim().isNotEmpty ?? false)
          ? p.roomName!.trim()
          : p.title;
      if (_roomNameController.text.trim() != currentRoomName) return true;
    } else {
      final currentName = (p.propertyName?.trim().isNotEmpty ?? false)
          ? p.propertyName!.trim()
          : p.title;
      final initialType =
          (p.propertyType != null && p.propertyType!.trim().isNotEmpty)
              ? p.propertyType!
              : 'Boarding House';

      if (_nameController.text.trim() != currentName) return true;
      if (_addressController.text.trim() != p.address) return true;
      if (_propertyType != initialType) return true;
      if ((_location.latitude - p.location.latitude).abs() > 0.0001 ||
          (_location.longitude - p.location.longitude).abs() > 0.0001) {
        return true;
      }
    }

    final currentImages = _uploads.state.images;
    if (currentImages.length != p.photos.length) return true;
    for (var i = 0; i < currentImages.length; i++) {
      if (currentImages[i].url != p.photos[i]) return true;
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

  Future<void> _handleSave() async {
    final isRoom = widget.property.isRoom;
    final name = _nameController.text.trim();
    final roomName = _roomNameController.text.trim();
    final address = _addressController.text.trim();

    if (isRoom) {
      if (roomName.isEmpty) {
        _showError('Room name or number cannot be empty.');
        return;
      }
    } else {
      if (name.isEmpty) {
        _showError('Property name cannot be empty.');
        return;
      }
      if (address.isEmpty) {
        _showError('Complete address is required.');
        return;
      }
    }

    if (_uploads.state.isUploading) {
      _showError('Photos are still uploading. Please wait.');
      return;
    }

    final images = _uploads.state.images;
    if (images.isEmpty) {
      _showError('At least one photo is required.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final photoUrls = [for (final img in images) img.url];
      final photoPublicIds = [for (final img in images) img.publicId];

      final updates = <String, dynamic>{
        if (isRoom) ...{
          'roomName': roomName,
          'title': () {
            final bName =
                (widget.property.propertyName?.trim().isNotEmpty ?? false)
                    ? widget.property.propertyName!.trim()
                    : '';
            final raw = bName.isNotEmpty ? '$bName – $roomName' : roomName;
            return raw.length > 120 ? raw.substring(0, 120) : raw;
          }(),
        } else ...{
          'title': name.length > 120 ? name.substring(0, 120) : name,
          'propertyName': name.length > 120 ? name.substring(0, 120) : name,
          'propertyType': _propertyType,
          'address': address.length > 300 ? address.substring(0, 300) : address,
          'location': GeoPoint(_location.latitude, _location.longitude),
        },
        'photos': photoUrls,
        'photoPublicIds': photoPublicIds,
      };

      await widget.onSave(updates);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isRoom
                ? 'Room details saved successfully.'
                : 'Property details saved successfully.',
          ),
          backgroundColor: AppColors.slate900,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to save changes: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.destructive,
      ),
    );
  }

  Future<void> _confirmRemovePhoto(int index) async {
    final images = _uploads.state.images;
    if (images.length <= 1) {
      _showError('A listing must have at least one photo.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Remove Photo?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Are you sure you want to remove this photo from the listing?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: AppColors.surface,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _uploads.remove(index);
    }
  }

  void _addPhoto() {
    final nextSlot =
        _uploads.state.slots.indexWhere((s) => s.status == SlotStatus.empty);
    if (nextSlot == -1) {
      _showError('Maximum ${_uploads.state.slots.length} photos allowed.');
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(bCtx).pop();
                  _uploads.pickAndUpload(nextSlot, PickSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.of(bCtx).pop();
                  _uploads.pickAndUpload(nextSlot, PickSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRoom = widget.property.isRoom;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscard();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: context.appColors.textPrimary,
            onPressed: () async {
              final shouldPop = await _confirmDiscard();
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          centerTitle: false,
          title: Text(
            isRoom ? 'Edit Room Details' : 'Edit Property Details',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.appColors.textPrimary,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(color: AppColors.fieldFill, height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isRoom)
                        _buildRoomDetailsSection()
                      else
                        _buildEntirePropertyDetailsSection(),

                      const SizedBox(height: 18),
                      const Divider(color: AppColors.fieldFill, height: 1),
                      const SizedBox(height: 16),

                      _buildPhotosSection(isRoom: isRoom),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ── Bottom Fixed Save Changes Bar ─────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.fieldFill)),
                ),
                child: BlocBuilder<ImageUploadCubit, ImageUploadState>(
                  bloc: _uploads,
                  builder: (context, uploadState) {
                    final isBusy = _isSaving || uploadState.isUploading;
                    return SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.surface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isBusy ? null : _handleSave,
                        child: Text(
                          _isSaving
                              ? 'Saving Changes...'
                              : uploadState.isUploading
                                  ? 'Uploading Photos...'
                                  : 'Save Changes',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntirePropertyDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Property Information',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.slate900,
          ),
        ),
        const SizedBox(height: 12),
        LabelledField(
          label: 'Property name',
          child: AppTextField(
            controller: _nameController,
            hintText: 'e.g. La Boarding House',
            inputFormatters: [LengthLimitingTextInputFormatter(120)],
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 12),
        LabelledField(
          label: 'Property type',
          child: PropertyTypeDropdown(
            value: _propertyType,
            hint: 'Select property type',
            options: _propertyTypes,
            onChanged: (val) {
              if (val != null) setState(() => _propertyType = val);
            },
          ),
        ),
        const SizedBox(height: 12),
        ListingLocationPicker(
          addressController: _addressController,
          pin: _location,
          onPinChanged: (newLoc) {
            setState(() => _location = newLoc);
          },
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildRoomDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Room Information',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.slate900,
          ),
        ),
        const SizedBox(height: 12),
        LabelledField(
          label: 'Room name or number',
          child: AppTextField(
            controller: _roomNameController,
            hintText: 'e.g. Room 101',
            inputFormatters: [LengthLimitingTextInputFormatter(60)],
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.slate50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.apartment_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _nameController.text.isNotEmpty
                          ? _nameController.text
                          : 'Parent Property',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _propertyType,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1.5),
                    child: Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      _addressController.text,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: AppColors.slate500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Building name, type, and address are managed from the main Property page.',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11.5,
                  color: AppColors.slate400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosSection({required bool isRoom}) {
    return BlocBuilder<ImageUploadCubit, ImageUploadState>(
      bloc: _uploads,
      builder: (context, uploadState) {
        final slotsWithImages = <(int index, UploadSlot slot)>[];
        for (var i = 0; i < uploadState.slots.length; i++) {
          final slot = uploadState.slots[i];
          if (slot.status != SlotStatus.empty) {
            slotsWithImages.add((i, slot));
          }
        }

        final canAddMore =
            slotsWithImages.length < CloudinaryConfig.maxPropertyPhotos;
        final totalGridItems = slotsWithImages.length + (canAddMore ? 1 : 0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  isRoom ? 'Room Photos' : 'Property Photos',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.5,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.fieldFill,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${slotsWithImages.length} / ${CloudinaryConfig.maxPropertyPhotos}',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            const Text(
              'Add 1 to ${CloudinaryConfig.maxPropertyPhotos} photos. The first photo is the cover.',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                color: AppColors.slate500,
              ),
            ),
            const SizedBox(height: 12),

            // Compact 3-Column Photo Grid with inline Add Photo tile
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.05,
              ),
              itemCount: totalGridItems,
              itemBuilder: (context, idx) {
                // Inline "+ Add Photo" tile at the end of the grid
                if (idx == slotsWithImages.length) {
                  return Material(
                    color: AppColors.transparent,
                    child: InkWell(
                      onTap: _addPhoto,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Add Photo',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                color: AppColors.primary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final (slotIndex, slot) = slotsWithImages[idx];
                final isCover = idx == 0;
                final imageUrl = slot.image?.url;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.fieldFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              cacheWidth: 600,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.hint,
                                  size: 20,
                                ),
                              ),
                            )
                          : const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                    ),
                    if (isCover)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.scrim.withValues(alpha: 0.68),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            'Cover',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              color: AppColors.surface,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: InkWell(
                        onTap: () => _confirmRemovePhoto(slotIndex),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.scrim.withValues(alpha: 0.12),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: AppColors.slate900,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}
