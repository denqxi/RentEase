import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/mock_data.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_toggle.dart';

/// Edit an existing property listing — details, rules, pricing, amenities.
/// Writes back into the property map (MockData) on save; production swaps
/// this for a Firestore update guarded by the owner's security rules.
class EditPropertyScreen extends StatefulWidget {
  const EditPropertyScreen({required this.property, super.key});

  final Map<String, dynamic> property;

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _rentController;
  late final TextEditingController _depositController;
  late final TextEditingController _curfewController;

  late String _genderPolicy;
  late bool _smokingAllowed;
  late bool _petsAllowed;
  late int _advanceMonths;
  late Set<String> _selectedAmenities;

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    _nameController = TextEditingController(text: p['name'] as String);
    _addressController = TextEditingController(text: p['address'] as String);
    _rentController = TextEditingController(text: '${p['rent']}');
    _depositController = TextEditingController(text: '${p['deposit']}');
    _curfewController = TextEditingController(text: p['curfew'] as String? ?? '');
    _genderPolicy = p['allowedGender'] as String? ?? 'Any';
    _smokingAllowed = p['smokingAllowed'] as bool? ?? false;
    _petsAllowed = p['petsAllowed'] as bool? ?? false;
    _advanceMonths = p['advanceMonths'] as int? ?? 1;
    _selectedAmenities = Set<String>.from(
      (p['amenityList'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _curfewController.dispose();
    super.dispose();
  }

  void _save() {
    final p = widget.property;
    p['name'] = _nameController.text.trim();
    p['address'] = _addressController.text.trim();
    p['rent'] = int.tryParse(_rentController.text.trim()) ?? p['rent'];
    p['deposit'] =
        int.tryParse(_depositController.text.trim()) ?? p['deposit'];
    p['curfew'] = _curfewController.text.trim();
    p['allowedGender'] = _genderPolicy;
    p['smokingAllowed'] = _smokingAllowed;
    p['petsAllowed'] = _petsAllowed;
    p['advanceMonths'] = _advanceMonths;
    p['amenityList'] = _selectedAmenities.toList();
    p['amenities'] = _selectedAmenities.length;

    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${p['name']} updated.'),
        backgroundColor: context.appColors.ink,
      ),
    );
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
            _SectionLabel('PROPERTY DETAILS'),
            _FieldLabel('Property name'),
            _TextInput(controller: _nameController, hint: 'e.g. Sunshine Boarding House'),
            SizedBox(height: AppSpacing.md),
            _FieldLabel('Address'),
            _TextInput(controller: _addressController, hint: 'Street, barangay, Davao City'),
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
            _FieldLabel('Gender policy'),
            Row(
              children: [
                for (final policy in const [
                  'Female only',
                  'Male only',
                  'Any',
                ]) ...[
                  _ChoiceChip(
                    label: policy,
                    isSelected: _genderPolicy == policy,
                    onTap: () => setState(() => _genderPolicy = policy),
                  ),
                  SizedBox(width: 8),
                ],
              ],
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
            _FieldLabel('Curfew'),
            _TextInput(controller: _curfewController, hint: 'e.g. 10:00 PM or None'),
            SizedBox(height: AppSpacing.lg),

            _SectionLabel(
              'AMENITIES (${_selectedAmenities.length}/14)',
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final amenity in MockData.amenities)
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

            AppButton(label: 'Save changes', onPressed: _save),
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
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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
