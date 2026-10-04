import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/card_over_hero_layout.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';import '../cubit/admin_login_cubit.dart';
import '../data/repositories/admin_repository_impl.dart';
import '../domain/repositories/admin_repository.dart';
import 'admin_shell.dart';

/// Admin sign-in — card-over-hero like the tenant/owner auth screens, but
/// with a dark ink hero to signal the elevated role. No create-account link:
/// admin accounts are provisioned manually (see CLAUDE.md rule 8).
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({this.repository, super.key});

  /// Injected in tests / previews; defaults to the Firebase implementation.
  final AdminRepository? repository;

  static const routeName = '/admin/login';

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  late final AdminRepository _repo = widget.repository ?? AdminRepositoryImpl();
  late final AdminLoginCubit _cubit = AdminLoginCubit(_repo);

  bool get _canSubmit =>
      _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _login() =>
      _cubit.signIn(_emailController.text, _passwordController.text);

  void _onState(BuildContext context, AdminLoginState state) {
    if (state.isSignedIn) {
      // Re-resolve AuthBloc so it reflects the admin session.
      context.read<AuthBloc>().add(const AuthCheckRequested());
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => AdminShell(repository: _repo)),
      );
    } else if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage!),
          backgroundColor: context.appColors.ink,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminLoginCubit>.value(
      value: _cubit,
      child: BlocConsumer<AdminLoginCubit, AdminLoginState>(
        listener: _onState,
        builder: _buildForm,
      ),
    );
  }

  Widget _buildForm(BuildContext context, AdminLoginState login) {
    return CardOverHeroLayout(
      cardHeightFraction: 0.62,
      hero: const _AdminHero(),
      cardContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sign in', style: AppTextStyles.title(context)),
          SizedBox(height: 4),
          Text(
            'Authorized personnel only.',
            style: AppTextStyles.body(
              context,
            ).copyWith(color: context.appColors.textSecondary),
          ),
          SizedBox(height: AppSpacing.lg),
          LabelledField(
            label: 'ADMIN EMAIL',
            child: AppTextField(
              controller: _emailController,
              hintText: 'admin@rentease.ph',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icon(
                Icons.mail_outline_rounded,
                size: 18,
                color: context.appColors.hint,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          LabelledField(
            label: 'PASSWORD',
            child: AppTextField(
              controller: _passwordController,
              hintText: 'Enter password',
              obscureText: _obscure,
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: context.appColors.hint,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: context.appColors.hint,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          login.isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                )
              : AppButton(
                  label: 'Sign in',
                  onPressed: _canSubmit ? _login : null,
                ),
          SizedBox(height: AppSpacing.md),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 13,
                  color: context.appColors.textSecondary,
                ),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Admin accounts are provisioned by the platform team.',
                    style: AppTextStyles.caption(context),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// Dark ink hero with the brand mark and an admin badge chip.
class _AdminHero extends StatelessWidget {
  const _AdminHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appColors.ink,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppColors.onInk,
                  size: 30,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Text(
                    'RentEase',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppColors.onInk,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppRadii.chip),
                      border: Border.all(color: AppColors.accent, width: 0.5),
                    ),
                    child: Text(
                      'ADMIN',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                'Platform verification, users, and listings.',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  color: context.appColors.indicatorInactive,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
