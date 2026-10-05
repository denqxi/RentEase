import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_options.dart';
import '../../../core/constants/cloudinary_config.dart';
import '../../../shared/widgets/admin_unlisted_notice.dart';
import '../../uploads/data/repositories/cloudinary_image_upload_repository.dart';
import '../../uploads/domain/entities/uploaded_image.dart';
import '../../uploads/domain/repositories/image_upload_repository.dart';
import '../../uploads/presentation/cubit/image_upload_cubit.dart';
import '../../uploads/presentation/widgets/image_upload_slot.dart';
import '../../../core/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../registration/widgets/preference_dropdown.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/firestore/models/models.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_toggle.dart';

/// Edit an existing listing — details, pricing, house rules, amenities.
/// [onSave] persists the changed fields (Firestore, via the caller's cubit);
/// tenants see the changes on their next matching pass, since their device
/// re-scores the listing then.
class EditPropertyScreen extends StatefulWidget {
  const EditPropertyScreen({
    required this.property,
    required this.onSave,
    this.uploadRepository,
    super.key,
  });

  /// Override for tests; defaults to the Cloudinary implementation.
  final ImageUploadRepository? uploadRepository;

  final PropertyDoc property;
  final Future<void> Function(Map<String, dynamic> fields) onSave;

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  // Same values as onboarding's property rules step, which FilteringService
  // matches against.
  static const _genderPolicies = ['Female only', 'Male only', 'Mixed / Any'];

  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _rentController;
  late final TextEditingController _depositController;
  late final TextEditingController _occupantsController;

  late String _genderPolicy;
  late bool _smokingAllowed;
  late bool _petsAllowed;
  late int _advanceMonths;
  int? _curfewHours;
  late Set<String> _selectedAmenities;
  bool _saving = false;
  late final ImageUploadCubit _uploads;

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    // photos and photoPublicIds are parallel arrays; pad a missing id so the
    // pair stays aligned.
    _uploads = ImageUploadCubit(
      repository: widget.uploadRepository ?? CloudinaryImageUploadRepository(),
      kind: ImageKind.propertyPhoto,
      slotCount: CloudinaryConfig.maxPropertyPhotos,
      minRequired: 1,
      initialImages: [
        for (var i = 0;
            i < p.photos.length && i < CloudinaryConfig.maxPropertyPhotos;
            i++)
          UploadedImage(
            url: p.photos[i],
            publicId: i < p.photoPublicIds.length ? p.photoPublicIds[i] : '',
          ),
      ],
    );
    _nameController = TextEditingController(text: p.title);
    _addressController = TextEditingController(text: p.address);
    _rentController = TextEditingController(text: '${p.monthlyRent.round()}');
    _depositController = TextEditingController(
      text: '${p.depositAmount.round()}',
    );
    _occupantsController = TextEditingController(
      text: '${p.maxOccupants.round()}',
    );
    _curfewHours = p.curfewHours?.toInt();
    _genderPolicy = _genderPolicies.contains(p.allowedGender)
        ? p.allowedGender
        : 'Mixed / Any';
    _smokingAllowed = p.smokingAllowed;
    _petsAllowed = p.petsAllowed;
    _advanceMonths = p.advanceMonths.toInt().clamp(1, 3);
    _selectedAmenities = Set<String>.from(p.amenityList);
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

