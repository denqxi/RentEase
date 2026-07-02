import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/registration/widgets/registration_app_bar.dart';
import '../../../features/registration/widgets/step_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/map_zoom_controls.dart';
import '../model/property_draft.dart';
import 'property_rules_screen.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _mapController = MapController();
  LatLng? _pinnedLocation;
  final List<bool> _photoSlots = [false, false, false];

  bool get _canContinue =>
      _nameController.text.isNotEmpty && _addressController.text.isNotEmpty;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: RegistrationAppBar(
                onBack: () => Navigator.of(context).maybePop(),
                stepNumber: 1,
                stepCount: 4,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StepHeader(
                      title: 'Add your property.',
                      subtitle:
                          'Fill in the basic details of your boarding house.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LabelledField(
                              label: 'Property name',
                              child: AppTextField(
                                controller: _nameController,
                                hintText: 'e.g. Sunshine Boarding House',
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            LabelledField(
                              label: 'Address',
                              child: AppTextField(
                                controller: _addressController,
                                hintText: 'Street, Barangay, City',
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Location',
                              style: AppTextStyles.label(context)
                                  .copyWith(color: context.appColors.textSecondary),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Container(
                              height: 180,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(AppRadii.field),
                                border: Border.all(
                                  color: _pinnedLocation != null
                                      ? AppColors.accent
                                      : context.appColors.fieldBorder,
                                  width: _pinnedLocation != null ? 1.5 : 1,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                children: [
                                  FlutterMap(
                                    mapController: _mapController,
                                    options: MapOptions(
                                      initialCenter: const LatLng(
                                        MockData.tenantPoiLat,
                                        MockData.tenantPoiLng,
                                      ),
                                      initialZoom: 14,
                                      onTap: (_, latLng) => setState(
                                          () => _pinnedLocation = latLng),
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName:
                                            'com.rentease.app',
                                      ),
                                      if (_pinnedLocation != null)
                                        MarkerLayer(
                                          markers: [
                                            Marker(
                                              point: _pinnedLocation!,
                                              width: 40,
                                              height: 40,
                                              alignment: Alignment.topCenter,
                                              child: Icon(Icons.location_pin,
                                                  color: AppColors.accent,
                                                  size: 40),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  MapZoomControls(controller: _mapController),
                                  Positioned(
                                    left: AppSpacing.sm,
                                    bottom: AppSpacing.sm,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: context.appColors.surface,
                                        borderRadius: BorderRadius.circular(
                                            AppRadii.field),
                                        border: Border.all(
                                            color:
                                                context.appColors.fieldBorder),
                                      ),
                                      child: Text(
                                        _pinnedLocation == null
                                            ? 'Tap to pin your property'
                                            : 'Pinned '
                                                '${_pinnedLocation!.latitude.toStringAsFixed(4)}, '
                                                '${_pinnedLocation!.longitude.toStringAsFixed(4)}',
                                        style: AppTextStyles.caption(context)
                                            .copyWith(
                                          color: _pinnedLocation != null
                                              ? AppColors.accent
                                              : context
                                                  .appColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Photos',
                              style: AppTextStyles.label(context)
                                  .copyWith(color: context.appColors.textSecondary),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: List.generate(3, (i) {
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                        right: i < 2 ? AppSpacing.sm : 0),
                                    child: GestureDetector(
                                      onTap: () => setState(
                                          () => _photoSlots[i] = !_photoSlots[i]),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: _photoSlots[i]
                                              ? AppColors.accentSoft
                                              : context.appColors.fieldFill,
                                          borderRadius: BorderRadius.circular(
                                              AppRadii.field),
                                          border: Border.all(
                                            color: _photoSlots[i]
                                                ? AppColors.accent
                                                : context.appColors.fieldBorder,
                                            width: _photoSlots[i] ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            _photoSlots[i]
                                                ? Icons.check_rounded
                                                : Icons.add_a_photo_outlined,
                                            color: _photoSlots[i]
                                                ? AppColors.accent
                                                : context.appColors.hint,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppPrimaryButton(
                      label: 'Continue',
                      onPressed: _canContinue
                          ? () {
                              NewPropertyDraft.name = _nameController.text.trim();
                              NewPropertyDraft.address =
                                  _addressController.text.trim();
                              NewPropertyDraft.latitude =
                                  _pinnedLocation?.latitude;
                              NewPropertyDraft.longitude =
                                  _pinnedLocation?.longitude;
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const PropertyRulesScreen(),
                                ),
                              );
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
