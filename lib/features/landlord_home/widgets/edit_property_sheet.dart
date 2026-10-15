import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../owner_onboarding/widgets/listing_form_widgets.dart';
import '../../owner_onboarding/widgets/listing_location_picker.dart';

const List<String> kBuildingTypes = [
  'Boarding House',
  'House',
  'Apartment',
  'Condominium',
  'Studio Unit',
];

/// Bottom sheet to edit building/property metadata (Name, Type, Address, Map Pin).
Future<void> showEditPropertySheet({
  required BuildContext context,
  required String initialName,
  required String? initialType,
  required String initialAddress,
  required LatLng? initialLocation,
  required Future<void> Function({
    required String name,
    required String type,
    required String address,
    required LatLng location,
  }) onSave,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.appColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _EditPropertySheet(
      initialName: initialName,
      initialType: initialType,
      initialAddress: initialAddress,
      initialLocation: initialLocation,
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
    required this.onSave,
  });

  final String initialName;
  final String? initialType;
  final String initialAddress;
  final LatLng? initialLocation;
  final Future<void> Function({
    required String name,
    required String type,
    required String address,
    required LatLng location,
  }) onSave;

  @override
  State<_EditPropertySheet> createState() => _EditPropertySheetState();
}

class _EditPropertySheetState extends State<_EditPropertySheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late String? _type;
  late LatLng? _pin;
  bool _saving = false;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _addressController = TextEditingController(text: widget.initialAddress);
    _type = widget.initialType != null &&
            kBuildingTypes.contains(widget.initialType)
        ? widget.initialType
        : kBuildingTypes.first;
    _pin = widget.initialLocation;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      !_saving &&
      !_resolving &&
      _nameController.text.trim().isNotEmpty &&
      _type != null &&
      _addressController.text.trim().isNotEmpty &&
      _pin != null;

  Future<void> _handleSave() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(
        name: _nameController.text.trim(),
        type: _type!,
        address: _addressController.text.trim(),
        location: _pin!,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update property: $e'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Edit Property',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Update building name, type, address, and pinned location.',
              style: AppTextStyles.caption(context),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Property Name',
              style: AppTextStyles.label(context),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppTextField(
              controller: _nameController,
              hintText: 'e.g. GL Boardinghouse',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Property Type',
              style: AppTextStyles.label(context),
            ),
            const SizedBox(height: AppSpacing.xs),
            ListingDropdown<String>(
              value: _type,
              hint: 'Select property type',
              items: [
                for (final t in kBuildingTypes)
                  DropdownMenuItem(
                    value: t,
                    child: Text(
                      t,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        color: context.appColors.textPrimary,
                      ),
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _type = v),
            ),
            const SizedBox(height: AppSpacing.md),
            ListingLocationPicker(
              addressController: _addressController,
              pin: _pin,
              onPinChanged: (p) => setState(() => _pin = p),
              onChanged: (resolving) => setState(() => _resolving = resolving),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: AppPrimaryButton(
                label: _saving ? 'Saving...' : 'Save Changes',
                onPressed: _canSave ? _handleSave : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
