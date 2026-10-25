import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_svg_icons.dart';
import '../../../core/firestore/models/tenant_profile_doc.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../owner_onboarding/widgets/listing_form_widgets.dart';
import '../../profile/view/edit_constraints_screen.dart';
import '../../tenant_onboarding/view/poi_setup_screen.dart';

class SessionFilterSheet extends StatefulWidget {
  const SessionFilterSheet({
    required this.initialBudget,
    required this.initialDistance,
    required this.savedBudget,
    required this.savedDistance,
    this.initialRoomType = 'Either',
    this.initialPropertyTypes = const {},
    this.initialAmenities = const {},
    this.initialGroupSize = 1,
    this.initialRequireSmoking = false,
    this.initialRequirePets = false,
    this.initialPoiType = 'School',
    this.initialPoiLabel,
    this.profile,
    required this.onApply,
    this.onReset,
    super.key,
  });

  final double initialBudget;
  final double initialDistance;
  final double savedBudget;
  final double savedDistance;
  final String initialRoomType;
  final Set<String> initialPropertyTypes;
  final Set<String> initialAmenities;
  final int initialGroupSize;
  final bool initialRequireSmoking;
  final bool initialRequirePets;
  final String initialPoiType;
  final String? initialPoiLabel;
  final TenantProfileDoc? profile;
  final VoidCallback? onReset;

  final void Function({
    required double budget,
    required double distance,
    required String roomType,
    required Set<String> propertyTypes,
    required Set<String> amenities,
    required int groupSize,
    required bool requireSmoking,
    required bool requirePets,
    String? poiType,
    String? poiLabel,
    LatLng? poiLatLng,
  }) onApply;

  @override
  State<SessionFilterSheet> createState() => _SessionFilterSheetState();
}

class _SessionFilterSheetState extends State<SessionFilterSheet> {
  late double _budget;
  late double _distance;
  late String _roomType;
  late Set<String> _propertyTypes;
  late Set<String> _amenities;
  late int _groupSize;
  late bool _requireSmoking;
  late bool _requirePets;
  late String _poiType;
  late String _poiLabel;
  LatLng? _poiLatLng;
  late bool _wifiRequired;
  late TextEditingController _budgetController;

  // Track expanded section index (0 = Budget, 1 = Location, 2 = Amenities, 3 = House Rules; -1 = all collapsed)
  int _expandedIndex = 0;

  void _toggleSection(int index) {
    setState(() {
      _expandedIndex = _expandedIndex == index ? -1 : index;
    });
  }

  static const List<String> _availablePropertyTypes = [
    'Boarding House',
    'Dormitory',
    'Apartment',
    'Studio',
    'Room',
  ];

  @override
  void initState() {
    super.initState();
    _budget = widget.initialBudget;
    _distance = widget.initialDistance;
    _roomType = widget.initialRoomType;
    _propertyTypes = Set<String>.from(widget.initialPropertyTypes);
    _amenities = Set<String>.from(widget.initialAmenities);
    _groupSize = widget.initialGroupSize;
    _requireSmoking = widget.initialRequireSmoking;
    _requirePets = widget.initialRequirePets;
    _poiType = widget.initialPoiType;
    _poiLabel = widget.initialPoiLabel ??
        (widget.profile?.poiLabel ?? 'Saved Location');
    final profileGeo = widget.profile?.poiLatLng;
    if (profileGeo != null) {
      _poiLatLng = LatLng(
        profileGeo.latitude,
        profileGeo.longitude,
      );
    }
    _wifiRequired = widget.profile?.needsWifi ?? _amenities.contains('WiFi');
    _budgetController = TextEditingController(text: _budget.round().toString());
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  void _resetToProfile() {
    setState(() {
      _budget = widget.savedBudget;
      _budgetController.text = _budget.round().toString();
      _distance = widget.savedDistance;
      _roomType = widget.profile?.roomType ?? 'Either';
      _propertyTypes.clear();
      _amenities.clear();
      if (widget.profile?.preferredAmenities != null) {
        _amenities.addAll(widget.profile!.preferredAmenities!);
      }
      _groupSize = widget.profile?.groupSize.toInt() ?? 1;
      _requireSmoking = widget.profile?.isSmoker ?? false;
      _requirePets = widget.profile?.hasPet ?? false;
      _poiType = widget.profile?.poiType ?? 'School';
      _poiLabel = widget.profile?.poiLabel ?? 'Saved Location';
      final resetGeo = widget.profile?.poiLatLng;
      if (resetGeo != null) {
        _poiLatLng = LatLng(
          resetGeo.latitude,
          resetGeo.longitude,
        );
      }
      _wifiRequired = widget.profile?.needsWifi ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gender = widget.profile?.requiredGender.trim() ?? 'Any';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.slate300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with integrated Close, Title + Subtitle, and Reset
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 2, right: 6),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.slate500,
                    ),
                  ),
                ),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Search Filters',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Refine your search to find the right property',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: AppColors.slate500,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    _resetToProfile();
                    widget.onReset?.call();
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Reset',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 0.8, color: AppColors.fieldFill),

