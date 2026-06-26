import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/mock_data.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/ci_score_pill.dart';
import '../../../shared/widgets/compatible_badge.dart';
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
      return MockData.properties
          .where((p) => p['bScore'] == 1)
          .toList();
    }
    return MockData.properties;
  }

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
    );
  }

  @override
  Widget build(BuildContext context) {
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
      ),
    );
  }
}

// ── Filter chip widgets ───────────────────────────────────────────────────────

class _TealChip extends StatelessWidget {
  const _TealChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.tenantFillBlue,
        border: Border.all(color: AppColors.primaryMid),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryMid,
        ),
      ),
    );
  }
}

class _AmberChip extends StatelessWidget {
  const _AmberChip({required this.label, required this.onClose});

  final String label;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.amberFill,
        border: Border.all(color: AppColors.amberPrimary),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
          ),
        ],
      ),
    );
  }
}

// ── Property card ─────────────────────────────────────────────────────────────

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({
    required this.property,
    required this.isSessionActive,
    required this.onTap,
  });

  final Map<String, dynamic> property;
  final bool isSessionActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isOutside =
        (property['isOutsidePreference'] == true) && isSessionActive;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
