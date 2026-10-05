import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/screens/privacy_notice_screen.dart';
import '../../data/repositories/account_deletion_repository_impl.dart';
import '../../domain/services/account_deletion_service.dart';
import '../cubit/delete_account_cubit.dart';

/// Plain description of what "Delete my account" removes and keeps.
class DeleteAccountContent {
  const DeleteAccountContent._();

  static const String confirmedMessage = 'Your account has been deleted.';

  static const List<String> tenantDeleted = <String>[
    'Your profile, preferences, map pin and ranking priorities',
    'Your saved listings, matches and notifications',
    'Your email, phone and emergency contact',
    'Your sign-in account',
  ];

  static const List<String> ownerDeleted = <String>[
    'Your profile, verification record and document links',
    'Your property listings and their rooms (open inquiries are closed)',
    'Your notifications, email and phone',
    'Your sign-in account',
  ];

  static const List<String> kept = <String>[
    'Inquiry and chat records you shared with other users stay for them, '
        'with your name shown as "Deleted user"',
    'Ratings you gave or received',
    'Images you already uploaded (photos and verification documents) stay on '
        'Cloudinary until we remove them manually on request',
  ];
}

/// Profile > Delete my account. Re-authenticates with the current password,
/// requires typing DELETE, then runs the deletion and returns to sign-in.
class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({
    required this.uid,
    required this.isOwner,
    this.cubit,
    super.key,
  });

  final String uid;
  final bool isOwner;

  /// Injectable for tests; defaults to the Firebase-backed service.
  final DeleteAccountCubit? cubit;

  /// Pushes the screen for the signed-in user.
  static Future<void> open(
    BuildContext context, {
    required String uid,
    required bool isOwner,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DeleteAccountScreen(uid: uid, isOwner: isOwner),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DeleteAccountCubit>(
      create: (_) =>
          cubit ??
          DeleteAccountCubit(
            uid: uid,
            isOwner: isOwner,
            service: AccountDeletionService(
              repository: AccountDeletionRepositoryImpl(),
            ),
          ),
      child: _DeleteAccountView(isOwner: isOwner),
    );
  }
}

class _DeleteAccountView extends StatefulWidget {
  const _DeleteAccountView({required this.isOwner});

  final bool isOwner;

  @override
  State<_DeleteAccountView> createState() => _DeleteAccountViewState();
}

class _DeleteAccountViewState extends State<_DeleteAccountView> {
  final _password = TextEditingController();
  final _typed = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    _typed.dispose();
    super.dispose();
  }

  void _onState(BuildContext context, DeleteAccountState state) {
    if (state.status != DeleteAccountStatus.success) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    context.read<AuthBloc>().add(const AuthSignOutRequested());
    messenger.showSnackBar(
      const SnackBar(content: Text(DeleteAccountContent.confirmedMessage)),
    );
    navigator.pushNamedAndRemoveUntil(AppRouter.signIn, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final deleted = widget.isOwner
        ? DeleteAccountContent.ownerDeleted
        : DeleteAccountContent.tenantDeleted;

    return Scaffold(
      backgroundColor: context.appColors.surface,
      appBar: AppBar(
        backgroundColor: context.appColors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.appColors.textPrimary),
        title: Text(
          'Delete my account',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.appColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<DeleteAccountCubit, DeleteAccountState>(
          listener: _onState,
          builder: (context, state) {
            final busy = state.isDeleting;
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                const SizedBox(height: AppSpacing.md),
                Text(
                  'This permanently deletes your account and cannot be undone.',
                  style: AppTextStyles.body(context),
                ),
                const SizedBox(height: AppSpacing.lg),
                _Bullets(title: 'What is deleted', items: deleted),
                _Bullets(title: 'What stays', items: DeleteAccountContent.kept),
                GestureDetector(
                  onTap: () => PrivacyNoticeScreen.open(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      'Read the Privacy Notice',
                      style: AppTextStyles.link(context),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LabelledField(
                  label: 'Current password',
                  child: AppTextField(
                    controller: _password,
                    hintText: 'Enter your password',
                    obscureText: _obscure,
                    enabled: !busy,
                    onChanged: (_) => setState(() {}),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: context.appColors.hint,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LabelledField(
                  label: 'Type ${DeleteAccountCubit.confirmWord} to confirm',
                  child: AppTextField(
                    controller: _typed,
                    hintText: DeleteAccountCubit.confirmWord,
                    enabled: !busy,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    state.errorMessage!,
                    style: AppTextStyles.body(
                      context,
                    ).copyWith(color: AppColors.destructive),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: busy ? 'Deleting…' : 'Delete my account',
                  isDanger: true,
                  onPressed:
                      (!busy &&
                          DeleteAccountCubit.canSubmit(
                            password: _password.text,
                            typed: _typed.text,
                          ))
                      ? () => context.read<DeleteAccountCubit>().delete(
                          password: _password.text,
                          typed: _typed.text,
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Cancel',
                  isOutlined: true,
                  onPressed: busy ? null : () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Bullets extends StatelessWidget {
  const _Bullets({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: AppTextStyles.body(context)),
                  Expanded(
                    child: Text(item, style: AppTextStyles.body(context)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
