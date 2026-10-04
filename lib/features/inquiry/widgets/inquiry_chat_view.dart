import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/firestore/models/models.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/phase_badge.dart';
import '../../resolution/view/rating_screen.dart';
import '../cubit/inquiry_thread_cubit.dart';
import '../domain/services/inquiry_service.dart';
import 'rejected_owner_notice.dart';
import '../model/inquiry_summary.dart';
import 'contact_row.dart';

/// Phase 2 — open chat between tenant and owner, shared by both sides
/// ([isOwner] picks the perspective). Owners can mark the booking; once
/// booked, the input is replaced by a prompt to rate the other party.
class InquiryChatView extends StatefulWidget {
  const InquiryChatView({
    required this.isOwner,
    required this.counterpartName,
    required this.propertyTitle,
    super.key,
  });

  final bool isOwner;
  final String counterpartName;
  final String propertyTitle;

  @override
  State<InquiryChatView> createState() => _InquiryChatViewState();
}

class _InquiryChatViewState extends State<InquiryChatView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  int _lastMessageCount = 0;

  static const _tenantQuickReplies = [
    'When can I visit?',
    'Is the room still available?',
    'How much is the deposit?',
  ];

  static const _ownerQuickReplies = [
    'When can you move in?',
    'Do you have your documents ready?',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    final sent = await context.read<InquiryThreadCubit>().sendMessage(text);
    if (sent && mounted && text == _messageController.text) {
      _messageController.clear();
    }
  }

  Future<void> _confirmMarkBooked() async {
    final cubit = context.read<InquiryThreadCubit>();
    // Unchecked by default: most boarding houses have several vacancies,
    // and hiding a listing by accident is worse than an extra inquiry.
    var fillsLastVacancy = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Mark as booked?',
          style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w700),
        ),
        content: StatefulBuilder(
          builder: (ctx, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This confirms the booking for ${widget.counterpartName} and '
                'closes the chat.',
                style: const TextStyle(fontFamily: 'DM Sans', fontSize: 14),
              ),
              SizedBox(height: AppSpacing.md),
              CheckboxListTile(
                value: fillsLastVacancy,
                onChanged: (v) =>
                    setDialogState(() => fillsLastVacancy = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.accent,
                title: const Text(
                  'This fills my last vacancy',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Hides ${widget.propertyTitle} from new tenants and closes '
                  'its other open inquiries.',
                  style: AppTextStyles.caption(ctx),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: ctx.appColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Confirm',
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (await cubit.markBooked(fillsLastVacancy: fillsLastVacancy) && mounted) {
      _openRating();
    }
  }

  void _openRating() {
    final cubit = context.read<InquiryThreadCubit>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => widget.isOwner
            ? RatingScreen.forOwner(
                subjectName: widget.counterpartName,
                subjectInitials: InquirySummary.initialsOf(
                  widget.counterpartName,
                ),
                moveInLabel: widget.propertyTitle,
                onSubmit: (stars, review) =>
                    cubit.submitRating(stars: stars, review: review),
              )
            : RatingScreen(
                subjectName: widget.propertyTitle,
                moveInLabel: 'Hosted by ${widget.counterpartName}',
                onSubmit: (stars, review) =>
                    cubit.submitRating(stars: stars, review: review),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<InquiryThreadCubit>().state;
    final inquiry = state.inquiry!;
    final booked = inquiry.status == 'booked';
    // Another tenant took the last vacancy (InquiryService.markBooked).
    final closed = inquiry.status == 'closed';
    final canChat = InquiryService.canChat(inquiry);
    final myId = context.read<InquiryThreadCubit>().uid;

    if (state.messages.length != _lastMessageCount) {
      _lastMessageCount = state.messages.length;
      _scrollToBottom();
    }

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
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accentSoft,
              child: Text(
                InquirySummary.initialsOf(widget.counterpartName),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.appColors.ink,
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.counterpartName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: context.appColors.textPrimary,
                          ),
                        ),
                      ),
                      // CLAUDE.md verified-badge placement #4: Phase 2 chat
                      // header, icon only — shown to the tenant for the owner.
                      if (!widget.isOwner && state.ownerVerified) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: AppColors.matchHigh,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    widget.propertyTitle,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Center(child: PhaseBadge(phase: 2)),
          SizedBox(width: AppSpacing.md),
        ],
      ),
      body: Column(
        children: [
          // Shown once the other party shared their phone (accepted threads,
          // including booked); absent otherwise.
          ContactRow(phone: state.counterpartPhone),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: state.messages.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return _SystemNote(
                    widget.isOwner
                        ? 'You accepted this inquiry — chat is open.'
                        : '${widget.counterpartName} accepted your inquiry — '
                              'chat is open.',
                  );
                }
                final message = state.messages[i - 1];
                return _MessageBubble(
                  message: message,
                  isMine: message.senderId == myId,
                );
              },
            ),
          ),
          if (booked)
            _BookedPanel(
              isOwner: widget.isOwner,
              counterpartName: widget.counterpartName,
              onRate: _openRating,
            )
          else if (closed)
            _ClosedPanel(isOwner: widget.isOwner)
          else if (state.ownerRejected)
            RejectedOwnerNotice(isOwner: widget.isOwner)
          else ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  for (final reply
                      in widget.isOwner
                          ? _ownerQuickReplies
                          : _tenantQuickReplies) ...[
                    _QuickReplyChip(
                      label: reply,
                      onTap: canChat && !state.isBusy
                          ? () => _send(reply)
                          : null,
                    ),
                    SizedBox(width: AppSpacing.sm),
                  ],
                ],
              ),
            ),
            if (widget.isOwner)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: canChat && !state.isBusy
                        ? _confirmMarkBooked
                        : null,
                    child: Text(
                      'Mark as booked',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: canChat,
                        onSubmitted: _send,
                        textInputAction: TextInputAction.send,
                        style: AppTextStyles.field(context),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: AppTextStyles.field(
                            context,
                          ).copyWith(color: context.appColors.hint),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: context.appColors.fieldFill,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: context.appColors.fieldBorder,
                            ),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: context.appColors.fieldBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: AppColors.accent,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    GestureDetector(
                      onTap: canChat && !state.isBusy
                          ? () => _send(_messageController.text)
                          : null,
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: canChat
                            ? context.appColors.ink
                            : context.appColors.indicatorInactive,
                        child: Icon(
                          Icons.send_rounded,
                          color: AppColors.onInk,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SystemNote extends StatelessWidget {
  const _SystemNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: context.appColors.fieldFill,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            border: Border.all(color: context.appColors.fieldBorder, width: 0.5),
          ),
          child: Text(
            text,
            style: AppTextStyles.caption(context),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final MessageDoc message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isMine ? context.appColors.ink : context.appColors.fieldFill,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(13),
                topRight: const Radius.circular(13),
                bottomLeft: Radius.circular(isMine ? 13 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 13),
              ),
              border: isMine
                  ? null
                  : Border.all(color: context.appColors.fieldBorder, width: 0.5),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: isMine ? AppColors.onInk : context.appColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickReplyChip extends StatelessWidget {
  const _QuickReplyChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.accent),
        ),
      ),
    );
  }
}

class _ClosedPanel extends StatelessWidget {
  const _ClosedPanel({required this.isOwner});

  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SafeArea(
        top: false,
        child: Text(
          isOwner
              ? 'Closed — you marked this listing fully booked.'
              : 'This listing is now fully booked, so the chat is closed.',
          style: AppTextStyles.body(
            context,
          ).copyWith(color: context.appColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _BookedPanel extends StatelessWidget {
  const _BookedPanel({
    required this.isOwner,
    required this.counterpartName,
    required this.onRate,
  });

  final bool isOwner;
  final String counterpartName;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.matchHigh,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Booking confirmed',
                  style: AppTextStyles.body(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            AppButton(
              label: isOwner ? 'Rate $counterpartName' : 'Rate your stay',
              variant: AppButtonVariant.outline,
              onPressed: onRate,
            ),
          ],
        ),
      ),
    );
  }
}
