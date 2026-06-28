<<<<<<< Updated upstream
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/mock_data.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/ci_score_pill.dart';
import '../../../shared/widgets/compatible_badge.dart';
=======
﻿import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/mock_data.dart';
import '../../../shared/widgets/listing_image_placeholder.dart';
import '../../../shared/widgets/verified_badge.dart';
import '../../tenant/view/session_filter_sheet.dart';
>>>>>>> Stashed changes
import 'property_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool _isSessionActive = false;
  double _sessionBudget = 6000;
  double _sessionDistance = 5.0;

  List<Map<String, dynamic>> get _displayedProperties {
    if (!_isSessionActive) {
<<<<<<< Updated upstream
      return MockData.properties
          .where((p) => p['bScore'] == 1)
          .toList();
=======
      return MockData.properties.where((p) => p['bScore'] == 1).toList();
>>>>>>> Stashed changes
    }
    return MockData.properties;
  }

<<<<<<< Updated upstream
  List<Widget> _buildFilterChips() {
    final chips = <Widget>[];

    // Always-on teal chips
    chips.add(_TealChip(label: 'Female only'));
    chips.add(const SizedBox(width: 8));
    chips.add(_TealChip(label: 'WiFi'));
    chips.add(const SizedBox(width: 8));
    chips.add(_TealChip(label: '₱4,500 max'));
    chips.add(const SizedBox(width: 8));
    chips.add(_TealChip(label: '3 km'));

    // Session chips
    if (_isSessionActive) {
      chips.add(const SizedBox(width: 8));
      chips.add(_AmberChip(
        label: '₱6,000',
        onClose: () => setState(() => _isSessionActive = false),
      ));
      chips.add(const SizedBox(width: 8));
      chips.add(_AmberChip(
        label: '5 km',
        onClose: () => setState(() => _isSessionActive = false),
      ));
    }

    return chips;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded,
                          color: AppColors.amberPrimary, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Session filters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Temporary — not saved',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Budget slider
                  Row(
                    children: [
                      const Text(
                        'Max budget',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      Text(
                        '₱${_sessionBudget.round()}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.amberPrimary,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(ctx).copyWith(
                      activeTrackColor: AppColors.amberPrimary,
                      thumbColor: AppColors.amberPrimary,
                      inactiveTrackColor: AppColors.border,
                      overlayColor:
                          AppColors.amberPrimary.withValues(alpha: 0.12),
                    ),
                    child: Slider(
                      value: _sessionBudget,
                      min: 3000,
                      max: 10000,
                      divisions: 70,
                      onChanged: (v) {
                        setSheetState(() => _sessionBudget = v);
                        setState(() => _sessionBudget = v);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Distance slider
                  Row(
                    children: [
                      const Text(
                        'Max distance',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      Text(
                        '${_sessionDistance.round()} km',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.amberPrimary,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(ctx).copyWith(
                      activeTrackColor: AppColors.amberPrimary,
                      thumbColor: AppColors.amberPrimary,
                      inactiveTrackColor: AppColors.border,
                      overlayColor:
                          AppColors.amberPrimary.withValues(alpha: 0.12),
                    ),
                    child: Slider(
                      value: _sessionDistance,
                      min: 1,
                      max: 10,
                      divisions: 18,
                      onChanged: (v) {
                        setSheetState(() => _sessionDistance = v);
                        setState(() => _sessionDistance = v);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Apply session filters',
                    color: AppColors.primaryMid,
                    onPressed: () {
                      setState(() => _isSessionActive = true);
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
=======
  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SessionFilterSheet(
        initialBudget: _sessionBudget,
        initialDistance: _sessionDistance,
        onApply: (budget, distance) {
          setState(() {
            _sessionBudget = budget;
            _sessionDistance = distance;
            _isSessionActive = true;
          });
        },
      ),
>>>>>>> Stashed changes
    );
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< Updated upstream
    return Scaffold(
      backgroundColor: AppColors.fieldFill,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Search',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined,
                color: AppColors.textSecondary),
            onPressed: () {},
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _showFilterSheet,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isSessionActive
                      ? AppColors.amberPrimary
                      : AppColors.primaryMid,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: _buildFilterChips()),
          ),
          // Result count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _isSessionActive
                    ? '${_displayedProperties.length} properties — includes outside preferences.'
                    : '${_displayedProperties.length} compatible properties found.',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Property list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ..._displayedProperties.map(
                  (p) => _PropertyCard(
                    property: p,
                    isSessionActive: _isSessionActive,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PropertyDetailScreen(property: p),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_isSessionActive)
                  _SessionFilterSection(
                    sessionBudget: _sessionBudget,
                    sessionDistance: _sessionDistance,
                    onBudgetChanged: (v) =>
                        setState(() => _sessionBudget = v),
                    onDistanceChanged: (v) =>
                        setState(() => _sessionDistance = v),
                    onApply: () => setState(() => _isSessionActive = true),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
=======
    final properties = _displayedProperties;

    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Search',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: context.appColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Spacer(),
                  // Filter button â€” filled accent when session active
                  GestureDetector(
                    onTap: _showFilterSheet,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _isSessionActive
                            ? AppColors.accent
                            : context.appColors.ink,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.tune_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          if (_isSessionActive)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // â”€â”€ Search input â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: context.appColors.fieldFill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.appColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by name, location...',
                    hintStyle: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.appColors.hint,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: context.appColors.textSecondary,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            SizedBox(height: AppSpacing.sm + 4),

            // â”€â”€ Filter chips â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: <Widget>[
                  _TealChip(label: 'Female only'),
                  SizedBox(width: 8),
                  _TealChip(label: 'WiFi'),
                  SizedBox(width: 8),
                  _TealChip(label: '₱4,500 max'),
                  SizedBox(width: 8),
                  _TealChip(label: '3 km'),
                  if (_isSessionActive) ...<Widget>[
                    SizedBox(width: 8),
                    _AmberChip(
                      label: '₱${_sessionBudget.round()}',
                      onClose: () => setState(() => _isSessionActive = false),
                    ),
                    SizedBox(width: 8),
                    _AmberChip(
                      label: '${_sessionDistance.round()} km',
                      onClose: () => setState(() => _isSessionActive = false),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: AppSpacing.sm),

            // â”€â”€ Result count â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                '${properties.length} properties found',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textSecondary,
                ),
              ),
            ),

            SizedBox(height: AppSpacing.sm),

            // â”€â”€ Property list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: properties.length + 1,
                itemBuilder: (ctx, i) {
                  if (i == properties.length) {
                    return SizedBox(height: AppSpacing.lg);
                  }
                  final p = properties[i];
                  return _PropertyCard(
                    property: p,
                    rank: i + 1,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PropertyDetailScreen(property: p),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
>>>>>>> Stashed changes
      ),
    );
  }
}

<<<<<<< Updated upstream
// ── Filter chip widgets ───────────────────────────────────────────────────────

class _TealChip extends StatelessWidget {
  const _TealChip({required this.label});

=======
// â”€â”€ Filter chips â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TealChip extends StatelessWidget {
  const _TealChip({required this.label});
>>>>>>> Stashed changes
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
<<<<<<< Updated upstream
        color: AppColors.tenantFillBlue,
        border: Border.all(color: AppColors.primaryMid),
=======
        color: AppColors.accentSoft,
>>>>>>> Stashed changes
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
<<<<<<< Updated upstream
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryMid,
=======
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.accent,
>>>>>>> Stashed changes
        ),
      ),
    );
  }
}

class _AmberChip extends StatelessWidget {
  const _AmberChip({required this.label, required this.onClose});
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
  final String label;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
<<<<<<< Updated upstream
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.amberFill,
        border: Border.all(color: AppColors.amberPrimary),
=======
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.amberFill,
>>>>>>> Stashed changes
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
<<<<<<< Updated upstream
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.amberText,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close,
                size: 12, color: AppColors.amberText),
=======
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.amberText,
            ),
          ),
          SizedBox(width: 4),
          GestureDetector(
            onTap: onClose,
            child: Icon(Icons.close, size: 12, color: AppColors.amberText),
>>>>>>> Stashed changes
          ),
        ],
      ),
    );
  }
}

