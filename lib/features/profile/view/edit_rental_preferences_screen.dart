import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_options.dart';
import '../../../shared/widgets/map_zoom_controls.dart';
import '../../tenant_onboarding/view/poi_setup_screen.dart';
import '../cubit/edit_preferences_cubit.dart';
import 'edit_constraints_screen.dart';

/// Unified Rental Preferences editor screen.
/// Combines Must-haves, Commute, Amenities, and Priorities into an organized,
/// non-linear editor where the tenant can freely navigate between sections.
class EditRentalPreferencesScreen extends StatelessWidget {
  const EditRentalPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      withEditPreferencesCubit(context, const _EditRentalPreferencesView());
}

class _EditRentalPreferencesView extends StatefulWidget {
  const _EditRentalPreferencesView();

  @override
  State<_EditRentalPreferencesView> createState() =>
      _EditRentalPreferencesViewState();
}

class _EditRentalPreferencesViewState extends State<_EditRentalPreferencesView> {
  // Brand tokens matching onboarding
  static const Color _primaryTeal = Color(0xFF149BBD);
  static const Color _midnightNavy = Color(0xFF1D1C2E);
  static const Color _surfaceTint = Color(0xFFEBF2F5);
  static const Color _borderStroke = Color(0xFFE2E8F0);
  static const Color _borderStrokeDark = Color(0xFFCBD5E1);
  static const Color _textPrimary = Color(0xFF1E293B);
  static const Color _textSecondary = Color(0xFF64748B);

  // Tab navigation (0: Must-haves, 1: Commute, 2: Amenities, 3: Priorities)
  int _selectedTabIndex = 0;
  bool _initialized = false;

  // ── 1. Must-haves Form State ──────────────────────────────────────────────
  final _budgetController = TextEditingController();
  static const _genderOptions = ['Female only', 'Male only', 'Mixed / Any'];
  String _gender = 'Female only';
  bool _wifiRequired = true;
  int _groupSize = 1;
  bool _isSmoker = false;
  bool _hasPet = false;

  // ── 2. Commute Form State ────────────────────────────────────────────────
  String _poiType = 'School';
  final _searchController = TextEditingController();
  final _mapController = MapController();
  LatLng _markerPos = const LatLng(AppOptions.defaultMapLat, AppOptions.defaultMapLng);
  String _resolvedAddress = AppOptions.defaultMapLabel;
  double _maxKm = 3.0;
  List<Map<String, dynamic>> _suggestions = const [];

  // ── 3. Amenities Form State ──────────────────────────────────────────────
  String _roomType = 'Either';
  final Set<String> _preferredAmenities = <String>{};

  // Fixed 14-item checklist
  static const List<String> _amenitiesList = [
    'WiFi',
    'Air conditioning',
    'Electric fan',
    'Private bathroom',
    'Laundry facility',
    'CCTV or security camera',
    'Parking space',
    'Study area or desk',
    'Refrigerator access',
    '24-hour access',
    'Water included in rent',
    'Electricity included in rent',
    'Furnished room',
    'Kitchen or cooking area',
  ];

  // ── 4. Priorities Allocation State ───────────────────────────────────────
  int _rent = 50;
  int _distance = 20;
  int _amenities = 30;

  int get _totalPriorities => _rent + _distance + _amenities;
  bool get _isBalanced => _totalPriorities == 100;

