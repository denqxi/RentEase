import '../../../core/constants/app_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/services/geocoding_service.dart';
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
  final _geocodingService = const GeocodingService();
  LatLng? _pinnedLocation;
  bool _isResolvingAddress = false;
  int _geocodeRequestId = 0;
  late final ImageUploadCubit _uploads = ImageUploadCubit(
    repository: widget.repository ?? CloudinaryImageUploadRepository(),
    kind: ImageKind.propertyPhoto,
    slotCount: CloudinaryConfig.maxPropertyPhotos,
    minRequired: 1,
  );

  // The pin is required: tenants' LocationMatch and distance ranking are
  // computed from these coordinates.
  bool get _canContinue =>
      !_isResolvingAddress &&
      _uploads.state.isReady &&
      _nameController.text.trim().isNotEmpty &&
      _addressController.text.trim().isNotEmpty &&
      _pinnedLocation != null;

  Future<void> _onMapTapped(LatLng latLng) async {
    final requestId = ++_geocodeRequestId;
    setState(() {
      _pinnedLocation = latLng;
      _isResolvingAddress = true;
    });

    try {
      final address = await _geocodingService.reverseGeocode(
        latLng.latitude,
        latLng.longitude,
      );

      if (requestId != _geocodeRequestId || !mounted) return;

      setState(() {
        _addressController.text = address;
        _isResolvingAddress = false;
      });
    } catch (_) {
      if (requestId != _geocodeRequestId || !mounted) return;
      setState(() {
        _isResolvingAddress = false;
      });
    }
  }

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
                                suffixIcon: _isResolvingAddress
                                    ? const Padding(
                                        padding: EdgeInsets.all(14),
                                        child: SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : null,
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
                                      onTap: (_, latLng) =>
                                          _onMapTapped(latLng),
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
                                              child: const Icon(
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
                                  if (_pinnedLocation == null)
                                    Positioned(
                                      left: 8,
                                      bottom: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.95),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: context.appColors.fieldBorder,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.06),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.lightbulb_rounded,
                                              size: 14,
                                              color: Color(0xFFEAB308),
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              'Tap to pin your property (required)',
                                              style: TextStyle(
                                                fontFamily: 'DM Sans',
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.normal,
                                                color: Color(0xFF475569),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (_isResolvingAddress) ...[
                              const SizedBox(height: 6),
                              const Row(
                                children: [
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Fetching location...',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (_pinnedLocation != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Pinned: ${_addressController.text.isNotEmpty ? _addressController.text : '${_pinnedLocation!.latitude.toStringAsFixed(4)}, ${_pinnedLocation!.longitude.toStringAsFixed(4)}'}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
