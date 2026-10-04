import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../activity/data/repositories/notification_repository_impl.dart';
import '../../auth/presentation/current_uid.dart';
import '../cubit/invite_cubit.dart';
import '../data/repositories/inquiry_repository_impl.dart';
import '../domain/services/inquiry_service.dart';
import '../model/invite_option.dart';

/// "Invite" for one compatible tenant (owner side).
///
/// CLAUDE.md rule 2: renders nothing at all (`SizedBox.shrink`, never a
/// disabled button) unless the owner can really invite — [bScore] is 1, a property is still available and the tenant has no
/// thread for it yet. The eligibility itself is decided by
/// [InquiryService.inviteOptions] and re-enforced by firestore.rules.
class InviteButton extends StatelessWidget {
  const InviteButton({
    required this.tenantId,
    required this.tenantName,
    required this.bScore,
    this.propertyId,
    this.compact = false,
    super.key,
  });

  final String tenantId;
  final String tenantName;
  final num bScore;

  /// Limits the invite to one property; null lets the owner pick among all
  /// their compatible, available ones.
  final String? propertyId;

  /// Small outline style for list cards; otherwise a full-width primary.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ownerId = currentUidOrNull(context);
    if (bScore != 1 || ownerId == null) return const SizedBox.shrink();

    final repository = InquiryRepositoryImpl();
    return BlocProvider(
      create: (_) => InviteCubit(
        ownerId: ownerId,
        tenantId: tenantId,
        propertyId: propertyId,
        service: InquiryService(
          repository: repository,
          notifications: NotificationRepositoryImpl(),
        ),
      ),
      child: _InviteView(tenantName: tenantName, compact: compact),
    );
  }
}

class _InviteView extends StatelessWidget {
  const _InviteView({required this.tenantName, required this.compact});

  final String tenantName;
  final bool compact;

  Future<void> _onTap(BuildContext context, InviteState state) async {
    final cubit = context.read<InviteCubit>();
    final options = state.options;
    final InviteOption? choice = options.length == 1
        ? options.first
        : await _pickProperty(context, options);
    if (choice == null) return;
    await cubit.send(choice);
  }

  Future<InviteOption?> _pickProperty(
    BuildContext context,
    List<InviteOption> options,
  ) {
    return showModalBottomSheet<InviteOption>(
      context: context,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invite $tenantName to which property?',
                style: AppTextStyles.title(sheetContext).copyWith(fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final option in options)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  minVerticalPadding: 12,
                  title: Text(
                    option.propertyTitle,
                    style: AppTextStyles.body(sheetContext),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.hint,
                  ),
                  onTap: () => Navigator.of(sheetContext).pop(option),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InviteCubit, InviteState>(
      listenWhen: (prev, curr) =>
          (curr.sentTitle != null && prev.sentTitle != curr.sentTitle) ||
          (curr.errorMessage != null && prev.errorMessage != curr.errorMessage),
      listener: (context, state) {
        final sent = state.sentTitle;
        final error = state.errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error ?? 'Invitation sent to $tenantName for $sent.',
            ),
            backgroundColor: error != null
                ? AppColors.destructive
                : context.appColors.ink,
          ),
        );
        context.read<InviteCubit>().clearMessages();
      },
      builder: (context, state) {
        // Absent, never disabled, when there is nothing to invite to.
        if (!state.canInvite) return const SizedBox.shrink();
        return AppButton(
          label: state.isSending ? 'Sending...' : 'Invite',
          variant: compact ? AppButtonVariant.outline : AppButtonVariant.primary,
          isSmall: compact,
          isFullWidth: !compact,
          onPressed: state.isSending ? null : () => _onTap(context, state),
        );
      },
    );
  }
}
