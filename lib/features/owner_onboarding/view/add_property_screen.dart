import '../../../core/constants/app_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/registration/widgets/registration_app_bar.dart';
import '../../../features/registration/widgets/step_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/map_zoom_controls.dart';
import '../../../core/constants/cloudinary_config.dart';
import '../../uploads/data/repositories/cloudinary_image_upload_repository.dart';
import '../../uploads/domain/entities/uploaded_image.dart';
import '../../uploads/domain/repositories/image_upload_repository.dart';
import '../../uploads/presentation/cubit/image_upload_cubit.dart';
import '../../uploads/presentation/widgets/image_upload_slot.dart';
import '../cubit/owner_onboarding_cubit.dart';
import 'property_rules_screen.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({this.repository, super.key});

  /// Override for tests; defaults to the Cloudinary implementation.
  final ImageUploadRepository? repository;

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _mapController = MapController();
  LatLng? _pinnedLocation;
  late final ImageUploadCubit _uploads = ImageUploadCubit(
    repository: widget.repository ?? CloudinaryImageUploadRepository(),
    kind: ImageKind.propertyPhoto,
    slotCount: CloudinaryConfig.maxPropertyPhotos,
    minRequired: 1,
  );

  // The pin is required: tenants' LocationMatch and distance ranking are
  // computed from these coordinates.
  bool get _canContinue =>
      _uploads.state.isReady &&
      _nameController.text.trim().isNotEmpty &&
      _addressController.text.trim().isNotEmpty &&
      _pinnedLocation != null;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _mapController.dispose();
    _uploads.close();
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
                stepCount: 3,
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
                                // Matches the 120-char cap in firestore.rules.
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(120),
                                ],
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            LabelledField(
                              label: 'Address',
                              child: AppTextField(
                                controller: _addressController,
                                hintText: 'Street, Barangay, City',
                                // Matches the 300-char cap in firestore.rules.
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(300),
                                ],
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Location',
                              style: AppTextStyles.label(context).copyWith(
                                color: context.appColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Container(
                              height: 180,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppRadii.field,
                                ),
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
                                        AppOptions.defaultMapLat,
                                        AppOptions.defaultMapLng,
                                      ),
                                      initialZoom: 14,
                                      onTap: (_, latLng) => setState(
                                        () => _pinnedLocation = latLng,
                                      ),
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
                                              child: Icon(
                                                Icons.location_pin,
                                                color: AppColors.accent,
                                                size: 40,
                                              ),
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
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.appColors.surface,
                                        borderRadius: BorderRadius.circular(
                                          AppRadii.field,
                                        ),
                                        border: Border.all(
                                          color: context.appColors.fieldBorder,
                                        ),
                                      ),
                                      child: Text(
                                        _pinnedLocation == null
                                            ? 'Tap to pin your property (required)'
                                            : 'Pinned '
                                                  '${_pinnedLocation!.latitude.toStringAsFixed(4)}, '
                                                  '${_pinnedLocation!.longitude.toStringAsFixed(4)}',
                                        style: AppTextStyles.caption(context)
                                            .copyWith(
                                              color: _pinnedLocation != null
                                                  ? AppColors.accent
                                                  : context
                                                        .appColors
                                                        .textSecondary,
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
                              style: AppTextStyles.label(context).copyWith(
                                color: context.appColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
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
                                      onPick: (src) =>
                                          _uploads.pickAndUpload(i, src),
                                      onRetry: () => _uploads.retry(i),
                                      onRemove: () => _uploads.remove(i),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add 1 to ${CloudinaryConfig.maxPropertyPhotos} photos. The first is the cover.',
                              style: AppTextStyles.caption(context),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    BlocBuilder<ImageUploadCubit, ImageUploadState>(
                      bloc: _uploads,
                      builder: (context, _) => AppPrimaryButton(
                        label: 'Continue',
                        onPressed: _canContinue
                            ? () {
                                context.read<OwnerOnboardingCubit>().saveBasics(
                                  title: _nameController.text.trim(),
                                  address: _addressController.text.trim(),
                                  latitude: _pinnedLocation!.latitude,
                                  longitude: _pinnedLocation!.longitude,
                                  photos: _uploads.state.images,
                                );
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const PropertyRulesScreen(),
                                  ),
                                );
                              }
                            : null,
                      ),
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
