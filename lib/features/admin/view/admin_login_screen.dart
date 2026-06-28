import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
=======

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';
import 'pending_verifications_screen.dart';
>>>>>>> Stashed changes

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

<<<<<<< Updated upstream
=======
  static const routeName = '/admin/login';

>>>>>>> Stashed changes
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
<<<<<<< Updated upstream
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminNavy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                const Icon(Icons.home_work_rounded, color: Colors.white, size: 48),
                const SizedBox(height: 8),
                const Text(
                  'RentEase',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Admin access',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _AdminTextField(
                  controller: emailController,
                  hint: 'Admin email',
                ),
                const SizedBox(height: 16),
                _AdminTextField(
                  controller: passwordController,
                  hint: 'Password',
                  obscure: true,
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Log in',
                  color: AppColors.primaryMid,
                  onPressed: () {},
                ),
                const SizedBox(height: 24),
                Text(
                  'Admin credentials are managed internally.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
=======
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  bool get _canSubmit =>
      _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const PendingVerificationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppSpacing.xl),
              Text(
                'RentEase',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onInk,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Admin Panel',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  color: context.appColors.indicatorInactive,
                ),
              ),
              const Spacer(),
              Text(
                'Sign in',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onInk,
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              _DarkTextField(
                controller: _emailController,
                hintText: 'Admin email',
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: AppSpacing.sm),
              _DarkTextField(
                controller: _passwordController,
                hintText: 'Password',
                obscureText: _obscure,
                onChanged: (_) => setState(() {}),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: context.appColors.indicatorInactive,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              _loading
                  ? Center(child: CircularProgressIndicator(color: AppColors.accent))
                  : AppButton(
                      label: 'Sign in',
                      onPressed: _canSubmit ? _login : null,
                    ),
              const Spacer(),
            ],
>>>>>>> Stashed changes
          ),
        ),
      ),
    );
  }
}

<<<<<<< Updated upstream
class _AdminTextField extends StatelessWidget {
  const _AdminTextField({
    required this.controller,
    required this.hint,
    this.obscure = false,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
=======
class _DarkTextField extends StatelessWidget {
  const _DarkTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
>>>>>>> Stashed changes

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
<<<<<<< Updated upstream
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        fillColor: Colors.white.withValues(alpha: 0.1),
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
        contentPadding: const EdgeInsets.all(16),
=======
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      style: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 14,
        color: AppColors.onInk,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 14,
          color: context.appColors.indicatorInactive,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: context.appColors.textPrimary.withValues(alpha: 0.12),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: BorderSide(color: context.appColors.textSecondary, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: BorderSide(color: AppColors.accent, width: 1.5),
        ),
>>>>>>> Stashed changes
      ),
    );
  }
}
