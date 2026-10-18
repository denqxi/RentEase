import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_options.dart';
import '../../../core/constants/cloudinary_config.dart';
import '../../../core/firestore/models/models.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/presentation/current_uid.dart';
import '../../registration/widgets/registration_app_bar.dart';
import '../../registration/widgets/step_header.dart';
import '../../uploads/data/repositories/cloudinary_image_upload_repository.dart';
import '../../uploads/domain/entities/uploaded_image.dart';
import '../../uploads/domain/repositories/image_upload_repository.dart';
import '../../uploads/presentation/cubit/image_upload_cubit.dart';
import '../../uploads/presentation/widgets/image_upload_slot.dart';
import '../cubit/owner_onboarding_cubit.dart';
import '../widgets/listing_form_widgets.dart';
import '../widgets/listing_location_picker.dart';
import '../widgets/new_property_sheet.dart';

/// 6-step "Create listing" wizard (Rental type → Details → House rules →
/// Rent & occupants → Amenities → Review). Replaces the old 3-screen
/// add-property flow; it reuses the same map picker, Cloudinary uploader and
/// `OwnerOnboardingCubit.submitProperty` publishing logic.
class CreateListingWizardScreen extends StatefulWidget {
  const CreateListingWizardScreen({
    this.addRoomTo,
    this.repository,
    super.key,
  });

  /// When set (from "+ Add Room"), the wizard opens as **A Room** with this
  /// listing's property preselected. Any listing of the building works.
  final PropertyDoc? addRoomTo;

  /// Override for tests; defaults to the Cloudinary implementation.
  final ImageUploadRepository? repository;

  @override
  State<CreateListingWizardScreen> createState() =>
      _CreateListingWizardScreenState();
}

class _CreateListingWizardScreenState extends State<CreateListingWizardScreen> {
  static const int _stepCount = 6;
  static const String _addNewValue = '__add_new__';

  /// Curfew choices; null = no curfew (stored by omitting `curfewHours`).
  static const List<int?> _curfewOptions = [null, 20, 21, 22, 23, 0];

  int _step = 0;
  bool _posting = false;

  // Step 1
  String? _rentalType; // 'entire_place' | 'room'

  // Step 2 — entire place
  final _placeNameController = TextEditingController();
  final _placeAddressController = TextEditingController();
  String? _placeType;
  LatLng? _placePin;
  bool _resolvingAddress = false;

  // Step 2 — room
  List<SavedBuilding> _savedBuildings = const [];
  final List<SavedBuilding> _newBuildings = [];
  SavedBuilding? _building;
  bool _loadingBuildings = false;
  final _roomNameController = TextEditingController();
  List<PropertyDoc> _ownerListings = const [];

  // Step 3
  final _depositController = TextEditingController();
  final _advanceController = TextEditingController(text: '1');
  String _allowedGender = 'Mixed / Any';
  bool _smokingAllowed = false;
  bool _petsAllowed = false;
  int? _curfewHours = 22;

  // Step 4
  final _rentController = TextEditingController();
  final _occupantsController = TextEditingController(text: '1');
  bool _isAvailable = true;

  // Step 5
  final Set<String> _amenities = {};

  late final ImageUploadCubit _uploads = ImageUploadCubit(
    repository: widget.repository ?? CloudinaryImageUploadRepository(),
    kind: ImageKind.propertyPhoto,
    slotCount: CloudinaryConfig.maxPropertyPhotos,
    minRequired: 1,
  );

  bool get _isRoom => _rentalType == 'room';