  num? get _budget => num.tryParse(_budgetController.text.trim());
  String? get _budgetError {
    final text = _budgetController.text.trim();
    if (text.isEmpty) return 'Maximum budget is required.';
    final val = num.tryParse(text);
    if (val == null || val < 1000) return 'Maximum budget must be at least ₱1,000.';
    return null;
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _initFrom(EditPreferencesState state) {
    final profile = state.profile;
    if (_initialized || profile == null) return;
    _initialized = true;

    // Must-haves
    _budgetController.text = '${profile.maxBudget.round()}';
    _gender = _genderOptions.contains(profile.requiredGender)
        ? profile.requiredGender
        : 'Mixed / Any';
    _wifiRequired = profile.needsWifi;
    _groupSize = profile.groupSize > 0 ? profile.groupSize.toInt() : 1;
    _isSmoker = profile.isSmoker;
    _hasPet = profile.hasPet;

    // Commute
    if (profile.poiType != null && profile.poiType!.isNotEmpty) {
      _poiType = profile.poiType!;
    }
    _markerPos = LatLng(profile.poiLatLng.latitude, profile.poiLatLng.longitude);
    _resolvedAddress = profile.poiLabel.isNotEmpty ? profile.poiLabel : AppOptions.defaultMapLabel;
    _maxKm = profile.maxDistanceKm.toDouble().clamp(1.0, 10.0);

    // Amenities
    if (profile.roomType != null && profile.roomType!.isNotEmpty) {
      _roomType = profile.roomType!;
    }
    _preferredAmenities
      ..clear()
      ..addAll(profile.preferredAmenities ?? const <String>[]);

    // Priorities
    _rent = (profile.wRent * 100).round();
    _distance = (profile.wDistance * 100).round();
    _amenities = (profile.wAmenities * 100).round();
    if (_rent + _distance + _amenities != 100) {
      _rent = 50;
      _distance = 20;
      _amenities = 30;
    }
  }

  // ── Reverse geocode for Davao ───────────────────────────────────────────
  String _addressFor(LatLng pos) {
    Map<String, dynamic>? nearest;
    double best = double.infinity;
    for (final area in AppOptions.davaoAreas) {
      final dLat = pos.latitude - (area['lat'] as double);
      final dLng = pos.longitude - (area['lng'] as double);
      final d = dLat * dLat + dLng * dLng;
      if (d < best) {
        best = d;
        nearest = area;
      }
    }
    final coords =
        '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
    return 'Near ${nearest!['name']}, Davao City ($coords)';
  }

  void _dropPin(LatLng position, {String? label}) {
    setState(() {
      _markerPos = position;
      _resolvedAddress = label ?? _addressFor(position);
    });
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _suggestions = q.length < 2
          ? const []
          : AppOptions.davaoPlaces
              .where((p) => (p['name'] as String).toLowerCase().contains(q))
              .toList();
    });
  }

  void _selectPlace(Map<String, dynamic> place) {
    final pos = LatLng(place['lat'] as double, place['lng'] as double);
    _searchController.text = place['name'] as String;
    setState(() => _suggestions = const []);
    FocusScope.of(context).unfocus();
    _dropPin(pos, label: '${place['name']}, Davao City');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapController.move(pos, 14.5);
    });
  }

  void _recenterDefault() {
    _dropPin(_markerPos, label: _resolvedAddress);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapController.move(_markerPos, 14.5);
    });
  }

  // ── Priority Slider Auto-Balancing ──────────────────────────────────────
  void _onRentChanged(double rawVal) {
    final rounded = (rawVal / 5).round() * 5;
    final newRent = rounded.clamp(0, 100);
    setState(() {
      _rent = newRent;
      final remaining = 100 - _rent;
      if (_distance > remaining) {
        _distance = remaining;
        _amenities = 0;
      } else {
        _amenities = remaining - _distance;
      }
    });
  }

  void _onDistanceChanged(double rawVal) {
    final rounded = (rawVal / 5).round() * 5;
    final maxDistance = 100 - _rent;
    final newDistance = rounded.clamp(0, maxDistance);
    setState(() {
      _distance = newDistance;
      _amenities = 100 - _rent - _distance;
    });
  }

  void _onAmenitiesChanged(double rawVal) {
    final rounded = (rawVal / 5).round() * 5;
    final maxAmenities = 100 - _rent;
    final newAmenities = rounded.clamp(0, maxAmenities);
    setState(() {
      _amenities = newAmenities;
      _distance = 100 - _rent - _amenities;
    });
  }

  // ── Validation and Save ─────────────────────────────────────────────────
  void _save() {
    if (_budget == null || _budget! < 1000) {
      setState(() => _selectedTabIndex = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid monthly budget of at least ₱1,000.'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    if (!_isBalanced) {
      setState(() => _selectedTabIndex = 3);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your priorities must add up to exactly 100%.'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    context.read<EditPreferencesCubit>().saveAllPreferences(
      maxBudget: _budget!,
      requiredGender: _gender,
      needsWifi: _wifiRequired,
      isSmoker: _isSmoker,
      hasPet: _hasPet,
      groupSize: _groupSize,
      poiType: _poiType,
      poiLatLng: GeoPoint(_markerPos.latitude, _markerPos.longitude),
      poiLabel: _resolvedAddress,
      maxDistanceKm: _maxKm,
      roomType: _roomType,
      preferredAmenities: _preferredAmenities.toList(),
      wRent: _rent / 100.0,
      wDistance: _distance / 100.0,
      wAmenities: _amenities / 100.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditPreferencesCubit, EditPreferencesState>(
      listener: (context, state) {
        if (state.status == EditPreferencesStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rental preferences updated! Matches refreshed.'),
              backgroundColor: _primaryTeal,
            ),
          );
          Navigator.of(context).pop(true);
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.destructive,
            ),
          );
        }
      },
      builder: (context, state) {
        _initFrom(state);
        final isSaving = state.status == EditPreferencesStatus.saving;
        final isLoading = state.status == EditPreferencesStatus.loading;

        if (isLoading) {
          return Scaffold(
            backgroundColor: context.appColors.surface,
            appBar: AppBar(
              backgroundColor: context.appColors.surface,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: context.appColors.textPrimary,
                  size: 18,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text('Rental preferences'),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: context.appColors.surface,
          appBar: AppBar(
            backgroundColor: context.appColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: context.appColors.textPrimary,
                size: 18,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Rental preferences',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.appColors.textPrimary,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(46),
              child: _buildTabPills(),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: _buildCurrentTabContent(),
                  ),
                ),
                _buildStickyBottomBar(isSaving),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Tab Pill Navigation Bar ──────────────────────────────────────────────
  Widget _buildTabPills() {
    final tabs = [
      ('Must-haves', Icons.check_circle_outline_rounded),
      ('Commute', Icons.near_me_outlined),
      ('Amenities', Icons.meeting_room_outlined),
      ('Priorities', Icons.tune_rounded),
    ];

    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final isSelected = _selectedTabIndex == index;
          final (title, icon) = tabs[index];

          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() => _selectedTabIndex = index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? _primaryTeal : context.appColors.fieldFill,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? _primaryTeal : context.appColors.fieldBorder,
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 13,
                    color: isSelected ? Colors.white : _textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : _textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Switcher for Tab Content ─────────────────────────────────────────────
  Widget _buildCurrentTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildMustHavesTab();
      case 1:
        return _buildCommuteTab();
      case 2:
        return _buildAmenitiesTab();
      case 3:
        return _buildPrioritiesTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 0: MUST-HAVES (Matching HardConstraintsScreen)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMustHavesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What are your must-haves?',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.appColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          "We'll only show places that strictly match these conditions.",
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: context.appColors.textSecondary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),

        // Card 1: ABOUT THE PLACE
        _buildSectionCard(
          title: 'ABOUT THE PLACE',
          children: [
            // 1. Maximum monthly budget
            _buildFieldLabel('Maximum monthly budget'),
            const SizedBox(height: 4),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: context.appColors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: context.appColors.fieldFill,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 10, right: 4),
                  child: Text(
                    '₱',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                hintText: 'Enter max budget (e.g., 5000)',
                hintStyle: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12.5,
                  color: context.appColors.hint,
                ),
                errorText: _budgetError,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: _budgetError != null ? AppColors.destructive : context.appColors.fieldBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: _budgetError != null ? AppColors.destructive : _primaryTeal,
                    width: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 2. Who can stay
            _buildFieldLabel('Who can stay'),
            const SizedBox(height: 4),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: context.appColors.fieldFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.appColors.fieldBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _gender,
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: context.appColors.textSecondary,
                    size: 19,
                  ),
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.appColors.textPrimary,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Female only', child: Text('Female only')),
                    DropdownMenuItem(value: 'Male only', child: Text('Male only')),
                    DropdownMenuItem(value: 'Mixed / Any', child: Text('Mixed / Any')),
                  ],
                  onChanged: (v) => setState(() => _gender = v ?? 'Mixed / Any'),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 3. WiFi required
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: context.appColors.fieldFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.appColors.fieldBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'WiFi required',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                  ),
                  _buildToggleSwitch(
                    value: _wifiRequired,
                    onChanged: (v) => setState(() => _wifiRequired = v),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Card 2: ABOUT YOU
        _buildSectionCard(
          title: 'ABOUT YOU',
          children: [
            // Occupancy Stepper
            Row(
              children: [
                Expanded(
                  child: Text(
                    'How many people will stay?',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                ),
                _buildStepper(
                  value: _groupSize,
                  onChanged: (v) => setState(() => _groupSize = v),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Smoking & Pets Sub-card
            Container(
              decoration: BoxDecoration(
                color: context.appColors.fieldFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.appColors.fieldBorder),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'I smoke',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: context.appColors.textPrimary,
                            ),
                          ),
                        ),
                        _buildToggleSwitch(
                          value: _isSmoker,
                          onChanged: (v) => setState(() => _isSmoker = v),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: context.appColors.fieldBorder.withValues(alpha: 0.8),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'I have a pet',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: context.appColors.textPrimary,
                            ),
                          ),
                        ),
                        _buildToggleSwitch(
                          value: _hasPet,
                          onChanged: (v) => setState(() => _hasPet = v),
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
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1: COMMUTE (Matching PoiSetupScreen & DistancePreferenceScreen)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCommuteTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where do you commute to daily?',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _midnightNavy,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Set your school, office, or frequent spot to see places within easy reach.',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: _textSecondary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),

        // Purpose Category
        const Text(
          'I AM COMMUTING TO',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.7,
            color: _textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final type in ['School', 'Workplace', 'Other'])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => setState(() => _poiType = type),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: _poiType == type ? _primaryTeal : context.appColors.fieldFill,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _poiType == type ? _primaryTeal : context.appColors.fieldBorder,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        type,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _poiType == type ? Colors.white : _textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Destination Search Input
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12.5,
            color: _textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search Davao landmark, school, or building...',
            hintStyle: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              color: context.appColors.hint,
            ),
            filled: true,
            fillColor: context.appColors.fieldFill,
            prefixIcon: const Icon(Icons.search, size: 17, color: _primaryTeal),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _suggestions = const []);
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.appColors.fieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _primaryTeal, width: 1.4),
            ),
          ),
        ),

        // Suggestions Dropdown
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _borderStroke),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                for (final place in _suggestions)
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    leading: const Icon(Icons.place_outlined, color: _primaryTeal, size: 17),
                    title: Text(
                      place['name'] as String,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _textPrimary,
                      ),
                    ),
                    onTap: () => _selectPlace(place),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),

        // Map Preview with interactive pin and radius
        Container(
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _borderStroke),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _markerPos,
                  initialZoom: 13.5,
                  onTap: (_, latLng) => _dropPin(latLng),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.rentease.app',
                  ),
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _markerPos,
                        radius: _maxKm * 1000,
                        useRadiusInMeter: true,
                        color: _primaryTeal.withValues(alpha: 0.15),
                        borderColor: _primaryTeal,
                        borderStrokeWidth: 1.4,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _markerPos,
                        width: 34,
                        height: 34,
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          Icons.location_pin,
                          color: _primaryTeal,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              MapZoomControls(controller: _mapController),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _borderStroke),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.my_location_rounded,
                      color: _primaryTeal,
                      size: 16,
                    ),
                    onPressed: _recenterDefault,
                    padding: const EdgeInsets.all(5),
                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                  ),
                ),
              ),
              Positioned(
                left: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: _borderStroke),
                  ),
                  child: const Text(
                    '💡 Tap map or drag pin to adjust your destination',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: _textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Selected Destination Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: _surfaceTint,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _borderStrokeDark),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _primaryTeal.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.location_on_rounded, color: _primaryTeal, size: 15),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DESTINATION POINT:',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 9,
                        fontWeight: FontWeight.normal,
                        letterSpacing: 0.5,
                        color: _primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _resolvedAddress,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PoiSetupScreen(
                        isPicker: true,
                        initialPoiType: _poiType,
                        initialLatLng: _markerPos,
                        initialAddress: _resolvedAddress,
                        initialMaxKm: _maxKm,
                        onLocationConfirmed: (type, pos, addr, maxDist) {
                          setState(() {
                            _poiType = type;
                            _markerPos = pos;
                            _resolvedAddress = addr;
                            _maxKm = maxDist;
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) _mapController.move(pos, 14.5);
                          });
                        },
                      ),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Change',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _primaryTeal,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Travel Distance Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'MAXIMUM TRAVEL DISTANCE',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.7,
                color: _textSecondary,
              ),
            ),
            Text(
              'Up to ${_maxKm.toStringAsFixed(1)} km away',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _primaryTeal,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _primaryTeal,
            inactiveTrackColor: _borderStroke,
            thumbColor: _primaryTeal,
            overlayColor: _primaryTeal.withValues(alpha: 0.15),
            trackHeight: 3.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5),
          ),
          child: Slider(
            value: _maxKm,
            min: 1.0,
            max: 10.0,
            divisions: 18,
            onChanged: (v) => setState(() => _maxKm = v),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _surfaceTint,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _borderStrokeDark),
          ),
          child: Text(
            'Rentals within ${_maxKm.toStringAsFixed(1)} km of your destination will be prioritized.',
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2: AMENITIES (Matching SoftPreferencesStepScreen)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildAmenitiesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Any nice-to-haves?',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.appColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          "Pick extra features you'd like. We'll show places with these first.",
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: context.appColors.textSecondary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),

        // Room Type
        Text(
          'Room type',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: context.appColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final type in ['Solo', 'Shared', 'Either']) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _roomType = type),
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: _roomType == type ? _primaryTeal : context.appColors.fieldFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _roomType == type ? _primaryTeal : context.appColors.fieldBorder,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      type,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _roomType == type ? Colors.white : context.appColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              if (type != 'Either') const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Preferred Amenities Chips
        Text(
          'Preferred amenities (${_preferredAmenities.length} selected)',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: context.appColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final amenity in _amenitiesList) ...[
              _buildAmenityChip(
                label: amenity,
                isSelected: _preferredAmenities.contains(amenity),
                onTap: () {
                  setState(() {
                    if (!_preferredAmenities.remove(amenity)) {
                      _preferredAmenities.add(amenity);
                    }
                  });
                },
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildAmenityChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5.5),
        decoration: BoxDecoration(
          color: isSelected ? _primaryTeal : context.appColors.fieldFill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _primaryTeal : context.appColors.fieldBorder,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
              size: 13,
              color: isSelected ? Colors.white : context.appColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : context.appColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 3: PRIORITIES (Matching TopsisWeightScreen)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPrioritiesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What matters most to you?',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _midnightNavy,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Drag the sliders to prioritize what fits your lifestyle.',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: _textSecondary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),

        // Slider 1: Monthly Rent
        _buildCriteriaSlider(
          label: 'Lower Monthly Rent',
          subtext: 'Show cheaper rates first',
          value: _rent,
          onChanged: _onRentChanged,
        ),
        const SizedBox(height: 8),

        // Slider 2: Commute Distance
        _buildCriteriaSlider(
          label: 'Shorter Daily Commute',
          subtext: 'Show rooms closer to your school or work first',
          value: _distance,
          onChanged: _onDistanceChanged,
        ),
        const SizedBox(height: 8),

        // Slider 3: Amenities
        _buildCriteriaSlider(
          label: 'More Amenities & Inclusions',
          subtext: 'Show rooms with Wi-Fi, AC, and bath first',
          value: _amenities,
          onChanged: _onAmenitiesChanged,
        ),
        const SizedBox(height: 12),

        // Allocation Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: _isBalanced ? _surfaceTint : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isBalanced
                  ? _primaryTeal.withValues(alpha: 0.35)
                  : const Color(0xFFFDE68A),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _isBalanced ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                    color: _isBalanced ? _primaryTeal : const Color(0xFFD97706),
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _isBalanced
                          ? 'Total weight: 100%'
                          : 'Total: $_totalPriorities% / 100% (${100 - _totalPriorities}% remaining)',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _isBalanced ? _primaryTeal : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              const Text(
                'You have 100% to divide across all three. Setting one sets the limit for the rest.',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCriteriaSlider({
    required String label,
    required String subtext,
    required int value,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.appColors.fieldFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _midnightNavy,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _primaryTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$value%',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _primaryTeal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            subtext,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10.5,
              fontWeight: FontWeight.w400,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _primaryTeal,
              inactiveTrackColor: _borderStrokeDark,
              thumbColor: _primaryTeal,
              overlayColor: _primaryTeal.withValues(alpha: 0.15),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper Widgets ───────────────────────────────────────────────────────
  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appColors.fieldBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: context.appColors.textPrimary,
      ),
    );
  }

  Widget _buildToggleSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 38,
        height: 22,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          color: value ? _primaryTeal : context.appColors.fieldBorder,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 17,
          height: 17,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepper({
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStepperButton(
          icon: Icons.remove,
          onTap: value > 1 ? () => onChanged(value - 1) : null,
        ),
        Container(
          width: 30,
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.appColors.textPrimary,
            ),
          ),
        ),
        _buildStepperButton(
          icon: Icons.add,
          onTap: value < 10 ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }

  Widget _buildStepperButton({required IconData icon, VoidCallback? onTap}) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: enabled ? context.appColors.fieldBorder : Colors.transparent,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 13,
          color: enabled ? context.appColors.textPrimary : context.appColors.hint,
        ),
      ),
    );
  }

  // ── Sticky Bottom Bar ────────────────────────────────────────────────────
  Widget _buildStickyBottomBar(bool isSaving) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        border: Border(top: BorderSide(color: context.appColors.fieldBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: isSaving ? null : _save,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(_midnightNavy),
            foregroundColor: WidgetStateProperty.all(Colors.white),
            elevation: WidgetStateProperty.all(0),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          child: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Save changes',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
        ),
      ),
    );
  }
}