  Future<void> _pickCurfew() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _curfewHours ?? 22, minute: 0),
    );
    if (picked != null && mounted) {
      setState(() => _curfewHours = picked.hour);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.destructive),
    );
  }

  Future<void> _save() async {
    final title = _nameController.text.trim();
    final address = _addressController.text.trim();
    final rent = int.tryParse(_rentController.text.trim()) ?? 0;
    final deposit = int.tryParse(_depositController.text.trim()) ?? 0;
    final occupants = int.tryParse(_occupantsController.text.trim()) ?? 0;
    if (title.isEmpty || address.isEmpty) {
      _showError('Enter the property name and address.');
      return;
    }
    if (rent <= 0) {
      _showError('Enter a monthly rent above ₱0.');
      return;
    }
    if (occupants < 1) {
      _showError('Max occupants must be at least 1.');
      return;
    }

    // Checklist order (not tap order); amenityScore must equal its length —
    // firestore.rules rejects the write otherwise.
    final amenities = AppOptions.amenities
        .where(_selectedAmenities.contains)
        .toList();

    if (!_uploads.state.isReady) {
      _showError('Add at least 1 photo and wait for uploads to finish.');
      return;
    }
    // Removed photos just drop from the doc; unsigned Cloudinary presets
    // can't delete from the client, so the old assets are orphaned.
    final images = _uploads.state.images;

    setState(() => _saving = true);
    try {
      await widget.onSave({
        'photos': [for (final i in images) i.url],
        'photoPublicIds': [for (final i in images) i.publicId],
        'title': title,
        'address': address,
        'monthlyRent': rent,
        'depositAmount': deposit,
        'advanceMonths': _advanceMonths,
        'allowedGender': _genderPolicy,
        'smokingAllowed': _smokingAllowed,
        'petsAllowed': _petsAllowed,
        'maxOccupants': occupants,
        'curfewHours': _curfewHours,
        'amenityList': amenities,
        'amenityScore': amenities.length,
        'hasWifi': amenities.contains('WiFi'),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title updated.'),
          backgroundColor: context.appColors.ink,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError(
        e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Could not save the listing. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      appBar: AppBar(
        backgroundColor: context.appColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: context.appColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit property',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.appColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.property.adminUnlisted) ...[
              const AdminUnlistedNotice(),
              SizedBox(height: AppSpacing.lg),
            ],
            _SectionLabel('PHOTOS'),
            BlocBuilder<ImageUploadCubit, ImageUploadState>(
              bloc: _uploads,
              builder: (context, state) => Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: List.generate(
                  state.slots.length,
                  (i) => SizedBox(
                    width: 96,
                    child: ImageUploadSlot(
                      slot: state.slots[i],
                      emptyLabel: i == 0 ? 'Cover' : null,
                      onPick: (src) => _uploads.pickAndUpload(i, src),
                      onRetry: () => _uploads.retry(i),
                      onRemove: () => _uploads.remove(i),
                      onReplace: (src) => _uploads.pickAndUpload(i, src),
                      onMoveEarlier: i == 0 ? null : () => _uploads.moveEarlier(i),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Add 1 to ${CloudinaryConfig.maxPropertyPhotos} photos. The first is the cover.',
              style: AppTextStyles.caption(context),
            ),
            SizedBox(height: AppSpacing.lg),

            _SectionLabel('PROPERTY DETAILS'),
            _FieldLabel('Property name'),
            _TextInput(controller: _nameController, hint: 'e.g. Sunshine Boarding House', maxLength: 120),
            SizedBox(height: AppSpacing.md),
            _FieldLabel('Address'),
            _TextInput(controller: _addressController, hint: 'Street, barangay, Davao City', maxLength: 300),
            SizedBox(height: AppSpacing.lg),

            _SectionLabel('PRICING'),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Monthly rent (₱)'),
                      _TextInput(
                        controller: _rentController,
                        hint: '3800',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Deposit (₱)'),
                      _TextInput(
                        controller: _depositController,
                        hint: '3800',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            _FieldLabel('Advance months'),
            Row(
              children: [
                for (final months in const [1, 2, 3]) ...[
                  _ChoiceChip(
                    label: '$months mo',
                    isSelected: _advanceMonths == months,
                    onTap: () => setState(() => _advanceMonths = months),
                  ),
                  SizedBox(width: 8),
                ],
              ],
            ),
            SizedBox(height: AppSpacing.lg),

            _SectionLabel('HOUSE RULES'),
            PreferenceDropdown(
              label: 'Gender policy',
              value: _genderPolicy,
              hint: 'Select gender policy',
              items: _genderPolicies,
              onChanged: (v) => setState(() => _genderPolicy = v),
            ),
            SizedBox(height: AppSpacing.md),
            _ToggleRow(
              label: 'Smoking allowed',
              value: _smokingAllowed,
              onChanged: (v) => setState(() => _smokingAllowed = v),
            ),
            _ToggleRow(
              label: 'Pets allowed',
              value: _petsAllowed,
              onChanged: (v) => setState(() => _petsAllowed = v),
            ),
            SizedBox(height: AppSpacing.md),
            // Layer 1 OccupancyMatch: a tenant's group size must fit.
            _FieldLabel('Max occupants per room'),
            _TextInput(
              controller: _occupantsController,
              hint: '1',
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: AppSpacing.md),
            _FieldLabel('Curfew'),
            GestureDetector(
              onTap: _pickCurfew,
              child: AbsorbPointer(
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: context.appColors.fieldFill,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: context.appColors.fieldBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatCurfew(_curfewHours),
                          style: AppTextStyles.field(context),
                        ),
                      ),
                      Icon(
                        Icons.access_time_rounded,
                        size: 18,
                        color: context.appColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            _SectionLabel(
              'AMENITIES (${_selectedAmenities.length}/14)',
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final amenity in AppOptions.amenities)
                  _ChoiceChip(
                    label: amenity,
                    isSelected: _selectedAmenities.contains(amenity),
                    onTap: () => setState(() {
                      if (!_selectedAmenities.remove(amenity)) {
                        _selectedAmenities.add(amenity);
                      }
                    }),
                  ),
              ],
            ),
            SizedBox(height: AppSpacing.xl),

            BlocBuilder<ImageUploadCubit, ImageUploadState>(
              bloc: _uploads,
              builder: (context, state) => AppButton(
                label: _saving
                    ? 'Saving...'
                    : state.isUploading
                    ? 'Uploading photos...'
                    : 'Save changes',
                onPressed: _saving || !state.isReady ? null : _save,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: context.appColors.textSecondary,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.appColors.textSecondary,
        ),
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.maxLength,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  /// Hard cap on typed characters (mirrors the length caps in firestore.rules).
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: [
        if (keyboardType == TextInputType.number)
          FilteringTextInputFormatter.digitsOnly,
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],
      style: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 14,
        color: context.appColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 14,
          color: context.appColors.hint,
        ),
        filled: true,
        fillColor: context.appColors.fieldFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: BorderSide(color: context.appColors.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : context.appColors.fieldFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent : context.appColors.fieldBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.onInk : context.appColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.appColors.textPrimary,
              ),
            ),
          ),
          AppToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
