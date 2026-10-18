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

import '../../owner_onboarding/widgets/listing_form_widgets.dart';
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
  late final TextEditingController _roomNameController;
  late final TextEditingController _addressController;
  late final TextEditingController _rentController;
  late final TextEditingController _depositController;
  late final TextEditingController _occupantsController;

  late String _vacancyStatus; // 'available', 'pending', 'booked'
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
    _roomNameController = TextEditingController(text: p.roomName ?? '');
    _addressController = TextEditingController(text: p.address);
    _rentController = TextEditingController(text: '${p.monthlyRent.round()}');
    _depositController = TextEditingController(
      text: '${p.depositAmount.round()}',
    );
    _occupantsController = TextEditingController(
      text: '${p.maxOccupants.round()}',
    );
    _curfewHours = p.curfewHours?.toInt();
    _vacancyStatus = p.vacancyStatus.isNotEmpty ? p.vacancyStatus : (p.isAvailable ? 'available' : 'booked');
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
    _roomNameController.dispose();
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
    final roomName = _roomNameController.text.trim();
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
      final payload = <String, dynamic>{
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
        'vacancyStatus': _vacancyStatus,
        'isAvailable': _vacancyStatus == 'available',
      };
      if (widget.property.isRoom && roomName.isNotEmpty) {
        payload['roomName'] = roomName;
      }
      await widget.onSave(payload);
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
    final p = widget.property;
    final isRoom = p.isRoom;
    final parentName = (p.propertyName?.trim().isNotEmpty ?? false)
        ? p.propertyName!.trim()
        : p.title;

    return Scaffold(
      backgroundColor: context.appColors.surface,
      appBar: AppBar(
        backgroundColor: context.appColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: context.appColors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isRoom ? 'Edit Room Listing' : 'Edit Property Listing',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: context.appColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.property.adminUnlisted) ...[
              const AdminUnlistedNotice(),
              const SizedBox(height: AppSpacing.md),
            ],

            // ── Card 1: Header / Basic Info ─────────────────────────────
            _CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFDBEAFE)),
                        ),
                        child: Text(
                          (p.propertyType ?? 'BOARDING HOUSE').toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          parentName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _FieldLabel(isRoom ? 'Room / Unit Name' : 'Property Title'),
                  _TextInput(
                    controller: isRoom ? _roomNameController : _nameController,
                    hint: isRoom ? 'e.g. Room 101' : 'e.g. Sunshine Boarding House',
                    maxLength: 120,
                  ),
                  const SizedBox(height: 12),
                  _FieldLabel('Address'),
                  _TextInput(
                    controller: _addressController,
                    hint: 'Street, barangay, Davao City',
                    maxLength: 300,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Card 2: Rental Status ────────────────────────────────────
            _CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardHeaderTitle(
                    title: 'Rental Status',
                    subtitle: 'Set whether this unit is currently accepting tenants',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatusSelectButton(
                        label: 'Available',
                        color: const Color(0xFF10B981),
                        isSelected: _vacancyStatus == 'available',
                        onTap: () => setState(() => _vacancyStatus = 'available'),
                      ),
                      const SizedBox(width: 8),
                      _StatusSelectButton(
                        label: 'Pending',
                        color: const Color(0xFFF59E0B),
                        isSelected: _vacancyStatus == 'pending',
                        onTap: () => setState(() => _vacancyStatus = 'pending'),
                      ),
                      const SizedBox(width: 8),
                      _StatusSelectButton(
                        label: 'Booked',
                        color: const Color(0xFF64748B),
                        isSelected: _vacancyStatus == 'booked',
                        onTap: () => setState(() => _vacancyStatus = 'booked'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Card 3: Rates & Deposit ──────────────────────────────────
            _CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardHeaderTitle(
                    title: 'Pricing & Deposit',
                    subtitle: 'Monthly rent rate and upfront security requirements',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel('Monthly Rent (₱)'),
                            _TextInput(
                              controller: _rentController,
                              hint: '3500',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel('Deposit (₱)'),
                            _TextInput(
                              controller: _depositController,
                              hint: '3500',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _FieldLabel('Advance Months'),
                  Row(
                    children: [
                      for (final months in const [1, 2, 3]) ...[
                        _ChoiceChip(
                          label: '$months Month${months > 1 ? 's' : ''}',
                          isSelected: _advanceMonths == months,
                          onTap: () => setState(() => _advanceMonths = months),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Card 4: Rules & Capacity ─────────────────────────────────
            _CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardHeaderTitle(
                    title: 'Capacity & House Rules',
                    subtitle: 'Set tenant restrictions and living guidelines',
                  ),
                  const SizedBox(height: 12),
                  _FieldLabel('Allowed Gender Policy'),
                  PreferenceDropdown(
                    label: '',
                    value: _genderPolicy,
                    hint: 'Select gender policy',
                    items: _genderPolicies,
                    onChanged: (v) => setState(() => _genderPolicy = v),
                  ),
                  const SizedBox(height: 12),
                  _FieldLabel('Max Occupants (per unit)'),
                  _TextInput(
                    controller: _occupantsController,
                    hint: '1',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _FieldLabel('Curfew'),
                  GestureDetector(
                    onTap: _pickCurfew,
                    child: AbsorbPointer(
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: context.appColors.fieldFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.appColors.fieldBorder),
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
                  const SizedBox(height: 12),
                  _ToggleRow(
                    label: 'Smoking Allowed',
                    value: _smokingAllowed,
                    onChanged: (v) => setState(() => _smokingAllowed = v),
                  ),
                  _ToggleRow(
                    label: 'Pets Allowed',
                    value: _petsAllowed,
                    onChanged: (v) => setState(() => _petsAllowed = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Card 5: Amenities ────────────────────────────────────────
            _CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardHeaderTitle(
                    title: 'Amenities (${_selectedAmenities.length}/14)',
                    subtitle: 'Features available to occupants of this listing',
                  ),
                  const SizedBox(height: 8),
                  for (final (group, items) in kAmenityGroups) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      group,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final amenity in items)
                          AmenityChip(
                            label: amenity,
                            selected: _selectedAmenities.contains(amenity),
                            onTap: () => setState(() {
                              if (!_selectedAmenities.remove(amenity)) {
                                _selectedAmenities.add(amenity);
                              }
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Card 6: Photos ───────────────────────────────────────────
            _CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardHeaderTitle(
                    title: 'Photos',
                    subtitle: 'Add clear images of the room/property interior & exterior',
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 6),
                  Text(
                    'Add 1 to ${CloudinaryConfig.maxPropertyPhotos} photos. The first is the cover.',
                    style: AppTextStyles.caption(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Save Button ──────────────────────────────────────────────
            BlocBuilder<ImageUploadCubit, ImageUploadState>(
              bloc: _uploads,
              builder: (context, state) => AppButton(
                label: _saving
                    ? 'Saving changes...'
                    : state.isUploading
                        ? 'Uploading photos...'
                        : 'Save Changes',
                onPressed: _saving || !state.isReady ? null : _save,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  const _CardContainer({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardHeaderTitle extends StatelessWidget {
  const _CardHeaderTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}

class _StatusSelectButton extends StatelessWidget {
  const _StatusSelectButton({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? color : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? color : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
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
