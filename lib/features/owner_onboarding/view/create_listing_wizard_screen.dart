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
import '../l10n/listing_strings.dart';
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

  /// English / Tagalog for this wizard only; remembered on the device.
  bool _tagalog = false;
  ListingStrings get _s => ListingStrings(_tagalog);

  Future<void> _loadLanguage() async {
    final tagalog = await ListingLanguageStore.isTagalog();
    if (mounted && tagalog != _tagalog) setState(() => _tagalog = tagalog);
  }

  void _setLanguage(bool tagalog) {
    if (tagalog == _tagalog) return;
    setState(() => _tagalog = tagalog);
    ListingLanguageStore.setTagalog(tagalog);
  }

  @override
  void initState() {
    super.initState();
    _loadLanguage();
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

  bool get _isPresetRoom => widget.addRoomTo != null;
  int get _minStep => _isPresetRoom ? 1 : 0;

  void _goTo(int step) => setState(() => _step = step);

  void _back() {
    if (_step <= _minStep) {
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
    messenger.showSnackBar(SnackBar(content: Text(_s.posted)));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.destructive),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  (String, String) get _header => switch (_step) {
    0 => _s.headerRentalType,
    1 => _isRoom ? _s.headerRoomDetails : _s.headerPlaceDetails,
    2 => _s.headerHouseRules,
    3 => _s.headerRent,
    4 => _s.headerAmenities,
    _ => _s.headerReview,
  };

  /// Compact English / Tagalog switch above the step header.
  Widget _languageToggle() {
    Widget option(String label, bool tagalog) {
      final selected = _tagalog == tagalog;
      return GestureDetector(
        onTap: () => _setLanguage(tagalog),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : context.appColors.surface,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w700,
              color: selected
                  ? AppColors.onInk
                  : context.appColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: 'Language',
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: context.appColors.fieldBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            option(_s.languageEnglish, false),
            option(_s.languageTagalog, true),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = _header;
    final isLast = _step == _stepCount - 1;

    return PopScope(
      canPop: _step <= _minStep,
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: _languageToggle(),
                      ),
                      const SizedBox(height: AppSpacing.sm),
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
                              ? (_posting ? _s.posting : _s.postListing)
                              : _s.continueLabel,
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

  /// Step hint shown above the fields: what to fill in and how it is used.
  /// Step 0 has its own callout below the rental type cards.
  (String, String, IconData)? get _hint => switch (_step) {
    1 => (
      _s.tipHowTo,
      _isRoom ? _s.tipRoomBody : _s.tipPlaceBody,
      Icons.info_outline_rounded,
    ),
    2 => (_s.tipRulesTitle, _s.tipRulesBody, Icons.rule_rounded),
    3 => (_s.tipRentTitle, _s.tipRentBody, Icons.payments_outlined),
    4 => (_s.tipAmenitiesTitle, _s.tipAmenitiesBody, Icons.checklist_rounded),
    5 => (_s.tipReviewTitle, _s.tipReviewBody, Icons.task_alt_rounded),
    _ => null,
  };

  Widget _buildStep() {
    final hint = _hint;
    final step = switch (_step) {
      0 => _rentalTypeStep(),
      1 => _isRoom ? _roomDetailsStep() : _placeDetailsStep(),
      2 => _houseRulesStep(),
      3 => _rentOccupantsStep(),
      4 => _amenitiesStep(),
      _ => _reviewStep(),
    };
    if (hint == null) return step;
    final (title, subtitle, icon) = hint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListingCalloutBox(title: title, subtitle: subtitle, icon: icon),
        const SizedBox(height: AppSpacing.lg),
        step,
      ],
    );
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
          title: _s.entirePlace,
          description: _s.entirePlaceDesc,
          selected: _rentalType == 'entire_place',
          onTap: () => setState(() => _rentalType = 'entire_place'),
        ),
        const SizedBox(height: AppSpacing.md),
        RentalTypeCard(
          icon: Icons.bed_outlined,
          title: _s.aRoom,
          description: _s.aRoomDesc,
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
        ListingCalloutBox(
          title: _s.addMoreLaterTitle,
          subtitle: _s.addMoreLaterBody,
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
          _s.photosCaption(CloudinaryConfig.maxPropertyPhotos),
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
          label: _s.propertyName,
          child: AppTextField(
            controller: _placeNameController,
            hintText: _s.propertyNameHint,
            // Matches the 120-char cap in firestore.rules.
            inputFormatters: [LengthLimitingTextInputFormatter(120)],
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LabelledField(
          label: _s.propertyType,
          child: PropertyTypeDropdown(
            value: _placeType,
            hint: _s.propertyTypeHint,
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
        _photosSection(label: _s.addPhotos),
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
          label: _s.propertyName,
          child: ListingDropdown<String>(
            value: building?.id,
            hint: _loadingBuildings ? _s.loadingProperties : _s.selectProperty,
            items: [
              for (final b in buildings)
                DropdownMenuItem(value: b.id, child: Text(b.name)),
              DropdownMenuItem(
                value: _addNewValue,
                child: Text(_s.addNewProperty),
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
          label: _s.roomName,
          child: AppTextField(
            controller: _roomNameController,
            hintText: _s.roomNameHint,
            inputFormatters: [LengthLimitingTextInputFormatter(60)],
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (taken) ...[
          const SizedBox(height: 6),
          Text(
            _s.roomNameTaken(building!.name),
            style: AppTextStyles.caption(
              context,
            ).copyWith(color: AppColors.destructive),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        LabelledField(
          label: _s.listingName,
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
                  ? _s.listingNameAuto
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
        _photosSection(label: _s.addRoomPhotos),
      ],
    );
  }

  // ── Step 3 ─────────────────────────────────────────────────────────────

  Widget _houseRulesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabelledField(
          label: _s.deposit,
          child: AppTextField(
            controller: _depositController,
            hintText: '3500',
            prefixText: '₱ ',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _s.depositCaption,
          style: AppTextStyles.caption(context),
        ),
        const SizedBox(height: AppSpacing.md),
        LabelledField(
          label: _s.advance,
          child: AppTextField(
            controller: _advanceController,
            hintText: '1',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _s.advanceCaption,
          style: AppTextStyles.caption(context),
        ),
        const SizedBox(height: AppSpacing.md),
        LabelledField(
          label: _s.whoCanRent,
          child: ListingDropdown<String>(
            value: _allowedGender,
            hint: _s.selectHint,
            // Values stay English (stored + used by matching); labels translate.
            items: [
              DropdownMenuItem(value: 'Mixed / Any', child: Text(_s.anyone)),
              DropdownMenuItem(value: 'Male only', child: Text(_s.maleOnly)),
              DropdownMenuItem(
                value: 'Female only',
                child: Text(_s.femaleOnly),
              ),
            ],
            onChanged: (v) => setState(() => _allowedGender = v ?? _allowedGender),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ListingToggleRow(
          label: _s.smokingAllowed,
          value: _smokingAllowed,
          onChanged: (v) => setState(() => _smokingAllowed = v),
        ),
        const SizedBox(height: AppSpacing.sm),
        ListingToggleRow(
          label: _s.petsAllowed,
          value: _petsAllowed,
          onChanged: (v) => setState(() => _petsAllowed = v),
        ),
        const SizedBox(height: AppSpacing.md),
        LabelledField(
          label: _s.curfew,
          child: DropdownButtonFormField<int?>(
            initialValue: _curfewHours,
            isExpanded: true,
            decoration: _dropdownDecoration(),
            items: [
              for (final h in _curfewOptions)
                DropdownMenuItem<int?>(
                  value: h,
                  child: Text(h == null ? _s.noCurfew : formatCurfew(h)),
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
      borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
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
          label: _s.monthlyRent,
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
          label: _s.maxOccupants,
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
          label: _s.availableForRent,
          helper: _s.availableHelper,
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
            _s.amenitiesSelected(
              _amenities.length,
              AppOptions.amenities.length,
            ),
            style: AppTextStyles.caption(context),
          ),
        ),
        for (final (group, items) in kAmenityGroups) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _s.amenityGroup(group),
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
                  displayLabel: _s.amenity(a),
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
    'Mixed / Any' => _s.anyone,
    'Male only' => _s.maleOnly,
    'Female only' => _s.femaleOnly,
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
          title: _s.reviewListing,
          onEdit: () => _goTo(1),
          child: Column(
            children: [
              ReviewLine(_s.listingName, _listingName.isEmpty ? '—' : _listingName),
              ReviewLine(_s.reviewRentalType, _isRoom ? _s.aRoom : _s.entirePlace),
              if (_isRoom)
                ReviewLine(_s.reviewProperty, _building?.name ?? '—')
              else
                ReviewLine(_s.propertyType, _placeType ?? '—'),
              ReviewLine(_s.reviewAddress, address.isEmpty ? '—' : address),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ReviewSectionCard(
          title: _s.reviewRentalType,
          onEdit: () => _goTo(0),
          child: Text(
            _isRoom ? _s.reviewRoomType : _s.reviewPlaceType,
            style: AppTextStyles.body(
              context,
            ).copyWith(color: context.appColors.textPrimary),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ReviewSectionCard(
          title: _s.reviewPhotos,
          onEdit: () => _goTo(1),
          child: photos.isEmpty
              ? Text(_s.noPhotos, style: AppTextStyles.caption(context))
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
                        // Decode a thumbnail, not the full upload; wide
                        // enough to cover 72dp at 3x for 16:9 photos.
                        cacheWidth: 400,
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
          title: _s.reviewHouseRules,
          onEdit: () => _goTo(2),
          child: Column(
            children: [
              ReviewLine(_s.reviewDeposit, _peso(_int(_depositController, 0))),
              ReviewLine(
                _s.reviewAdvance,
                _s.months(_int(_advanceController, 1)),
              ),
              ReviewLine(_s.reviewWhoCanRent, _genderLabel),
              ReviewLine(
                _s.reviewSmoking,
                _smokingAllowed ? _s.allowed : _s.notAllowed,
              ),
              ReviewLine(_s.reviewPets, _petsAllowed ? _s.allowed : _s.notAllowed),
              ReviewLine(
                _s.curfew,
                _curfewHours == null ? _s.noCurfew : formatCurfew(_curfewHours),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ReviewSectionCard(
          title: _s.reviewRent,
          onEdit: () => _goTo(3),
          child: Column(
            children: [
              ReviewLine(_s.reviewMonthlyRent, _peso(_int(_rentController, 0))),
              ReviewLine(
                _s.reviewMaxOccupants,
                '${_int(_occupantsController, 1)}',
              ),
              ReviewLine(
                _s.reviewAvailability,
                _isAvailable ? _s.availableForRent : _s.notAvailable,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ReviewSectionCard(
          title: _s.reviewAmenities,
          onEdit: () => _goTo(4),
          child: amenityList.isEmpty
              ? Text(_s.noneSelected, style: AppTextStyles.caption(context))
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final a in amenityList)
                      AmenityChip(
                        label: a,
                        displayLabel: _s.amenity(a),
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
                cacheWidth: 256,
                errorBuilder: (_, _, _) => Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.onInk,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    color: AppColors.accent,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ] else ...[
            const Icon(Icons.location_pin, color: AppColors.accent, size: 20),
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
