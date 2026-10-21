import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/firestore/models/models.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../landlord_home/view/tenant_detail_screen.dart';
import '../../landlord_home/view/owner_detail_screen.dart';
import '../../owner/model/compatible_tenant.dart';
import '../../activity/cubit/activity_cubit.dart';
import '../../activity/data/repositories/notification_repository_impl.dart';
import '../../auth/presentation/current_uid.dart';
import '../cubit/inquiry_thread_cubit.dart';
import '../data/repositories/inquiry_repository_impl.dart';
import '../domain/services/inquiry_service.dart';
import '../model/inquiry_summary.dart';
import '../widgets/inquiry_chat_view.dart';
import '../widgets/owner_invite_view.dart';
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
    try {
      context.read<ActivityCubit>().markInquiryRead(inquiryId);
    } catch (_) {}
    final repository = InquiryRepositoryImpl();
    return BlocProvider(
      create: (_) => InquiryThreadCubit(
        inquiryId: inquiryId,
        uid: uid,
        repository: repository,
        service: InquiryService(
          repository: repository,
          notifications: NotificationRepositoryImpl(),
        ),
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
                : const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
          );
        }

        final currentUid = currentUidOrNull(context);
        final effectiveIsOwner = (currentUid != null && inquiry.ownerId == currentUid)
            ? true
            : (currentUid != null && inquiry.tenantId == currentUid)
                ? false
                : isOwner;

        final counterpartName = effectiveIsOwner
            ? fullNameOf(
                state.tenant,
                fallback: 'Tenant',
                loaded: !state.isLoading,
              )
            : fullNameOf(
                state.owner,
                fallback: 'Property owner',
                loaded: !state.isLoading,
              );
        final propertyTitle = state.property?.title ?? 'Listing';

        if (inquiry.stage == 2) {
          return InquiryChatView(
            isOwner: effectiveIsOwner,
            counterpartName: counterpartName,
            propertyTitle: propertyTitle,
          );
        }

        return _ThreadScaffold(
          title: counterpartName,
          subtitle: propertyTitle,
          counterpartName: counterpartName,
          property: state.property,
          onTapHeader: () {
            if (effectiveIsOwner) {
              final tenant = state.tenant;
              final profile = state.tenantProfile;
              final tenantId = tenant?.userId ?? inquiry.tenantId;
              final name = fullNameOf(
                tenant,
                fallback: counterpartName,
                loaded: !state.isLoading,
              );
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TenantDetailScreen(
                    tenant: CompatibleTenant(
                      matchId: inquiry.inquiryId,
                      tenantId: tenantId,
                      name: name,
                      gender: tenant?.gender ?? '',
                      maxBudget: profile?.maxBudget ?? 0,
                      bScore: 1,
                      occupation: profile?.occupation,
                      school: profile?.school,
                    ),
                    user: tenant,
                    profile: profile,
                    phone: state.counterpartPhone,
                    showInviteButton: false,
                  ),
                ),
              );
            } else {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => OwnerDetailScreen(
                    owner: state.owner,
                    property: state.property,
                    fallbackName: counterpartName,
                    phone: state.counterpartPhone,
                    isVerified: state.ownerVerified,
                  ),
                ),
              );
            }
          },
          body: state.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : effectiveIsOwner
              ? (InquiryService.isInvite(inquiry)
                    ? const OwnerInviteView()
                    : const OwnerPhase1View())
              : const TenantPhase1View(),
        );
      },
    );
  }
}

class _ThreadScaffold extends StatelessWidget {
  const _ThreadScaffold({
    required this.title,
    required this.body,
    this.subtitle,
    this.counterpartName,
    this.property,
    this.onTapHeader,
  });

  final String title;
  final String? subtitle;
  final String? counterpartName;
  final PropertyDoc? property;
  final Widget body;
  final VoidCallback? onTapHeader;

  @override
  Widget build(BuildContext context) {
    final hasHeaderDetails = counterpartName != null && subtitle != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Soft Top Sky-Blue Gradient Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 210,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      const Color(0xFFD8F3FE).withValues(alpha: 0.7),
                      const Color(0xFFEFF9FF).withValues(alpha: 0.45),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Top Header Bar ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 14, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF0F172A,
                                ).withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.chevron_left_rounded,
                            color: Color(0xFF0F172A),
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: onTapHeader,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                if (hasHeaderDetails) ...[
                                  Container(
                                    width: 42,
                                    height: 42,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEDF2F7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      InquirySummary.initialsOf(counterpartName!),
                                      style: const TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        title,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      if (subtitle != null) ...[
                                        const SizedBox(height: 1),
                                        Text(
                                          subtitle!,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.more_vert_rounded,
                        color: Color(0xFF0F172A),
                        size: 21,
                      ),
                    ],
                  ),
                ),

                // ── Pinned Property Banner Card ──────────────────────────
                if (hasHeaderDetails)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: ThreadPropertyBannerCard(
                      property: property,
                      fallbackTitle: subtitle!,
                    ),
                  ),

                // ── Thread Body ──────────────────────────────────────────
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
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