          // Scrollable Accordions
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  // ── SECTION 1: Price & Budget ─────────────────────────────
                  _ExpandableFilterSection(
                    title: 'PRICE & BUDGET',
                    svgIcon: AppSvgIcons.rentAndCapacity,
                    isExpanded: _expandedIndex == 0,
                    onToggle: () => _toggleSection(0),
                    summaryBadge:
                        '₱${_budget.round()} · $_roomType',
                    children: [
                      // Max monthly budget header
                      Row(
                        children: [
                          const Text(
                            'Maximum monthly budget',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate800,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '₱${_budget.round()}/mo',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Default: ₱${widget.savedBudget.round()}/mo',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: AppColors.slate500,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Budget numeric TextField matching Onboarding Step 1
                      TextField(
                        controller: _budgetController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (val) {
                          final numVal = double.tryParse(val);
                          if (numVal != null) {
                            setState(() {
                              _budget = numVal.clamp(1000, 10000);
                            });
                          }
                        },
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate900,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: AppColors.slate50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 12, right: 6),
                            child: Text(
                              '₱',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slate600,
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                          hintText: 'Enter max budget (1,000 - 10,000)',
                          hintStyle: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12.5,
                            color: AppColors.slate400,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Synchronized budget Slider
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: AppColors.slate200,
                          thumbColor: AppColors.primary,
                          trackHeight: 3.5,
                        ),
                        child: Slider(
                          value: _budget.clamp(1000, 10000),
                          min: 1000,
                          max: 10000,
                          divisions: 90,
                          onChanged: (v) {
                            setState(() {
                              _budget = v;
                              _budgetController.text = v.round().toString();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Room arrangement
                      const Text(
                        'Room arrangement',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (final type
                              in const ['Solo', 'Shared', 'Either']) ...[
                            Expanded(
                              child: _RoomTypePill(
                                label: type,
                                isSelected: _roomType == type,
                                onTap: () => setState(() => _roomType = type),
                              ),
                            ),
                            if (type != 'Either') const SizedBox(width: 8),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Property categories
                      const Text(
                        'Property categories',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final pType in _availablePropertyTypes)
                            _FilterChip(
                              label: pType,
                              isSelected: _propertyTypes.contains(pType),
                              onTap: () {
                                setState(() {
                                  if (_propertyTypes.contains(pType)) {
                                    _propertyTypes.remove(pType);
                                  } else {
                                    _propertyTypes.add(pType);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── SECTION 2: Location & Commute ─────────────────────────
                  _ExpandableFilterSection(
                    title: 'LOCATION & COMMUTE',
                    svgIcon: AppSvgIcons.location,
                    isExpanded: _expandedIndex == 1,
                    onToggle: () => _toggleSection(1),
                    summaryBadge:
                        '${_distance.toStringAsFixed(1)} km · $_poiType',
                    children: [
                      // Destination info preview card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.slate200,
                            width: 0.8,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row: Label on left, Category Badge on top-right
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'DESTINATION POINT',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.slate500,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.slate200,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _poiType,
                                    style: const TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.slate600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Only display address with bigger text
                            Text(
                              _poiLabel.isNotEmpty ? _poiLabel : 'Davao City',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.slate900,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Change button on bottom-left, smaller with pin icon
                            InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => PoiSetupScreen(
                                      isPicker: true,
                                      initialPoiType: _poiType,
                                      initialLatLng: _poiLatLng,
                                      initialAddress: _poiLabel,
                                      initialMaxKm: _distance,
                                      onLocationConfirmed:
                                          (poiType, pos, address, maxKm) {
                                        setState(() {
                                          _poiType = poiType;
                                          _poiLatLng = pos;
                                          _poiLabel = address;
                                          _distance = maxKm;
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      color: AppColors.surface,
                                      size: 13,
                                    ),
                                    SizedBox(width: 3.5),
                                    Text(
                                      'Change',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.surface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Max Distance
                      Row(
                        children: [
                          const Text(
                            'Max travel distance',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate800,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_distance.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Radius around ${_poiLabel.isNotEmpty ? _poiLabel : 'destination'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: AppColors.slate500,
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: AppColors.slate200,
                          thumbColor: AppColors.primary,
                          trackHeight: 3.5,
                        ),
                        child: Slider(
                          value: _distance.clamp(0.5, 15),
                          min: 0.5,
                          max: 15,
                          divisions: 29,
                          onChanged: (v) => setState(() => _distance = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── SECTION 3: All Deciding Amenities ─────────────────────
                  _ExpandableFilterSection(
                    title: 'AMENITIES & INCLUSIONS',
                    svgIcon: AppSvgIcons.amenities,
                    isExpanded: _expandedIndex == 2,
                    onToggle: () => _toggleSection(2),
                    summaryBadge: _amenities.isNotEmpty
                        ? '${_amenities.length} selected'
                        : 'Any',
                    children: [
                      for (int i = 0; i < kAmenityGroups.length; i++) ...[
                        Text(
                          kAmenityGroups[i].$1.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate500,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final a in kAmenityGroups[i].$2)
                              _IconChip(
                                label: a,
                                icon: amenityIconFor(a),
                                isSelected: _amenities.contains(a),
                                onTap: () {
                                  setState(() {
                                    if (_amenities.contains(a)) {
                                      _amenities.remove(a);
                                    } else {
                                      _amenities.add(a);
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                        if (i < kAmenityGroups.length - 1)
                          const SizedBox(height: 14),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── SECTION 4: House Rules & Occupancy ────────────────────
                  _ExpandableFilterSection(
                    title: 'HOUSE RULES & OCCUPANCY',
                    svgIcon: AppSvgIcons.houseRules,
                    isExpanded: _expandedIndex == 3,
                    onToggle: () => _toggleSection(3),
                    summaryBadge: _groupSize > 1 ||
                            _requireSmoking ||
                            _requirePets ||
                            _wifiRequired
                        ? '$_groupSize person${_groupSize > 1 ? 's' : ''}'
                        : 'Standard',
                    children: [
                      // Occupancy Stepper
                      Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Number of occupants',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.slate800,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Accommodates your group size',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.slate500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.fieldFill,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 16),
                                  padding: const EdgeInsets.all(6),
                                  constraints: const BoxConstraints(),
                                  onPressed: _groupSize > 1
                                      ? () => setState(() => _groupSize--)
                                      : null,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Text(
                                    '$_groupSize',
                                    style: const TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.slate800,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 16),
                                  padding: const EdgeInsets.all(6),
                                  constraints: const BoxConstraints(),
                                  onPressed: _groupSize < 10
                                      ? () => setState(() => _groupSize++)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(
                        height: 1,
                        thickness: 0.6,
                        color: AppColors.slate200,
                      ),
                      const SizedBox(height: 10),

                      // Smoking Allowed
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Smoking allowed only',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.slate800,
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: 0.78,
                            alignment: Alignment.centerRight,
                            child: Switch(
                              value: _requireSmoking,
                              activeThumbColor: AppColors.surface,
                              activeTrackColor: AppColors.primary,
                              inactiveThumbColor: AppColors.slate400,
                              inactiveTrackColor: AppColors.slate200,
                              trackOutlineColor:
                                  WidgetStateProperty.resolveWith(
                                (states) => AppColors.transparent,
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onChanged: (v) =>
                                  setState(() => _requireSmoking = v),
                            ),
                          ),
                        ],
                      ),

                      // Pets Allowed
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Pets allowed only',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.slate800,
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: 0.78,
                            alignment: Alignment.centerRight,
                            child: Switch(
                              value: _requirePets,
                              activeThumbColor: AppColors.surface,
                              activeTrackColor: AppColors.primary,
                              inactiveThumbColor: AppColors.slate400,
                              inactiveTrackColor: AppColors.slate200,
                              trackOutlineColor:
                                  WidgetStateProperty.resolveWith(
                                (states) => AppColors.transparent,
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onChanged: (v) => setState(() => _requirePets = v),
                            ),
                          ),
                        ],
                      ),

                      // WiFi Required
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'WiFi required',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.slate800,
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: 0.78,
                            alignment: Alignment.centerRight,
                            child: Switch(
                              value: _wifiRequired,
                              activeThumbColor: AppColors.surface,
                              activeTrackColor: AppColors.primary,
                              inactiveThumbColor: AppColors.slate400,
                              inactiveTrackColor: AppColors.slate200,
                              trackOutlineColor:
                                  WidgetStateProperty.resolveWith(
                                (states) => AppColors.transparent,
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onChanged: (v) {
                                setState(() {
                                  _wifiRequired = v;
                                  if (v) {
                                    _amenities.add('WiFi');
                                  } else {
                                    _amenities.remove('WiFi');
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Locked Gender Policy Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                AppColors.slate200.withValues(alpha: 0.6),
                            width: 0.6,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.slate900
                                  .withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.lock_outline_rounded,
                                size: 16,
                                color: AppColors.slate500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Gender Rule: $gender',
                                        style: const TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.slate800,
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  const EditConstraintsScreen(),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'Edit Profile',
                                          style: TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Landlord-enforced policy based on your verified profile.',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.slate500,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Sticky Bottom Apply Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(
                top: BorderSide(color: AppColors.fieldFill, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.scrim.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(
                      budget: _budget,
                      distance: _distance,
                      roomType: _roomType,
                      propertyTypes: _propertyTypes,
                      amenities: _amenities,
                      groupSize: _groupSize,
                      requireSmoking: _requireSmoking,
                      requirePets: _requirePets,
                      poiType: _poiType,
                      poiLabel: _poiLabel,
                      poiLatLng: _poiLatLng,
                    );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.appColors.ink,
                    foregroundColor: AppColors.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.surface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACCORDION / EXPANDABLE FILTER SECTION WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _ExpandableFilterSection extends StatelessWidget {
  const _ExpandableFilterSection({
    required this.title,
    required this.svgIcon,
    required this.isExpanded,
    required this.onToggle,
    required this.summaryBadge,
    required this.children,
  });

  final String title;
  final String svgIcon;
  final bool isExpanded;
  final VoidCallback onToggle;
  final String summaryBadge;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.slate200,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    alignment: Alignment.center,
                    child: AppSvgIcon(
                      svgString: svgIcon,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    summaryBadge,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: AppColors.slate400,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Collapsible body
          if (isExpanded) ...[
            const Divider(height: 1, thickness: 0.6, color: AppColors.fieldFill),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoomTypePill extends StatelessWidget {
  const _RoomTypePill({
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 38,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.slate50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.slate200.withValues(alpha: 0.8),
            width: isSelected ? 1.0 : 0.6,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.surface : AppColors.slate600,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.slate50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.6)
                : AppColors.slate200.withValues(alpha: 0.8),
            width: isSelected ? 1.0 : 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, size: 13, color: AppColors.primary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.slate700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.slate50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.6)
                : AppColors.slate200.withValues(alpha: 0.8),
            width: isSelected ? 1.0 : 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13.5,
              color: isSelected ? AppColors.primary : AppColors.slate500,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.slate700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