  @override
  void initState() {
    super.initState();
    final preset = widget.addRoomTo;
    if (preset != null) {
      _rentalType = 'room';
      _step = 1;
      final id = preset.parentPropertyId;
      if (id != null && id.isNotEmpty) {
        final existingCover = preset.effectiveBuildingCoverPhoto;
        _building = SavedBuilding(
          id: id,
          name: preset.propertyName ?? preset.title,
          type: preset.propertyType,
          address: preset.address,
          location: LatLng(preset.location.latitude, preset.location.longitude),
          coverPhoto: existingCover != null
              ? UploadedImage(
                  url: existingCover,
                  publicId: preset.propertyCoverPublicId ??
                      (preset.photoPublicIds.isNotEmpty
                          ? preset.photoPublicIds.first
                          : ''),
                )
              : null,
        );
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBuildings());
  }

  @override
  void dispose() {
    _placeNameController.dispose();
    _placeAddressController.dispose();
    _roomNameController.dispose();
    _depositController.dispose();
    _advanceController.dispose();
    _rentController.dispose();
    _occupantsController.dispose();
    _uploads.close();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────

  /// Loads only the signed-in owner's listings (query is `ownerId == uid`).
  Future<void> _loadBuildings() async {
    final uid = currentUidOrNull(context);
    if (uid == null) return;
    setState(() => _loadingBuildings = true);
    try {
      final listings = await context
          .read<OwnerOnboardingCubit>()
          .fetchOwnerListings(uid);
      if (!mounted) return;
      final saved = SavedBuilding.fromListings(listings);
      setState(() {
        _ownerListings = listings;
        _savedBuildings = saved;
        if (_building != null) {
          // Prefer the stored copy of a preselected building.
          final match = saved.where((b) => b.id == _building!.id);
          if (match.isNotEmpty) _building = match.first;
        }
        _loadingBuildings = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingBuildings = false);
    }
  }

  List<SavedBuilding> get _allBuildings {
    final list = <SavedBuilding>[..._savedBuildings, ..._newBuildings];
    final current = _building;
    if (current != null && !list.any((b) => b.id == current.id)) {
      list.insert(0, current);
    }
    return list;
  }

  bool get _roomNameTaken =>
      _isRoom &&
      _building != null &&
      OwnerOnboardingCubit.isDuplicateRoom(
        _ownerListings,
        parentPropertyId: _building!.id,
        propertyName: _building!.name,
        roomName: _roomNameController.text,
      );

  String get _listingName {
    if (_isRoom) {
      final b = _building?.name ?? '';
      final r = _roomNameController.text.trim();
      if (b.isEmpty && r.isEmpty) return '';
      return '$b – $r';
    }
    return _placeNameController.text.trim();
  }

  int _int(TextEditingController c, int fallback) =>
      int.tryParse(c.text.trim()) ?? fallback;

  // ── Validation ─────────────────────────────────────────────────────────

  bool get _canContinue {
    switch (_step) {
      case 0:
        return _rentalType != null;
      case 1:
        if (!_uploads.state.isReady) return false;
        if (_isRoom) {
          return _building != null &&
              _roomNameController.text.trim().isNotEmpty &&
              !_roomNameTaken;
        }
        return !_resolvingAddress &&
            _placeNameController.text.trim().isNotEmpty &&
            _placeType != null &&
            _placeType!.trim().isNotEmpty &&
            _placeAddressController.text.trim().isNotEmpty &&
            _placePin != null;
      case 3:
        return _int(_rentController, 0) > 0 && _int(_occupantsController, 0) >= 1;
      default:
        return true;
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────

  void _goTo(int step) => setState(() => _step = step);

  void _back() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
    } else {
      _goTo(_step - 1);
    }
  }

  void _next() {
    if (!_canContinue) return;
    if (_step < _stepCount - 1) {
      FocusScope.of(context).unfocus();
      _goTo(_step + 1);
    }
  }

  Future<void> _addNewProperty() async {
    final created = await showNewPropertySheet(
      context,
      repository: widget.repository,
    );
    if (created == null || !mounted) return;
    setState(() {
      _newBuildings.add(created);
      _building = created;
    });
  }

  Future<void> _post() async {
    final uid = currentUidOrNull(context);
    if (uid == null) {
      _showError('Your session has expired. Please sign in again.');
      return;
    }
    final isRoom = _isRoom;
    final LatLng? pin = isRoom ? _building?.location : _placePin;
    final address = isRoom
        ? _building?.address ?? ''
        : _placeAddressController.text.trim();
    if (pin == null) {
      _showError('Please set the location of your property.');
      return;
    }

    final cubit = context.read<OwnerOnboardingCubit>();
    cubit.reset();
    cubit.saveListing(
      rentalType: isRoom ? 'room' : 'entire_place',
      propertyName: isRoom
          ? _building!.name
          : _placeNameController.text.trim(),
      propertyType: isRoom ? _building!.type : _placeType,
      roomName: isRoom ? _roomNameController.text.trim() : null,
      parentPropertyId: isRoom ? _building!.id : null,
      address: address,
      latitude: pin.latitude,
      longitude: pin.longitude,
      photos: _uploads.state.images,
      propertyCoverPhoto: isRoom ? _building?.coverPhoto : null,
      depositAmount: _int(_depositController, 0),
      advanceMonths: _int(_advanceController, 1),
      allowedGender: _allowedGender,
      smokingAllowed: _smokingAllowed,
      petsAllowed: _petsAllowed,
      curfewHours: _curfewHours,
      maxOccupants: _int(_occupantsController, 1),
      monthlyRent: _int(_rentController, 0),
      isAvailable: _isAvailable,
      amenities: AppOptions.amenities.where(_amenities.contains).toList(),
    );

    setState(() => _posting = true);
    await cubit.submitProperty(uid: uid);
    if (!mounted) return;
    setState(() => _posting = false);

    final state = cubit.state;
    if (state.status != OwnerOnboardingStatus.saved) {
      _showError(state.errorMessage ?? 'Could not post your listing.');
      return;
    }
    cubit.reset();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRouter.landlordHome, (_) => false);
    messenger.showSnackBar(
      const SnackBar(content: Text('Your listing is now posted.')),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.destructive),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  (String, String) get _header {
    switch (_step) {
      case 0:
        return (
          'What are you renting out?',
          'Choose what tenants can rent from you.',
        );
      case 1:
        return _isRoom
            ? (
                'Tell us about your room',
                'Choose the property where your room is located.',
              )
            : ('Tell us about your place', 'Add the details tenants will see.');
      case 2:
        return (
          'Set your house rules',
          'Let tenants know what is allowed.',
        );
      case 3:
        return (
          'Set the rent and capacity',
          'How much is the rent, and how many people can stay?',
        );
      case 4:
        return (
          'What does your place have?',
          'Select everything tenants can use.',
        );
      default:
        return (
          'Check your listing',
          'Make sure everything is correct before posting.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = _header;
    final isLast = _step == _stepCount - 1;

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
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
                  onBack: _back,
                  stepNumber: _step + 1,
                  stepCount: _stepCount,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StepHeader(title: title, subtitle: subtitle),
                      const SizedBox(height: AppSpacing.lg),
                      Expanded(
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: KeyedSubtree(
                              key: ValueKey<String>('$_step-$_rentalType'),
                              child: _buildStep(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      BlocBuilder<ImageUploadCubit, ImageUploadState>(
                        bloc: _uploads,
                        builder: (context, _) => AppPrimaryButton(
                          label: isLast
                              ? (_posting ? 'Posting...' : 'Post Listing')
                              : 'Continue',
                          onPressed: isLast
                              ? (_posting ? null : _post)
                              : (_canContinue ? _next : null),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _rentalTypeStep();
      case 1:
        return _isRoom ? _roomDetailsStep() : _placeDetailsStep();
      case 2:
        return _houseRulesStep();
      case 3:
        return _rentOccupantsStep();
      case 4:
        return _amenitiesStep();
      default:
        return _reviewStep();
    }
  }

  static const String _entirePlaceSvg = '''
<svg
  xmlns="http://www.w3.org/2000/svg"
  width="80"
  height="80"
  viewBox="0 0 24 24"
  fill="none"
  stroke="#ffffff"
  stroke-width="1.5"
  stroke-linecap="round"
  stroke-linejoin="round"
>
  <path d="M8 9l5 5v7h-5v-4m0 4h-5v-7l5 -5m1 1v-6a1 1 0 0 1 1 -1h10a1 1 0 0 1 1 1v17h-8" />
  <path d="M13 7l0 .01" />
  <path d="M17 7l0 .01" />
  <path d="M17 11l0 .01" />
  <path d="M17 15l0 .01" />
</svg>
''';

  // ── Step 1 ─────────────────────────────────────────────────────────────

  Widget _rentalTypeStep() {
    return Column(
      children: [
        RentalTypeCard(
          svgString: _entirePlaceSvg,
          title: 'Entire Place',
          description: 'A whole house, apartment, or condo.',
          selected: _rentalType == 'entire_place',
          onTap: () => setState(() => _rentalType = 'entire_place'),
        ),
        const SizedBox(height: AppSpacing.md),
        RentalTypeCard(
          icon: Icons.bed_outlined,
          title: 'A Room',
          description: 'A room in a boarding house, dorm, or shared home.',
          selected: _rentalType == 'room',
          onTap: () => setState(() => _rentalType = 'room'),
        ),
        const SizedBox(height: AppSpacing.lg),
        RepaintBoundary(
          child: SizedBox(
            width: double.infinity,
            height: 250,
            child: Lottie.asset(
              'assets/images/create_listing_1stscreen.json',
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Lottie load error: $error');
                return Center(
                  child: Icon(
                    Icons.home_work_outlined,
                    size: 80,
                    color: AppColors.accent.withValues(alpha: 0.3),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const ListingCalloutBox(
          title: 'You can add more later',
          subtitle:
              'You can create another listing if you have more rooms or properties.',
          icon: Icons.lightbulb_rounded,
        ),
      ],
    );
  }

  // ── Step 2 ─────────────────────────────────────────────────────────────

  Widget _photosSection({required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label(
            context,
          ).copyWith(color: context.appColors.textSecondary),
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
                  onPick: (src) => _uploads.pickAndUpload(i, src),
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
    );
  }

  Widget _placeDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabelledField(
          label: 'Property name',
          child: AppTextField(
            controller: _placeNameController,
            hintText: 'e.g. Sunshine Apartment',
            // Matches the 120-char cap in firestore.rules.
            inputFormatters: [LengthLimitingTextInputFormatter(120)],
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LabelledField(
          label: 'Property type',
          child: PropertyTypeDropdown(
            value: _placeType,
            hint: 'Select property type',
            options: kPropertyTypes,
            onChanged: (v) => setState(() => _placeType = v),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ListingLocationPicker(
          addressController: _placeAddressController,
          pin: _placePin,
          onPinChanged: (p) => setState(() => _placePin = p),
          onChanged: (resolving) => setState(() => _resolvingAddress = resolving),
        ),
        const SizedBox(height: AppSpacing.md),
        _photosSection(label: 'Add photos'),
      ],
    );
  }

  Widget _roomDetailsStep() {
    final buildings = _allBuildings;
    final building = _building;
    final taken = _roomNameTaken;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabelledField(
          label: 'Property name',
          child: ListingDropdown<String>(
            value: building?.id,
            hint: _loadingBuildings ? 'Loading your properties...' : 'Select a property',
            items: [
              for (final b in buildings)
                DropdownMenuItem(value: b.id, child: Text(b.name)),
              const DropdownMenuItem(
                value: _addNewValue,
                child: Text('+ Add New Property'),
              ),
            ],
            onChanged: (v) {
              if (v == _addNewValue) {
                _addNewProperty();
              } else {
                setState(() {
                  _building = buildings.firstWhere((b) => b.id == v);
                });
              }
            },
          ),
        ),
        if (building != null) ...[
          const SizedBox(height: AppSpacing.md),
          _LockedLocationCard(building: building),
        ],
        const SizedBox(height: AppSpacing.md),
        LabelledField(
          label: 'Room name or number',
          child: AppTextField(
            controller: _roomNameController,
            hintText: 'e.g. Room 101',
            inputFormatters: [LengthLimitingTextInputFormatter(60)],
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (taken) ...[
          const SizedBox(height: 6),
          Text(
            'This room name is already used in ${building!.name}.',
            style: AppTextStyles.caption(
              context,
            ).copyWith(color: AppColors.destructive),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        LabelledField(
          label: 'Listing name',
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: context.appColors.fieldFill,
              borderRadius: BorderRadius.circular(AppRadii.field),
              border: Border.all(color: context.appColors.fieldBorder),
            ),
            child: Text(
              _listingName.isEmpty
                  ? 'Created from the property and room name'
                  : _listingName,
              style: AppTextStyles.body(context).copyWith(
                color: _listingName.isEmpty
                    ? context.appColors.hint
                    : context.appColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _photosSection(label: 'Add room photos'),
      ],
    );
  }

  // ── Step 3 ─────────────────────────────────────────────────────────────

  Widget _houseRulesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabelledField(
          label: 'Security deposit (₱)',
          child: AppTextField(
            controller: _depositController,
            hintText: '3500',
            prefixText: '₱ ',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LabelledField(
          label: 'Advance rent (months)',
          child: AppTextField(
            controller: _advanceController,
            hintText: '1',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LabelledField(
          label: 'Who can rent?',
          child: ListingDropdown<String>(
            value: _allowedGender,
            hint: 'Select...',
            items: const [
              DropdownMenuItem(value: 'Mixed / Any', child: Text('Anyone')),
              DropdownMenuItem(value: 'Male only', child: Text('Male only')),
              DropdownMenuItem(
                value: 'Female only',
                child: Text('Female only'),
              ),
            ],
            onChanged: (v) => setState(() => _allowedGender = v ?? _allowedGender),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ListingToggleRow(
          label: 'Smoking allowed',
          value: _smokingAllowed,
          onChanged: (v) => setState(() => _smokingAllowed = v),
        ),
        const SizedBox(height: AppSpacing.sm),
        ListingToggleRow(
          label: 'Pets allowed',
          value: _petsAllowed,
          onChanged: (v) => setState(() => _petsAllowed = v),
        ),
        const SizedBox(height: AppSpacing.md),
        LabelledField(
          label: 'Curfew',
          child: DropdownButtonFormField<int?>(
            initialValue: _curfewHours,
            isExpanded: true,
            decoration: _dropdownDecoration(),
            items: [
              for (final h in _curfewOptions)
                DropdownMenuItem<int?>(
                  value: h,
                  child: Text(h == null ? 'No curfew' : formatCurfew(h)),
                ),
            ],
            onChanged: (v) => setState(() => _curfewHours = v),
          ),
        ),
      ],
    );
  }

  InputDecoration _dropdownDecoration() => InputDecoration(
    filled: true,
    fillColor: context.appColors.fieldFill,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: 14,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.field),
      borderSide: BorderSide(color: context.appColors.fieldBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.field),
      borderSide: BorderSide(color: AppColors.accent, width: 1.5),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.field),
    ),
  );

  // ── Step 4 ─────────────────────────────────────────────────────────────

  Widget _rentOccupantsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabelledField(
          label: 'Monthly rent (₱)',
          child: AppTextField(
            controller: _rentController,
            hintText: '3500',
            prefixText: '₱ ',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Layer 1 OccupancyMatch: a tenant's group size must not exceed this.
        LabelledField(
          label: 'Maximum number of occupants',
          child: AppTextField(
            controller: _occupantsController,
            hintText: '1',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ListingToggleRow(
          label: 'Available for rent',
          helper: 'Turn off if tenants cannot move in yet.',
          value: _isAvailable,
          onChanged: (v) => setState(() => _isAvailable = v),
        ),
      ],
    );
  }

  // ── Step 5 ─────────────────────────────────────────────────────────────

  Widget _amenitiesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${_amenities.length} of ${AppOptions.amenities.length} selected',
            style: AppTextStyles.caption(context),
          ),
        ),
        for (final (group, items) in kAmenityGroups) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            group,
            style: AppTextStyles.label(context).copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final a in items)
                AmenityChip(
                  label: a,
                  selected: _amenities.contains(a),
                  onTap: () => setState(() {
                    if (!_amenities.remove(a)) _amenities.add(a);
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  // ── Step 6 ─────────────────────────────────────────────────────────────

  String _peso(int v) =>
      '₱${v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  String get _genderLabel => switch (_allowedGender) {
    'Mixed / Any' => 'Anyone',
    final g => g,
  };

  Widget _reviewStep() {
    final address = _isRoom
        ? _building?.address ?? '—'
        : _placeAddressController.text.trim();
    final amenityList = AppOptions.amenities.where(_amenities.contains).toList();
    final photos = _uploads.state.images;

    return Column(
      children: [
        ReviewSectionCard(
          title: 'Listing',
          onEdit: () => _goTo(1),
          child: Column(
            children: [
              ReviewLine('Listing name', _listingName.isEmpty ? '—' : _listingName),
              ReviewLine('Rental type', _isRoom ? 'A Room' : 'Entire Place'),
              if (_isRoom)
                ReviewLine('Property', _building?.name ?? '—')
              else
                ReviewLine('Property type', _placeType ?? '—'),
              ReviewLine('Address', address.isEmpty ? '—' : address),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ReviewSectionCard(
          title: 'Rental type',
          onEdit: () => _goTo(0),
          child: Text(
            _isRoom
                ? 'A Room — a room in a boarding house, dorm, or shared home.'
                : 'Entire Place — a whole house, apartment, or condo.',
            style: AppTextStyles.body(
              context,
            ).copyWith(color: context.appColors.textPrimary),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ReviewSectionCard(
          title: 'Photos',
          onEdit: () => _goTo(1),
          child: photos.isEmpty
              ? Text('No photos yet', style: AppTextStyles.caption(context))
              : SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        photos[i].url,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 72,
                          height: 72,
                          color: context.appColors.fieldBorder,
                          child: const Icon(Icons.image_not_supported_outlined),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        ReviewSectionCard(
          title: 'House rules',
          onEdit: () => _goTo(2),
          child: Column(
            children: [
              ReviewLine('Security deposit', _peso(_int(_depositController, 0))),
              ReviewLine(
                'Advance rent',
                '${_int(_advanceController, 1)} month(s)',
              ),
              ReviewLine('Who can rent', _genderLabel),
              ReviewLine('Smoking', _smokingAllowed ? 'Allowed' : 'Not allowed'),
              ReviewLine('Pets', _petsAllowed ? 'Allowed' : 'Not allowed'),
              ReviewLine('Curfew', formatCurfew(_curfewHours)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ReviewSectionCard(
          title: 'Rent & occupants',
          onEdit: () => _goTo(3),
          child: Column(
            children: [
              ReviewLine('Monthly rent', _peso(_int(_rentController, 0))),
              ReviewLine(
                'Max occupants',
                '${_int(_occupantsController, 1)}',
              ),
              ReviewLine(
                'Availability',
                _isAvailable ? 'Available for rent' : 'Not available',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ReviewSectionCard(
          title: 'Amenities',
          onEdit: () => _goTo(4),
          child: amenityList.isEmpty
              ? Text('None selected', style: AppTextStyles.caption(context))
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final a in amenityList)
                      AmenityChip(
                        label: a,
                        selected: true,
                        showCloseIcon: false,
                        onTap: () {},
                      ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// Read-only address/location summary shown after picking a saved property.
class _LockedLocationCard extends StatelessWidget {
  const _LockedLocationCard({required this.building});

  final SavedBuilding building;

  @override
  Widget build(BuildContext context) {
    final coverUrl = building.coverPhoto?.url;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadii.field),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (coverUrl != null && coverUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                coverUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.apartment_rounded,
                    color: AppColors.accent,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ] else ...[
            Icon(Icons.location_pin, color: AppColors.accent, size: 20),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  building.address,
                  style: AppTextStyles.body(
                    context,
                  ).copyWith(color: context.appColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (building.type != null) building.type!,
                    'Location & cover photo saved with this property',
                  ].join(' · '),
                  style: AppTextStyles.caption(context),
                ),
              ],
            ),
          ),
          Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: context.appColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
