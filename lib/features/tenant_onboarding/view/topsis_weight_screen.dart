import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../cubit/tenant_onboarding_cubit.dart';
import '../../matching/domain/entities/priority_weights.dart';
import '../../../shared/widgets/priority_sliders.dart';
import '../../../shared/widgets/app_snack_bar.dart';

/// Screen 4/4 — TOPSIS Preference Priority Allocation.
/// Lets tenants divide a 100% budget across Monthly Rent, Travel Distance,
/// and Amenities using an allocation limit capping system.
class TopsisWeightScreen extends StatefulWidget {
  const TopsisWeightScreen({
    this.initialRent = 0.35,
    this.initialDistance = 0.35,
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
  static const Color _primaryTeal = AppColors.primary;
  static const Color _midnightNavy = AppColors.ink;
  Color get _borderStroke => context.appColors.fieldBorder;
  Color get _textPrimary => context.appColors.textPrimary;
  Color get _textSecondary => context.appColors.textSecondary;

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

  void _onWeightsChanged(PriorityWeights next) {
    setState(() {
      _rent = next.rent;
      _distance = next.distance;
      _amenities = next.amenities;
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
      AppSnackBar.show(
        ScaffoldMessenger.of(context),
        'Your session has expired. Please sign in again.',
        kind: AppSnackKind.error,
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
          AppSnackBar.show(
            ScaffoldMessenger.of(context),
            state.errorMessage ?? 'Could not save your profile.',
            kind: AppSnackKind.error,
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
                    Semantics(
                      button: true,
                      label: 'Back',
                      child: GestureDetector(
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
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: _textPrimary,
                          size: 24,
                        ),
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
                      Text(
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
                        Text(
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

                        // 2. The rule, then the three priority sliders
                        PrioritySliders(
                          weights: PriorityWeights(
                            rent: _rent,
                            distance: _distance,
                            amenities: _amenities,
                          ),
                          onChanged: _onWeightsChanged,
                        ),
                        if (widget.onSave != null) ...[
                          const SizedBox(height: 12),
                          Center(
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
                          return context.appColors.indicatorInactive;
                        }
                        return _midnightNavy;
                      }),
                      foregroundColor:
                          WidgetStateProperty.resolveWith<Color>((states) {
                        if (states.contains(WidgetState.disabled)) {
                          return _textSecondary;
                        }
                        return AppColors.onInk;
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