<<<<<<< Updated upstream
// ── Property card ─────────────────────────────────────────────────────────────
=======
// â”€â”€ Property card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
>>>>>>> Stashed changes

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({
    required this.property,
<<<<<<< Updated upstream
    required this.isSessionActive,
=======
    required this.rank,
>>>>>>> Stashed changes
    required this.onTap,
  });

  final Map<String, dynamic> property;
<<<<<<< Updated upstream
  final bool isSessionActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isOutside =
        (property['isOutsidePreference'] == true) && isSessionActive;
=======
  final int rank;
  final VoidCallback onTap;

  String _fmtRent(int rent) => rent
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final int seed = (property['id'] as String).hashCode % 5 + 1;
    final double ciScore = (property['ciScore'] as num).toDouble();
    final int rent = (property['rent'] as num).toInt();
    final bool isVerified = property['isVerified'] as bool? ?? false;
>>>>>>> Stashed changes

    return GestureDetector(
      onTap: onTap,
      child: Container(
<<<<<<< Updated upstream
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOutside ? AppColors.amberPrimary : AppColors.border,
            width: isOutside ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
=======
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
>>>>>>> Stashed changes
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
<<<<<<< Updated upstream
          children: [
            // Image area
            Stack(
              children: [
                Container(
                  height: 130,
                  decoration: BoxDecoration(
                    color: isOutside
                        ? AppColors.amberFill
                        : AppColors.tenantFillBlue,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12)),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.home_outlined,
                      color: isOutside
                          ? AppColors.amberPrimary
                          : AppColors.primaryMid,
                      size: 48,
                    ),
                  ),
                ),
                // Rank badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOutside
                          ? AppColors.amberPrimary
                          : AppColors.primaryMid,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${property['rank']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Outside-preference chips
                if (isOutside)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if ((property['distanceExcess'] ?? 0) > 0)
                          const _OutsideChip('Over distance'),
                        const SizedBox(height: 4),
                        if ((property['budgetExcess'] ?? 0) > 0)
                          const _OutsideChip('Over budget'),
                      ],
                    ),
                  ),
              ],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          property['name'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!isOutside)
                        CiScorePill(
                            score: (property['ciScore'] as num).toDouble()),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${property['distance']} km · ₱${property['rent']}/mo · ${property['amenities']} amenities',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (!isOutside && property['bScore'] == 1)
                        const CompatibleBadge(),
                    ],
                  ),
                  if (property['isVerified'] == true) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Icon(Icons.check_circle,
                            color: AppColors.primaryTeal, size: 12),
                        SizedBox(width: 3),
                        Text(
                          'Verified Owner',
                          style: TextStyle(
                            color: AppColors.primaryTeal,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
=======
          children: <Widget>[
            // â”€â”€ Image with rank badge overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ListingImagePlaceholder(seed: seed),
                    // Rank badge â€” top left
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '#$rank',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // â”€â”€ Card body â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Name row + CI score
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          property['name'] as String,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.appColors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${(ciScore * 100).round()}% match',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),

                  // Address
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: context.appColors.textSecondary,
                      ),
                      SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          property['address'] as String,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: context.appColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),

                  // Price + Verified badge
                  Row(
                    children: <Widget>[
                      Text(
                        '₱${_fmtRent(rent)}',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                        ),
                      ),
                      Text(
                        '/mo',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (isVerified) const VerifiedBadge(isVerified: true),
                    ],
                  ),
                  SizedBox(height: AppSpacing.sm),

                  // Send Inquiry button
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text('Send Inquiry'),
                    ),
                  ),
