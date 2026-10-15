import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/firestore/models/models.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import 'listing_form_widgets.dart';
import 'listing_location_picker.dart';

/// Property types offered for an entire place / a new building.
const List<String> kPropertyTypes = ['Boarding House'];

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
    this.isNew = false,
  });

  final String id;
  final String name;
  final String? type;
  final String address;
  final LatLng location;

  /// True until its first room has been posted.
  final bool isNew;

  /// Groups the owner's room listings into buildings. Only rooms carrying a
  /// `parentPropertyId` are grouped; the earliest listing's data is used.
  static List<SavedBuilding> fromListings(List<PropertyDoc> listings) {
    final byId = <String, SavedBuilding>{};
    for (final p in listings) {
      final id = p.parentPropertyId;
      if (!p.isRoom || id == null || id.isEmpty) continue;
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
        ),
      );
    }
    final list = byId.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }
}

/// Bottom sheet for "+ Add New Property": name, type, address and map pin.
/// Returns the new [SavedBuilding] (not yet in Firestore) or null.
Future<SavedBuilding?> showNewPropertySheet(BuildContext context) {
  return showModalBottomSheet<SavedBuilding>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.appColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _NewPropertySheet(),
  );
}

class _NewPropertySheet extends StatefulWidget {
  const _NewPropertySheet();

  @override
  State<_NewPropertySheet> createState() => _NewPropertySheetState();
}

class _NewPropertySheetState extends State<_NewPropertySheet> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  String? _type;
  LatLng? _pin;
  bool _resolving = false;

  bool get _canSave =>
      !_resolving &&
      _nameController.text.trim().isNotEmpty &&
      _type != null &&
      _addressController.text.trim().isNotEmpty &&
      _pin != null;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(
      SavedBuilding(
        // Client-generated id; becomes the parentPropertyId of its rooms.
        id: 'b${DateTime.now().microsecondsSinceEpoch}',
        name: _nameController.text.trim(),
        type: _type,
        address: _addressController.text.trim(),
        location: _pin!,
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
              child: ListingDropdown<String>(
                value: _type,
                hint: 'Select type',
                items: [
                  for (final t in kPropertyTypes)
                    DropdownMenuItem(value: t, child: Text(t)),
                ],
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
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: 'Save property',
              onPressed: _canSave ? _save : null,
            ),
          ],
        ),
      ),
    );
  }
}
