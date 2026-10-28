import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/cubit/app_theme_cubit.dart';
import '../../../core/router/app_router.dart';
import '../../account_deletion/data/repositories/account_deletion_repository_impl.dart';
import '../../account_deletion/domain/services/account_deletion_service.dart';
import '../../account_deletion/presentation/cubit/delete_account_cubit.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/current_uid.dart';
import '../../auth/presentation/screens/privacy_notice_screen.dart';
import '../../auth/presentation/screens/terms_and_conditions_screen.dart';
import '../../landlord_home/cubit/landlord_home_cubit.dart';

class AccountSecurityScreen extends StatelessWidget {
  const AccountSecurityScreen({super.key, this.isOwner = true});

  final bool isOwner;


  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
      ];

  /// Safely forwards [LandlordHomeCubit] from the calling route if available.
  static Future<void> open(BuildContext context, {bool isOwner = true}) {
    LandlordHomeCubit? cubit;
    try {
      cubit = context.read<LandlordHomeCubit>();
    } catch (_) {
      cubit = null;
    }

    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => cubit != null
            ? BlocProvider<LandlordHomeCubit>.value(
                value: cubit,
                child: AccountSecurityScreen(isOwner: isOwner),
              )
            : AccountSecurityScreen(isOwner: isOwner),
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (ctx) => const _ChangePasswordBottomSheet(),
    );
  }

  void _showDeleteAccountSheet(BuildContext context, int listingsCount) {
    final uid = currentUidOrNull(context);
    if (uid == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (ctx) => BlocProvider<DeleteAccountCubit>(
        create: (_) => DeleteAccountCubit(
          uid: uid,
          isOwner: isOwner,
          service: AccountDeletionService(
            repository: AccountDeletionRepositoryImpl(),
          ),
        ),
        child: _DeleteAccountBottomSheet(
          listingsCount: listingsCount,
          isOwner: isOwner,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppThemeCubit>().state;
    final bgColor = isDark ? context.appColors.surface : AppColors.surface;
    final cardColor = isDark ? AppColors.darkCard : AppColors.surface;
    final textColor = isDark ? AppColors.surface : AppColors.slate900;

    int listingsCount = 4;
    try {
      final landlordState = context.watch<LandlordHomeCubit>().state;
      if (landlordState.properties.isNotEmpty) {
        listingsCount = landlordState.properties.length;
      }
    } catch (_) {
      // Fallback when opened outside LandlordShell (e.g. preview)
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leadingWidth: 56,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? AppColors.darkField : AppColors.fieldFill,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkField
                      : AppColors.fieldFill,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: textColor,
                  size: 19,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Account & security',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SECURITY SECTION
              _buildSectionHeader('SECURITY', AppColors.slate500),
              const SizedBox(height: 10),
              _buildCard(
                cardColor: cardColor,
                isDark: isDark,
                child: _buildActionRow(
                  icon: Icons.vpn_key_outlined,
                  iconBg: AppColors.tenantFillBlue,
                  iconColor: AppColors.primaryCyan,
                  title: 'Change password',
                  textColor: textColor,
                  subtitle: 'Update your account login password',
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.slate400,
                    size: 20,
                  ),
                  onTap: () => _showChangePasswordSheet(context),
                ),
              ),

              const SizedBox(height: 24),

              // LEGAL SECTION
              _buildSectionHeader('LEGAL', AppColors.slate500),
              const SizedBox(height: 10),
              _buildCard(
                cardColor: cardColor,
                isDark: isDark,
                child: Column(
                  children: [
                    _buildActionRow(
                      icon: Icons.verified_user_outlined,
                      iconBg: AppColors.tenantFillBlue,
                      iconColor: AppColors.primaryCyan,
                      title: 'Privacy Notice',
                      textColor: textColor,
                      trailing: const Icon(
                        Icons.open_in_new_rounded,
                        color: AppColors.slate400,
                        size: 18,
                      ),
                      onTap: () => PrivacyNoticeScreen.open(context),
                    ),
                    Divider(
                      height: 1,
                      color: isDark
                          ? AppColors.darkField
                          : AppColors.fieldFill,
                    ),
                    _buildActionRow(
                      icon: Icons.description_outlined,
                      iconBg: AppColors.tenantFillBlue,
                      iconColor: AppColors.primaryCyan,
                      title: 'Terms & Conditions',
                      textColor: textColor,
                      trailing: const Icon(
                        Icons.open_in_new_rounded,
                        color: AppColors.slate400,
                        size: 18,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TermsAndConditionsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // DANGER ZONE
              _buildSectionHeader('DANGER ZONE', AppColors.rose600),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCard
                      : AppColors.redFill50,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? AppColors.rose600.withValues(alpha: 0.4)
                        : AppColors.redBorder200,
                    width: 1,
                  ),
                  boxShadow: cardShadow,
                ),
                child: _buildActionRow(
                  icon: Icons.delete_outline_rounded,
                  iconBg: AppColors.redFill50,
                  iconColor: AppColors.rose600,
                  title: 'Delete my account',
                  titleColor: AppColors.rose600,
                  textColor: textColor,
                  subtitle: 'Permanent erasure of owner records',
                  subtitleColor: AppColors.rose600.withValues(alpha: 0.75),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.rose600,
                    size: 20,
                  ),
                  onTap: () => _showDeleteAccountSheet(context, listingsCount),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildCard({
    required Color cardColor,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkField : AppColors.slate200,
          width: 1,
        ),
        boxShadow: cardShadow,
      ),
      child: child,
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required Color textColor,
    Color? titleColor,
    String? subtitle,
    Color? subtitleColor,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: subtitleColor ?? AppColors.slate500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

// Change Password Bottom Sheet
class _ChangePasswordBottomSheet extends StatefulWidget {
  const _ChangePasswordBottomSheet();

  @override
  State<_ChangePasswordBottomSheet> createState() =>
      _ChangePasswordBottomSheetState();
}

class _ChangePasswordBottomSheetState
    extends State<_ChangePasswordBottomSheet> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isUpdating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final current = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (current.isEmpty) {
      setState(() => _errorMessage = 'Enter your current password.');
      return;
    }
    if (newPass.length < 8) {
      setState(
        () => _errorMessage = 'New password must be at least 8 characters.',
      );
      return;
    }
    if (newPass != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('User session not found.');
      }

      // Re-authenticate
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: current,
      );
      await user.reauthenticateWithCredential(cred);

      // Update password
      await user.updatePassword(newPass);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
          _errorMessage = e.code == 'wrong-password'
              ? 'Current password is incorrect.'
              : e.message ?? 'Failed to update password.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
          _errorMessage = 'An error occurred. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Change password',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enter your current password and pick a new one.',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: AppColors.slate500,
              ),
            ),
            const SizedBox(height: 18),

            // Current Password
            _buildField(
              label: 'Current password',
              controller: _currentPasswordController,
              obscure: _obscureCurrent,
              onToggleObscure: () =>
                  setState(() => _obscureCurrent = !_obscureCurrent),
            ),
            const SizedBox(height: 12),

            // New Password
            _buildField(
              label: 'New password',
              controller: _newPasswordController,
              obscure: _obscureNew,
              onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
            ),
            const SizedBox(height: 12),

            // Confirm New Password
            _buildField(
              label: 'Confirm new password',
              controller: _confirmPasswordController,
              obscure: _obscureConfirm,
              onToggleObscure: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12.5,
                  color: AppColors.destructive,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryCyan,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isUpdating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.surface,
                        ),
                      )
                    : const Text(
                        'Update password',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.surface,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.slate700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.slate200),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              color: AppColors.slate900,
            ),
            decoration: InputDecoration(
              hintText: '••••••••',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              border: InputBorder.none,
              suffixIcon: IconButton(
                onPressed: onToggleObscure,
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: AppColors.slate400,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Delete Account Bottom Sheet (Matching Image 5)
class _DeleteAccountBottomSheet extends StatefulWidget {
  const _DeleteAccountBottomSheet({
    required this.listingsCount,
    this.isOwner = true,
  });

  final int listingsCount;
  final bool isOwner;

  @override
  State<_DeleteAccountBottomSheet> createState() =>
      _DeleteAccountBottomSheetState();
}

class _DeleteAccountBottomSheetState extends State<_DeleteAccountBottomSheet> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onState(BuildContext context, DeleteAccountState state) {
    if (state.status != DeleteAccountStatus.success) return;
    Navigator.of(context).pop(); // dismiss sheet
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    context.read<AuthBloc>().add(const AuthSignOutRequested());
    messenger.showSnackBar(
      const SnackBar(content: Text('Your account has been deleted.')),
    );
    navigator.pushNamedAndRemoveUntil(AppRouter.signIn, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeleteAccountCubit, DeleteAccountState>(
      listener: _onState,
      builder: (context, state) {
        final isGoogle = context.read<DeleteAccountCubit>().isGoogleUser;
        final busy = state.isDeleting;
        final isConfirmed = _confirmController.text.trim() == 'DELETE';
        final hasPassword = _passwordController.text.isNotEmpty;
        final canDelete = !busy && isConfirmed && (isGoogle || hasPassword);

        return Container(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.slate300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const SizedBox(height: 20),

                // Warning Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.redFill50,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.rose600,
                      size: 26,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Title
                Text(
                  widget.isOwner
                      ? 'Delete Landlord Account?'
                      : 'Delete Tenant Account?',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),

                const SizedBox(height: 6),

                // Subtitle
                Text(
                  widget.isOwner
                      ? 'This permanently erases your ${widget.listingsCount} listings, verified status, and tenant communications.'
                      : 'This permanently erases your saved properties, inquiries, and application history.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    color: AppColors.slate500,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 20),

                if (!isGoogle) ...[
                  // Password input for backend re-authentication
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Enter current password:',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      enabled: !busy,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        color: AppColors.slate900,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        hintStyle: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          color: AppColors.slate400,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                            color: AppColors.slate400,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.fieldFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Signed in with Google. You will be prompted to re-authenticate with Google upon confirmation.',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12.5,
                              color: AppColors.slate600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Type DELETE prompt
                Align(
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        color: AppColors.slate700,
                      ),
                      children: [
                        TextSpan(text: 'Type '),
                        TextSpan(
                          text: 'DELETE',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.rose600,
                          ),
                        ),
                        TextSpan(text: ' to confirm:'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // DELETE text field
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.redBorder200,
                      width: 1.2,
                    ),
                  ),
                  child: TextField(
                    controller: _confirmController,
                    enabled: !busy,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate900,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'DELETE',
                      hintStyle: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        color: AppColors.slate300,
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                if (state.errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    state.errorMessage!,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12.5,
                      color: AppColors.rose600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Two buttons row
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: TextButton(
                          onPressed:
                              busy ? null : () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.fieldFill,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: canDelete
                              ? () => context.read<DeleteAccountCubit>().delete(
                                    password: isGoogle ? null : _passwordController.text,
                                    typed: _confirmController.text,
                                  )
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.rose500,
                            disabledBackgroundColor:
                                AppColors.rose300,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.surface,
                                  ),
                                )
                              : const Text(
                                  'Delete forever',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.surface,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
