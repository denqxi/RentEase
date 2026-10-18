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
  const AccountSecurityScreen({super.key});

  static const Color bgIceBlue = Colors.white;
  static const Color primaryCyan = Color(0xFF0094D9);
  static const Color textDarkNavy = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);
  static const Color dangerRed = Color(0xFFE11D48);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0C2340).withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF0C2340).withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
      ];

  /// Safely forwards [LandlordHomeCubit] from the calling route if available.
  static Future<void> open(BuildContext context) {
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
                child: const AccountSecurityScreen(),
              )
            : const AccountSecurityScreen(),
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _ChangePasswordBottomSheet(),
    );
  }

  void _showDeleteAccountSheet(BuildContext context, int listingsCount) {
    final uid = currentUidOrNull(context);
    if (uid == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider<DeleteAccountCubit>(
        create: (_) => DeleteAccountCubit(
          uid: uid,
          isOwner: true,
          service: AccountDeletionService(
            repository: AccountDeletionRepositoryImpl(),
          ),
        ),
        child: _DeleteAccountBottomSheet(listingsCount: listingsCount),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppThemeCubit>().state;
    final bgColor = isDark ? context.appColors.surface : bgIceBlue;
    final cardColor = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final textColor = isDark ? Colors.white : textDarkNavy;

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
            color: isDark ? const Color(0xFF2A2A36) : const Color(0xFFF1F5F9),
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
                      ? const Color(0xFF2A2A36)
                      : const Color(0xFFF1F5F9),
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
              _buildSectionHeader('SECURITY', textMuted),
              const SizedBox(height: 10),
              _buildCard(
                cardColor: cardColor,
                isDark: isDark,
                child: _buildActionRow(
                  icon: Icons.vpn_key_outlined,
                  iconBg: const Color(0xFFEBF6FD),
                  iconColor: primaryCyan,
                  title: 'Change password',
                  textColor: textColor,
                  subtitle: 'Update your account login password',
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: textMutedLight,
                    size: 20,
                  ),
                  onTap: () => _showChangePasswordSheet(context),
                ),
              ),

              const SizedBox(height: 24),

              // LEGAL SECTION
              _buildSectionHeader('LEGAL', textMuted),
              const SizedBox(height: 10),
              _buildCard(
                cardColor: cardColor,
                isDark: isDark,
                child: Column(
                  children: [
                    _buildActionRow(
                      icon: Icons.verified_user_outlined,
                      iconBg: const Color(0xFFEBF6FD),
                      iconColor: primaryCyan,
                      title: 'Privacy Notice',
                      textColor: textColor,
                      trailing: const Icon(
                        Icons.open_in_new_rounded,
                        color: textMutedLight,
                        size: 18,
                      ),
                      onTap: () => PrivacyNoticeScreen.open(context),
                    ),
                    Divider(
                      height: 1,
                      color: isDark
                          ? const Color(0xFF2A2A36)
                          : const Color(0xFFF1F5F9),
                    ),
                    _buildActionRow(
                      icon: Icons.description_outlined,
                      iconBg: const Color(0xFFEBF6FD),
                      iconColor: primaryCyan,
                      title: 'Terms & Conditions',
                      textColor: textColor,
                      trailing: const Icon(
                        Icons.open_in_new_rounded,
                        color: textMutedLight,
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
              _buildSectionHeader('DANGER ZONE', dangerRed),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A1C20)
                      : const Color(0xFFFFFBFB),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? dangerRed.withValues(alpha: 0.4)
                        : const Color(0xFFFECDD3),
                    width: 1,
                  ),
                  boxShadow: cardShadow,
                ),
                child: _buildActionRow(
                  icon: Icons.delete_outline_rounded,
                  iconBg: const Color(0xFFFFF0F2),
                  iconColor: dangerRed,
                  title: 'Delete my account',
                  titleColor: dangerRed,
                  textColor: textColor,
                  subtitle: 'Permanent erasure of owner records',
                  subtitleColor: dangerRed.withValues(alpha: 0.75),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: dangerRed,
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
          color: isDark ? const Color(0xFF2A2A36) : const Color(0xFFE2E8F0),
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
                        color: subtitleColor ?? textMuted,
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
    const primaryCyan = AccountSecurityScreen.primaryCyan;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
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
                  color: const Color(0xFFCBD5E1),
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
                color: Color(0xFF14213D),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enter your current password and pick a new one.',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: Color(0xFF64748B),
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
                  color: Color(0xFFEF4444),
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
                  backgroundColor: primaryCyan,
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
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Update password',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              color: Color(0xFF0F172A),
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
                  color: const Color(0xFF94A3B8),
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
  const _DeleteAccountBottomSheet({required this.listingsCount});

  final int listingsCount;

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
    const dangerRed = AccountSecurityScreen.dangerRed;

    return BlocConsumer<DeleteAccountCubit, DeleteAccountState>(
      listener: _onState,
      builder: (context, state) {
        final busy = state.isDeleting;
        final isConfirmed = _confirmController.text.trim() == 'DELETE';
        final hasPassword = _passwordController.text.isNotEmpty;
        final canDelete = !busy && isConfirmed && hasPassword;

        return Container(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
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
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const SizedBox(height: 20),

                // Warning Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: dangerRed,
                      size: 26,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Title
                const Text(
                  'Delete Landlord Account?',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF14213D),
                  ),
                ),

                const SizedBox(height: 6),

                // Subtitle
                Text(
                  'This permanently erases your ${widget.listingsCount} listings, verified status, and tenant communications.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 20),

                // Password input for backend re-authentication
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Enter current password:',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enabled: !busy,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      hintStyle: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
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
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Type DELETE prompt
                Align(
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        color: Color(0xFF334155),
                      ),
                      children: [
                        TextSpan(text: 'Type '),
                        TextSpan(
                          text: 'DELETE',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: dangerRed,
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFECDD3),
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
                      color: Color(0xFF0F172A),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'DELETE',
                      hintStyle: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        color: Color(0xFFCBD5E1),
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
                      color: dangerRed,
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
                            backgroundColor: const Color(0xFFF1F5F9),
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
                              color: Color(0xFF1E293B),
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
                                    password: _passwordController.text,
                                    typed: _confirmController.text,
                                  )
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF43F5E),
                            disabledBackgroundColor:
                                const Color(0xFFFDA4AF),
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
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Delete forever',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
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
