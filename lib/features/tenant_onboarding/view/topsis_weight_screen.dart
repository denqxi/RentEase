import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../cubit/tenant_onboarding_cubit.dart';

/// Screen 4/4 — TOPSIS Preference Priority Allocation.
/// Lets tenants divide a 100% budget across Monthly Rent, Travel Distance,
/// and Amenities using an allocation limit capping system.
class TopsisWeightScreen extends StatefulWidget {
  const TopsisWeightScreen({
    this.initialRent = 0.50,
    this.initialDistance = 0.20,
    this.initialAmenities = 0.30,
    this.onSave,
    super.key,
  });

  final double initialRent;
  final double initialDistance;
  final double initialAmenities;
  final VoidCallback? onSave;

  @override
  State<TopsisWeightScreen> createState() => _TopsisWeightScreenState();
}

class _TopsisWeightScreenState extends State<TopsisWeightScreen> {
  // Theme Color Tokens
  static const Color _primaryTeal = Color(0xFF149BBD);
  static const Color _midnightNavy = Color(0xFF1D1C2E);
  static const Color _surfaceTint = Color(0xFFEBF2F5);
  static const Color _borderStroke = Color(0xFFE2E8F0);
  static const Color _textPrimary = Color(0xFF1E293B);
  static const Color _textSecondary = Color(0xFF64748B);

  // Allocation State (values stored as integer percentages 0-100)
  late int _rent;
  late int _distance;
  late int _amenities;

  int get _total => _rent + _distance + _amenities;
  bool get _isBalanced => _total == 100;

  @override
  void initState() {
    super.initState();
    _rent = (widget.initialRent * 100).round();
    _distance = (widget.initialDistance * 100).round();
    _amenities = (widget.initialAmenities * 100).round();
  }

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

