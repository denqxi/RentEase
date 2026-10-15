import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/cloudinary_config.dart';
import '../../../core/firestore/models/models.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../owner_onboarding/widgets/listing_form_widgets.dart';
import '../../owner_onboarding/widgets/listing_location_picker.dart';
import '../../uploads/data/repositories/cloudinary_image_upload_repository.dart';
import '../../uploads/domain/entities/uploaded_image.dart';
import '../../uploads/domain/repositories/image_upload_repository.dart';
import '../../uploads/presentation/cubit/image_upload_cubit.dart';

/// Dedicated screen for editing an existing entire-property listing.
///
/// Organized into 5 distinct tabbed sections matching the RentEase design system:
/// 1. Details: Property name, property type, full address, and location pin.
/// 2. Photos: 2-column gallery with individual deletion and Add Photo button.
/// 3. Rent & Capacity: Monthly rent, occupants, and availability toggle.
/// 4. House Rules: Deposit, advance, who can rent, smoking, pets, and curfew.
/// 5. Amenities: Categorized checklist of all available features.
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
    'House',
    'Apartment',
    'Condominium',
    'Studio Unit',
    'Boarding House',
    'Other',
  ];

  static const List<int> _advanceOptions = [0, 1, 2, 3];
  static const List<String> _genderOptions = [
    'Anyone',
    'Mixed / Any',
    'Female only',
    'Male only',
  ];
  static const List<int?> _curfewOptions = [null, 20, 21, 22, 23, 0];

  static const List<String> _amenitiesList = [
    'WiFi',
    'Air conditioning',
    'Electric fan',
    'Furnished room',
    'Private bathroom',
    'Laundry facility',
    'Kitchen or cooking area',
    'Refrigerator access',
    'CCTV or security camera',
    'Parking space',
    'Study area or desk',
    '24-hour access',
    'Water included in rent',
    'Electricity included in rent',
  ];

  // Active Tab: 0 = Details, 1 = Photos, 2 = Rent, 3 = Rules, 4 = Amenities
  late int _currentTab;

  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _rentController;
  late final TextEditingController _depositController;
  late final TextEditingController _occupantsController;

  // Form State
  late String _propertyType;
  late LatLng _location;
  late int _advanceMonths;
  late String _allowedGender;
  late bool _smokingAllowed;
  late bool _petsAllowed;
  late int? _curfewHours;
  late bool _isAvailable;
  late Set<String> _amenities;

  bool _isSaving = false;
  late final ImageUploadCubit _uploads;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTabIndex.clamp(0, 4);
    final p = widget.property;

    final name = (p.propertyName?.trim().isNotEmpty ?? false)
        ? p.propertyName!.trim()
        : p.title;

    _nameController = TextEditingController(text: name);
    _addressController = TextEditingController(text: p.address);
    _rentController = TextEditingController(
      text: p.monthlyRent > 0 ? '${p.monthlyRent.round()}' : '',
    );
    _depositController = TextEditingController(
      text: p.depositAmount > 0 ? '${p.depositAmount.round()}' : '',
    );
    _occupantsController = TextEditingController(
      text: p.maxOccupants > 0 ? '${p.maxOccupants.round()}' : '1',
    );

    _propertyType = _propertyTypes.contains(p.propertyType)
        ? p.propertyType!
        : 'Apartment';
    _location = LatLng(p.location.latitude, p.location.longitude);
    _advanceMonths = _advanceOptions.contains(p.advanceMonths.round())
        ? p.advanceMonths.round()
        : 1;
    _allowedGender = _genderOptions.contains(p.allowedGender)
        ? p.allowedGender
        : 'Anyone';
    _smokingAllowed = p.smokingAllowed;
    _petsAllowed = p.petsAllowed;
    _curfewHours = p.curfewHours?.toInt();
    _isAvailable = p.isAvailable && p.vacancyStatus != 'booked';
    _amenities = Set<String>.from(p.amenityList);

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
    _addressController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _occupantsController.dispose();
    _uploads.close();
    super.dispose();
  }

  bool get _hasChanges {
    final p = widget.property;
    final currentName = (p.propertyName?.trim().isNotEmpty ?? false)
        ? p.propertyName!.trim()
        : p.title;

    if (_nameController.text.trim() != currentName) return true;
    if (_addressController.text.trim() != p.address) return true;
    if (_rentController.text.trim() != '${p.monthlyRent.round()}') return true;
    if (_depositController.text.trim() != '${p.depositAmount.round()}') {
      return true;
    }
    if (_occupantsController.text.trim() != '${p.maxOccupants.round()}') {
      return true;
    }
    if (_propertyType != (p.propertyType ?? 'Apartment')) return true;
    if ((_location.latitude - p.location.latitude).abs() > 0.0001 ||
        (_location.longitude - p.location.longitude).abs() > 0.0001) {
      return true;
    }
    if (_advanceMonths != p.advanceMonths.round()) return true;
    if (_allowedGender != p.allowedGender) return true;
    if (_smokingAllowed != p.smokingAllowed) return true;
    if (_petsAllowed != p.petsAllowed) return true;
    if (_curfewHours != p.curfewHours?.toInt()) return true;
    if (_isAvailable != (p.isAvailable && p.vacancyStatus != 'booked')) {
      return true;
    }

    final origAmenities = Set<String>.from(p.amenityList);
    if (_amenities.length != origAmenities.length ||
        !_amenities.containsAll(origAmenities)) {
      return true;
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
          'You have unsaved changes. Are you sure you want to discard them and return to Property Management?',
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
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Property name cannot be empty.');
      setState(() => _currentTab = 0);
      return;
    }

    final address = _addressController.text.trim();
    if (address.isEmpty) {
      _showError('Complete address is required.');
      setState(() => _currentTab = 0);
      return;
    }

    final rent = num.tryParse(_rentController.text.trim());
    if (rent == null || rent <= 0) {
      _showError('Monthly rent must be greater than ₱0.');
      setState(() => _currentTab = 2);
      return;
    }

    final occupants = num.tryParse(_occupantsController.text.trim());
    if (occupants == null || occupants < 1) {
      _showError('Maximum occupants must be at least 1.');
      setState(() => _currentTab = 2);
      return;
    }

    final deposit = num.tryParse(_depositController.text.trim()) ?? 0;

    if (_uploads.state.isUploading) {
      _showError('Photos are still uploading. Please wait.');
      setState(() => _currentTab = 1);
      return;
    }

    final images = _uploads.state.images;
    if (images.isEmpty) {
      _showError('At least one property photo is required.');
      setState(() => _currentTab = 1);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final photoUrls = [for (final img in images) img.url];
      final photoPublicIds = [for (final img in images) img.publicId];

      final updates = <String, dynamic>{
        'title': name,
        'propertyName': name,
        'propertyType': _propertyType,
        'address': address,
        'location': GeoPoint(_location.latitude, _location.longitude),
        'monthlyRent': rent,
        'depositAmount': deposit,
        'advanceMonths': _advanceMonths,
        'allowedGender': _allowedGender,
        'smokingAllowed': _smokingAllowed,
        'petsAllowed': _petsAllowed,
        'curfewHours': _curfewHours,
        'maxOccupants': occupants,
        'isAvailable': _isAvailable,
        'vacancyStatus': _isAvailable ? 'available' : 'booked',
        'hasWifi': _amenities.contains('WiFi'),
        'amenityList': _amenities.toList(),
        'amenityScore': _amenities.length,
        'photos': photoUrls,
        'photoPublicIds': photoPublicIds,
      };

      await widget.onSave(updates);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Property changes saved successfully.'),
          backgroundColor: Color(0xFF0F172A),
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
      _showError('A property must have at least one photo.');
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
              foregroundColor: Colors.white,
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
                'Add Property Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF0284C7)),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(bCtx).pop();
                  _uploads.pickAndUpload(nextSlot, PickSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF0284C7)),
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
    const activeColor = Color(0xFF0284C7);

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
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
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
            'Edit Property',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.appColors.textPrimary,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Tab Bar Navigation (Pills) ─────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildPillTab(0, 'Details'),
                    const SizedBox(width: 8),
                    _buildPillTab(1, 'Photos'),
                    const SizedBox(width: 8),
                    _buildPillTab(2, 'Rent'),
                    const SizedBox(width: 8),
                    _buildPillTab(3, 'Rules'),
                    const SizedBox(width: 8),
                    _buildPillTab(4, 'Amenities'),
                  ],
                ),
              ),
              const Divider(color: Color(0xFFF1F5F9), height: 1),

              // ── Tab Contents (IndexedStack preserves inputs) ───────
              Expanded(
                child: IndexedStack(
                  index: _currentTab,
                  children: [
                    _buildDetailsTab(),
                    _buildPhotosTab(),
                    _buildRentTab(),
                    _buildRulesTab(),
                    _buildAmenitiesTab(),
                  ],
                ),
              ),

              // ── Bottom Fixed Save Changes Bar ─────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: BlocBuilder<ImageUploadCubit, ImageUploadState>(
                  bloc: _uploads,
                  builder: (context, uploadState) {
                    final isBusy = _isSaving || uploadState.isUploading;
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activeColor,
                          foregroundColor: Colors.white,
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
                            fontSize: 16,
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

  Widget _buildPillTab(int index, String label) {
    final isSelected = _currentTab == index;
    const activeColor = Color(0xFF0284C7);

    return InkWell(
      onTap: () => setState(() => _currentTab = index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // ── Tab 0: Details (Property Information) ─────────────────────────
  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Property Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          LabelledField(
            label: 'Property name',
            child: AppTextField(
              controller: _nameController,
              hintText: 'e.g. La Boarding House',
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          LabelledField(
            label: 'Property type',
            child: ListingDropdown<String>(
              value: _propertyType,
              hint: 'Select property type',
              items: [
                for (final t in _propertyTypes)
                  DropdownMenuItem(value: t, child: Text(t)),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _propertyType = val);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          LabelledField(
            label: 'Full address',
            child: AppTextField(
              controller: _addressController,
              hintText: 'Complete street, barangay, and city',
              maxLines: 2,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          LabelledField(
            label: 'Pinned Map Location',
            child: ListingLocationPicker(
              addressController: _addressController,
              pin: _location,
              onPinChanged: (newLoc) {
                setState(() => _location = newLoc);
              },
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Tab 1: Photos (Property Photos) ───────────────────────────────
  Widget _buildPhotosTab() {
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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Property Photos',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Add, remove, or change photos.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 2-Column Photo Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                itemCount: slotsWithImages.length,
                itemBuilder: (context, idx) {
                  final (slotIndex, slot) = slotsWithImages[idx];
                  final isCover = slotIndex == 0;
                  final imageUrl = slot.image?.url;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Center(
                                  child: Icon(Icons.broken_image, color: Colors.grey),
                                ),
                              )
                            : const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                      ),
                      // Cover Badge
                      if (isCover)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Cover',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      // Delete X Button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: InkWell(
                          onTap: () => _confirmRemovePhoto(slotIndex),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              // + Add Photo Button
              InkWell(
                onTap: _addPhoto,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 52,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFBAE6FD),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_rounded, color: Color(0xFF0284C7), size: 20),
                      SizedBox(width: 6),
                      Text(
                        'Add Photo',
                        style: TextStyle(
                          color: Color(0xFF0284C7),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ── Tab 2: Rent & Capacity ─────────────────────────────────────────
  Widget _buildRentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rent & Capacity',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          LabelledField(
            label: 'Monthly rent (₱)',
            child: AppTextField(
              controller: _rentController,
              hintText: '4000',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          LabelledField(
            label: 'Maximum number of occupants',
            child: AppTextField(
              controller: _occupantsController,
              hintText: 'e.g. 2',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Available for rent',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Turn off if tenants cannot move in yet.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isAvailable,
                  activeThumbColor: const Color(0xFF0284C7),
                  onChanged: (val) => setState(() => _isAvailable = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Tab 3: House Rules ─────────────────────────────────────────────
  Widget _buildRulesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'House Rules',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          LabelledField(
            label: 'Security deposit (₱)',
            child: AppTextField(
              controller: _depositController,
              hintText: '2000',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          LabelledField(
            label: 'Advance rent (months)',
            child: ListingDropdown<int>(
              value: _advanceMonths,
              hint: 'Select advance rent',
              items: [
                for (final m in _advanceOptions)
                  DropdownMenuItem(
                    value: m,
                    child: Text(
                      m == 0 ? 'None' : '$m month${m > 1 ? 's' : ''}',
                    ),
                  ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _advanceMonths = val);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          LabelledField(
            label: 'Who can rent?',
            child: ListingDropdown<String>(
              value: _allowedGender,
              hint: 'Select eligibility',
              items: [
                for (final g in _genderOptions)
                  DropdownMenuItem(value: g, child: Text(g)),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _allowedGender = val);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Smoking allowed',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    Switch(
                      value: _smokingAllowed,
                      activeThumbColor: const Color(0xFF0284C7),
                      onChanged: (val) => setState(() => _smokingAllowed = val),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pets allowed',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    Switch(
                      value: _petsAllowed,
                      activeThumbColor: const Color(0xFF0284C7),
                      onChanged: (val) => setState(() => _petsAllowed = val),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          LabelledField(
            label: 'Curfew',
            child: ListingDropdown<int?>(
              value: _curfewHours,
              hint: 'Select curfew',
              items: [
                for (final c in _curfewOptions)
                  DropdownMenuItem<int?>(
                    value: c,
                    child: Text(
                      c == null
                          ? 'No curfew'
                          : '${c == 0 ? 12 : (c > 12 ? c - 12 : c)}:00 ${c >= 12 && c != 0 ? 'PM' : 'AM'}',
                    ),
                  ),
              ],
              onChanged: (val) => setState(() => _curfewHours = val),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Tab 4: Included Amenities ─────────────────────────────────────
  Widget _buildAmenitiesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Included Amenities',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select the amenities available at this property.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          for (final a in _amenitiesList) ...[
            InkWell(
              onTap: () {
                setState(() {
                  if (_amenities.contains(a)) {
                    _amenities.remove(a);
                  } else {
                    _amenities.add(a);
                  }
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _amenities.contains(a)
                            ? const Color(0xFF0284C7)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _amenities.contains(a)
                              ? const Color(0xFF0284C7)
                              : const Color(0xFFCBD5E1),
                          width: 1.5,
                        ),
                      ),
                      child: _amenities.contains(a)
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        a,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _amenities.contains(a)
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: _amenities.contains(a)
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
