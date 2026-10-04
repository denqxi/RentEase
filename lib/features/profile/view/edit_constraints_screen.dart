import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../registration/widgets/preference_dropdown.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_toggle.dart';
import '../../auth/presentation/current_uid.dart';
import '../../matching/data/repositories/filtering_repository_impl.dart';
import '../../matching/data/repositories/topsis_repository_impl.dart';
import '../../matching/domain/services/filtering_service.dart';
import '../../matching/domain/services/topsis_service.dart';
import '../../tenant_onboarding/data/repositories/tenant_profile_repository_impl.dart';
import '../cubit/edit_preferences_cubit.dart';

/// Shared by both Profile edit screens: an [EditPreferencesCubit] for the
/// signed-in tenant, or a sign-in prompt.
Widget withEditPreferencesCubit(BuildContext context, Widget child) {
  final uid = currentUidOrNull(context);
  if (uid == null) {
    return const _EditScaffold(
      title: 'Edit preferences',
      body: Center(child: Text('Sign in to edit your preferences.')),
    );
  }
  return BlocProvider(
    create: (_) => EditPreferencesCubit(
      uid: uid,
      repository: TenantProfileRepositoryImpl(),
      filteringService: FilteringService(repository: FilteringRepositoryImpl()),
      topsisService: TopsisService(repository: TopsisRepositoryImpl()),
    ),
    child: child,
  );
}

/// Edits the tenant's hard constraints (tenantProfiles). Pops `true` once
/// saved and re-matched, so the caller can refresh Home/Search.
class EditConstraintsScreen extends StatelessWidget {
  const EditConstraintsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      withEditPreferencesCubit(context, const _EditConstraintsView());
}

class _EditConstraintsView extends StatefulWidget {
  const _EditConstraintsView();

  @override
  State<_EditConstraintsView> createState() => _EditConstraintsViewState();
}

class _EditConstraintsViewState extends State<_EditConstraintsView> {
  static const _genderOptions = ['Female only', 'Male only', 'Mixed / Any'];

  final _budgetController = TextEditingController();
  String _gender = 'Mixed / Any';
  bool _wifiRequired = false;
  double _maxDistance = 3.0;
  bool _initialized = false;

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  void _initFrom(EditPreferencesState state) {
    final profile = state.profile;
    if (_initialized || profile == null) return;
    _initialized = true;
    _budgetController.text = '${profile.maxBudget.round()}';
    _gender = _genderOptions.contains(profile.requiredGender)
        ? profile.requiredGender
        : 'Mixed / Any'; // any other wildcard ('Any', 'All', …)
    _wifiRequired = profile.needsWifi;
    _maxDistance = profile.maxDistanceKm.toDouble().clamp(0.5, 10.0);
  }

  void _save() {
    context.read<EditPreferencesCubit>().saveConstraints(
      maxBudget: int.tryParse(_budgetController.text.trim()) ?? 0,
      requiredGender: _gender,
      needsWifi: _wifiRequired,
      maxDistanceKm: _maxDistance,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditPreferencesCubit, EditPreferencesState>(
      listener: (context, state) {
        if (state.status == EditPreferencesStatus.saved) {
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
        final saving = state.status == EditPreferencesStatus.saving;

        if (state.status == EditPreferencesStatus.loading) {
          return const _EditScaffold(
            title: 'Edit preferences',
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.profile == null) {
          return _EditScaffold(
            title: 'Edit preferences',
            body: _Message(state.errorMessage ?? 'Could not load preferences.'),
          );
        }

        return _EditScaffold(
          title: 'Edit preferences',
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: AppSpacing.md),
                      LabelledField(
                        label: 'Max monthly budget',
                        child: AppTextField(
                          controller: _budgetController,
                          prefixText: '₱ ',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          hintText: '4500',
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      PreferenceDropdown(
                        label: 'Gender policy',
                        value: _gender,
                        hint: 'Select gender policy',
                        items: _genderOptions,
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                      SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'WiFi required',
                              style: AppTextStyles.label(
                                context,
                              ).copyWith(color: context.appColors.textPrimary),
                            ),
                          ),
                          AppToggle(
                            value: _wifiRequired,
                            onChanged: (v) => setState(() => _wifiRequired = v),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Max distance from your POI',
                              style: AppTextStyles.label(
                                context,
                              ).copyWith(color: context.appColors.textPrimary),
                            ),
                          ),
                          Text(
                            '${_maxDistance.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _maxDistance,
                        min: 0.5,
                        max: 10,
                        divisions: 19,
                        activeColor: AppColors.accent,
                        inactiveColor: context.appColors.indicatorInactive,
                        onChanged: (v) => setState(() => _maxDistance = v),
                      ),
                      SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
              _SaveBar(
                saving: saving,
                note: 'Saving will recompute your property matches.',
                onSave: _save,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Shared pieces for the Profile edit screens ────────────────────────────

class EditScaffold extends StatelessWidget {
  const EditScaffold({required this.title, required this.body, super.key});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) => _EditScaffold(title: title, body: body);
}

class _EditScaffold extends StatelessWidget {
  const _EditScaffold({required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      appBar: AppBar(
        backgroundColor: context.appColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: context.appColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.appColors.textPrimary,
          ),
        ),
      ),
      body: body,
    );
  }
}

class SaveBar extends StatelessWidget {
  const SaveBar({
    required this.saving,
    required this.note,
    required this.onSave,
    this.enabled = true,
    super.key,
  });

  final bool saving;
  final bool enabled;
  final String note;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => _SaveBar(
    saving: saving,
    enabled: enabled,
    note: note,
    onSave: onSave,
  );
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.saving,
    required this.note,
    required this.onSave,
    this.enabled = true,
  });

  final bool saving;
  final bool enabled;
  final String note;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            AppPrimaryButton(
              label: saving ? 'Saving & re-matching...' : 'Save changes',
              onPressed: saving || !enabled ? null : onSave,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              note,
              style: AppTextStyles.caption(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          text,
          style: AppTextStyles.body(context),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