  /// The signed-in user's uid defensively fetched from AuthBloc.
  String? _currentUid(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) return auth.user.uid;
    if (auth is AuthEmailNotVerified) return auth.user.uid;
    return null;
  }

  void _continue() {
    if (widget.onSave != null) {
      widget.onSave!();
      return;
    }

    final uid = _currentUid(context);
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your session has expired. Please sign in again.',
          ),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    // Submit weights as standard decimal representations summing to 1.0
    context.read<TenantOnboardingCubit>().submit(
      uid: uid,
      wRent: _rent / 100.0,
      wDistance: _distance / 100.0,
      wAmenities: _amenities / 100.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = widget.onSave == null &&
        context.select<TenantOnboardingCubit, bool>(
          (c) => c.state.status == TenantOnboardingStatus.saving,
        );

    final canSubmit = _isBalanced && !isSaving;

    return BlocListener<TenantOnboardingCubit, TenantOnboardingState>(
      listenWhen: (prev, curr) =>
          widget.onSave == null && prev.status != curr.status,
      listener: (context, state) {
        if (state.status == TenantOnboardingStatus.saved) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.matchingTransition,
            (_) => false,
            arguments: false, // tenant
          );
        } else if (state.status == TenantOnboardingStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.errorMessage ?? 'Could not save your profile.',
              ),
              backgroundColor: AppColors.destructive,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: context.appColors.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar: Back button, Progress bar (4 / 4), Step indicator
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: context.appColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _borderStroke,
                          ),
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: _textPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    if (widget.onSave == null) ...[
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 1.0,
                            minHeight: 5,
                            backgroundColor: context.appColors.indicatorInactive
                                .withValues(alpha: 0.5),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              _primaryTeal,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        '4 / 4',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textSecondary,
                        ),
                      ),
                    ] else
                      const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Header
                        const Text(
                          'What matters most to you?',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _midnightNavy,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Drag the sliders to prioritize what fits your lifestyle.',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                            color: _textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // 2. Criteria Slider Cards
                        // Card 1: Monthly Rent
                        _CriteriaSliderCard(
                          label: 'Lower Monthly Rent',
                          subtext: 'Show cheaper rates first',
                          value: _rent,
                          onChanged: _onRentChanged,
                        ),
                        const SizedBox(height: 12),

                        // Card 2: Distance from POI
                        _CriteriaSliderCard(
                          label: 'Shorter Daily Commute',
                          subtext:
                              'Show rooms closer to your school or work first',
                          value: _distance,
                          onChanged: _onDistanceChanged,
                        ),
                        const SizedBox(height: 12),

                        // Card 3: Amenities
                        _CriteriaSliderCard(
                          label: 'More Amenities & Inclusions',
                          subtext:
                              'Show rooms with Wi-Fi, AC, and bath first',
                          value: _amenities,
                          onChanged: _onAmenitiesChanged,
                        ),
                        const SizedBox(height: 16),

                        // 3. Footnote & Allocation Indicator Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _isBalanced
                                ? _surfaceTint
                                : const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _isBalanced
                                  ? _primaryTeal.withValues(alpha: 0.35)
                                  : const Color(0xFFFDE68A),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _isBalanced
                                        ? Icons.check_circle_rounded
                                        : Icons.info_outline_rounded,
                                    color: _isBalanced
                                        ? _primaryTeal
                                        : const Color(0xFFD97706),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _isBalanced
                                          ? 'Total weight: 100%'
                                          : 'Total: $_total% / 100% (${100 - _total}% remaining)',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _isBalanced
                                            ? _primaryTeal
                                            : const Color(0xFFB45309),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'You have 100% to divide across all three. Setting one sets the limit for the rest.',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: _textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.onSave != null) ...[
                          const SizedBox(height: 12),
                          const Center(
                            child: Text(
                              'Saving will update your property ranking.',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                color: _textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // 4. Action Button (CTA)
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: canSubmit ? _continue : null,
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.resolveWith<Color>((states) {
                        if (states.contains(WidgetState.disabled)) {
                          return const Color(0xFFD9D9E0);
                        }
                        return _midnightNavy;
                      }),
                      foregroundColor:
                          WidgetStateProperty.resolveWith<Color>((states) {
                        if (states.contains(WidgetState.disabled)) {
                          return _textSecondary;
                        }
                        return Colors.white;
                      }),
                      elevation: WidgetStateProperty.all(0),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    child: Text(
                      widget.onSave != null
                          ? 'Save Changes'
                          : (isSaving
                              ? 'Finding Matches…'
                              : 'Show Matching Rentals'),
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined rounded-2xl card for each allocation criterion.
class _CriteriaSliderCard extends StatelessWidget {
  const _CriteriaSliderCard({
    required this.label,
    required this.subtext,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtext;
  final int value;
  final ValueChanged<double> onChanged;

  static const Color _primaryTeal = Color(0xFF149BBD);
  static const Color _midnightNavy = Color(0xFF1D1C2E);
  static const Color _surfaceTint = Color(0xFFEBF2F5);
  static const Color _borderStroke = Color(0xFFE2E8F0);
  static const Color _textSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: _midnightNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtext,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _surfaceTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$value%',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: _primaryTeal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackShape: const _FullWidthSliderTrackShape(),
              activeTrackColor: _primaryTeal,
              inactiveTrackColor: _borderStroke,
              thumbColor: _primaryTeal,
              overlayColor: _primaryTeal.withValues(alpha: 0.15),
              trackHeight: 3.5,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 8,
              ),
            ),
            child: Slider(
              value: value.toDouble().clamp(0.0, 100.0),
              min: 0.0,
              max: 100.0,
              divisions: 20,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Slider track shape that spans edge-to-edge across the parent container.
class _FullWidthSliderTrackShape extends RoundedRectSliderTrackShape {
  const _FullWidthSliderTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 3.5;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(
      offset.dx,
      trackTop,
      parentBox.size.width,
      trackHeight,
    );
  }
}
