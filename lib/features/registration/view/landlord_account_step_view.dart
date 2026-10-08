import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/input_formatters.dart';
import '../../../core/utils/validators.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../cubit/registration_cubit.dart';
import '../widgets/form_step_layout.dart';
import '../widgets/gender_select_field.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/password_requirements.dart';
import '../widgets/terms_agreement_field.dart';

/// Landlord step 1/4 — "Create your account".
class LandlordAccountStepView extends StatefulWidget {
  const LandlordAccountStepView({super.key});

  @override
  State<LandlordAccountStepView> createState() =>
      _LandlordAccountStepViewState();
}

class _LandlordAccountStepViewState extends State<LandlordAccountStepView> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final ScrollController _scrollController;
  late final FocusNode _passwordFocusNode;

  bool _obscurePassword = true;
  String _password = '';
  bool _agreedToTerms = false;

  /// Only shown once the user has attempted to continue, so fields don't
  /// flash red before they've had a chance to type anything.
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    final data = context.read<RegistrationCubit>().state.data;
    _fullNameController = TextEditingController(text: data.fullName);
    _phoneController = TextEditingController(
      text: _formatInitialPhone(data.phone),
    );
    _scrollController = ScrollController();
    _passwordFocusNode = FocusNode();
    _agreedToTerms = data.ageConfirmed;

    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus && _password.isNotEmpty) {
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _scrollController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  String _formatInitialPhone(String raw) {
    if (raw.isEmpty) return '';
    String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('63') && digits.length > 2) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.length > 10) digits = digits.substring(0, 10);
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  String? _getPhoneError(String phoneStateValue, String controllerText) {
    final digits = controllerText.replaceAll(RegExp(r'\D'), '');
    if (digits.isNotEmpty && !digits.startsWith('9')) {
      return 'Invalid number (e.g., 9XX XXX XXXX)';
    }
    if (_showErrors) {
      return Validators.phone(phoneStateValue);
    }
    return null;
  }

  void _handleContinue(BuildContext context) {
    final data = context.read<RegistrationCubit>().state.data;
    if (!data.ageConfirmed || !_agreedToTerms) {
      setState(() => _showErrors = true);
      return;
    }
    final hasErrors = Validators.required(data.fullName, field: 'Full name') != null ||
        Validators.required(data.gender, field: 'Gender') != null ||
        Validators.email(data.email) != null ||
        Validators.phone(data.phone) != null ||
        Validators.password(data.password) != null;

    if (hasErrors) {
      setState(() => _showErrors = true);
      return;
    }

    // The landlord step collects one "full name" field; split it so the
    // `users/{uid}` doc still has separate firstName/lastName like the
    // tenant path.
    final parts = data.fullName.trim().split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    context.read<AuthBloc>().add(
          AuthSignUpRequested(
            email: data.email.trim(),
            password: data.password,
            firstName: firstName,
            lastName: lastName,
            gender: data.gender,
            phone: data.phone.trim(),
            ageConfirmed: data.ageConfirmed,
            role: 'owner',
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegistrationCubit>();
    final data = context.watch<RegistrationCubit>().state.data;
    final isLoading = context.select<AuthBloc, bool>(
      (bloc) => bloc.state is AuthLoading,
    );

    return FormStepLayout(
      title: 'Create your account',
      subtitle: 'Set up your landlord profile.',
      buttonLabel: isLoading ? 'Creating account…' : 'Continue',
      scrollController: _scrollController,
      onContinue: (_agreedToTerms && data.ageConfirmed && !isLoading)
          ? () => _handleContinue(context)
          : null,
      footer: TermsAgreementField(
        value: _agreedToTerms && data.ageConfirmed,
        onChanged: (v) {
          setState(() => _agreedToTerms = v);
          cubit.setAgeConfirmed(v);
        },
        errorText: _showErrors && (!_agreedToTerms || !data.ageConfirmed)
            ? 'Please confirm you are at least 18 and agree to the terms.'
            : null,
      ),
      fields: <Widget>[
        LabeledTextField(
          label: 'Full name',
          hint: 'John Smith',
          controller: _fullNameController,
          textCapitalization: TextCapitalization.words,
          inputFormatters: const [TitleCaseNameFormatter()],
          onChanged: cubit.updateFullName,
          errorText: _showErrors
              ? Validators.required(data.fullName, field: 'Full name')
              : null,
        ),
        GenderSelectField(
          value: data.gender,
          onChanged: cubit.updateGender,
          errorText: _showErrors
              ? Validators.required(data.gender, field: 'Gender')
              : null,
        ),
        LabeledTextField(
          label: 'Email',
          hint: 'john@email.com',
          keyboardType: TextInputType.emailAddress,
          onChanged: cubit.updateEmail,
          errorText: _showErrors ? Validators.email(data.email) : null,
        ),
        LabeledTextField(
          label: 'Phone number',
          hint: '912 345 6789',
          prefixText: '+63',
          alwaysShowPrefix: true,
          showPrefixDivider: true,
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: const [PhilippinePhoneInputFormatter()],
          onChanged: (v) {
            final digits = v.replaceAll(RegExp(r'\D'), '');
            cubit.updatePhone(digits.isEmpty ? '' : '+63 $v');
            setState(() {});
          },
          errorText: _getPhoneError(data.phone, _phoneController.text),
        ),
        LabeledTextField(
          label: 'Password',
          hint: '12–16 characters',
          focusNode: _passwordFocusNode,
          obscureText: _obscurePassword,
          onToggleObscure: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          onChanged: (v) {
            cubit.updatePassword(v);
            setState(() => _password = v);
            if (v.isNotEmpty) {
              _scrollToBottom();
            }
          },
          errorText: _showErrors ? Validators.password(data.password) : null,
        ),
        PasswordRequirements(password: _password),
      ],
    );
  }
}