>>>>>>> Stashed changes
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
<<<<<<< Updated upstream

class _OutsideChip extends StatelessWidget {
  const _OutsideChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.amberPrimary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Session filter section ────────────────────────────────────────────────────

class _SessionFilterSection extends StatelessWidget {
  const _SessionFilterSection({
    required this.sessionBudget,
    required this.sessionDistance,
    required this.onBudgetChanged,
    required this.onDistanceChanged,
    required this.onApply,
  });

  final double sessionBudget;
  final double sessionDistance;
  final ValueChanged<double> onBudgetChanged;
  final ValueChanged<double> onDistanceChanged;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.access_time,
                  color: AppColors.amberPrimary, size: 16),
              SizedBox(width: 4),
              Text(
                'Session filters',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Spacer(),
              Text(
                'Temporary — not saved',
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Max budget',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                '₱${sessionBudget.round()}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.amberPrimary,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.amberPrimary,
              thumbColor: AppColors.amberPrimary,
              inactiveTrackColor: AppColors.border,
              overlayColor:
                  AppColors.amberPrimary.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: sessionBudget,
              min: 3000,
              max: 10000,
              divisions: 70,
              onChanged: onBudgetChanged,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Max distance',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                '${sessionDistance.round()} km',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.amberPrimary,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.amberPrimary,
              thumbColor: AppColors.amberPrimary,
              inactiveTrackColor: AppColors.border,
              overlayColor:
                  AppColors.amberPrimary.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: sessionDistance,
              min: 1,
              max: 10,
              divisions: 18,
              onChanged: onDistanceChanged,
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Apply session filters',
            color: AppColors.primaryMid,
            onPressed: onApply,
          ),
        ],
      ),
    );
  }
}
=======
>>>>>>> Stashed changes
