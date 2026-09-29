import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/phase_badge.dart';
import '../../auth/presentation/current_uid.dart';
import '../cubit/inquiry_thread_cubit.dart';
import '../data/repositories/inquiry_repository_impl.dart';
import '../domain/services/inquiry_service.dart';
import '../model/inquiry_summary.dart';
import '../widgets/inquiry_chat_view.dart';
import '../widgets/owner_phase1_view.dart';
import '../widgets/tenant_phase1_view.dart';

/// One inquiry, for either side. Follows the inquiry live and renders the
/// view for the current stage — so the tenant's locked Phase 1 screen
/// becomes the chat the moment the owner accepts, with no navigation.
class InquiryThreadScreen extends StatelessWidget {
  const InquiryThreadScreen({
    required this.inquiryId,
    required this.isOwner,
    super.key,
  });

  final String inquiryId;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final uid = currentUidOrNull(context);
    if (uid == null) {
      return const _ThreadScaffold(
        title: 'Inquiry',
        body: _CenteredMessage('Sign in to view this inquiry.'),
      );
    }
    final repository = InquiryRepositoryImpl();
    return BlocProvider(
      create: (_) => InquiryThreadCubit(
        inquiryId: inquiryId,
        uid: uid,
        repository: repository,
        service: InquiryService(repository: repository),
      ),
      child: _ThreadView(isOwner: isOwner),
    );
  }
}

class _ThreadView extends StatelessWidget {
  const _ThreadView({required this.isOwner});

  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InquiryThreadCubit, InquiryThreadState>(
      listenWhen: (prev, curr) =>
          curr.errorMessage != null && prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        // Load failures render in the body; action failures (accept, send,
        // …) keep the thread on screen and surface as a snackbar.
        if (state.inquiry == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: AppColors.destructive,
          ),
        );
        context.read<InquiryThreadCubit>().clearError();
      },
      builder: (context, state) {
        final inquiry = state.inquiry;
        if (inquiry == null) {
          return _ThreadScaffold(
            title: 'Inquiry',
            body: state.errorMessage != null
                ? _CenteredMessage(state.errorMessage!)
                : const Center(child: CircularProgressIndicator()),
          );
        }

        final counterpartName = isOwner
            ? fullNameOf(state.tenant, fallback: 'Tenant')
            : fullNameOf(state.owner, fallback: 'Property owner');
        final propertyTitle = state.property?.title ?? 'Listing';

        if (inquiry.stage == 2) {
          return InquiryChatView(
            isOwner: isOwner,
            counterpartName: counterpartName,
            propertyTitle: propertyTitle,
          );
        }

        return _ThreadScaffold(
          title: isOwner ? 'New inquiry' : propertyTitle,
          phase: 1,
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : isOwner
              ? const OwnerPhase1View()
              : const TenantPhase1View(),
        );
      },
    );
  }
}

class _ThreadScaffold extends StatelessWidget {
  const _ThreadScaffold({required this.title, required this.body, this.phase});

  final String title;
  final Widget body;
  final int? phase;

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
        actions: [
          if (phase != null) ...[
            Center(child: PhaseBadge(phase: phase!)),
            SizedBox(width: AppSpacing.md),
          ],
        ],
      ),
      body: body,
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage(this.text);

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
