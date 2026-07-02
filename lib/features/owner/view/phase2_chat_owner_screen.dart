import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/phase_badge.dart';

class Phase2ChatOwnerScreen extends StatefulWidget {
  const Phase2ChatOwnerScreen({required this.inquiry, super.key});

  final Map<String, dynamic> inquiry;

  @override
  State<Phase2ChatOwnerScreen> createState() => _Phase2ChatOwnerScreenState();
}

class _Phase2ChatOwnerScreenState extends State<Phase2ChatOwnerScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [
    _ChatMessage(text: 'Inquiry accepted. Chat is now open.', isSystem: true),
    _ChatMessage(
      text: 'Hello! I\'m interested in your boarding house. Is it still available?',
      isOwner: false,
    ),
    _ChatMessage(text: 'Yes it\'s available! When are you planning to move in?', isOwner: true),
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

  String _tenantReplyFor(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('move in') || lower.contains('when')) {
      return 'I can move in as early as next week, if that works!';
    }
    if (lower.contains('document') || lower.contains('requirement')) {
      return 'Sure, I have my valid ID and proof of enrollment ready.';
    }
    if (lower.contains('visit') || lower.contains('viewing')) {
      return 'Yes, I would love to schedule a viewing this week.';
    }
    return 'Sounds good, thank you!';
  }

  void _sendMessage([String? quickReply]) {
    final text = (quickReply ?? _messageController.text).trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isOwner: true));
      _messageController.clear();
    });
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(text: _tenantReplyFor(text)));
      });
      _scrollToBottom();
    });
  }

  Future<void> _showMarkBookedDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Mark as booked?',
          style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will confirm the booking for this tenant.',
          style: TextStyle(fontFamily: 'DM Sans', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: context.appColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final inquiry = widget.inquiry;
              MockData.ownerInquiries.remove(inquiry);
              MockData.ownerInquiryHistory.insert(0, {
                'tenantName': inquiry['tenantName'],
                'tenantInitials': inquiry['tenantInitials'],
                'propertyName': inquiry['propertyName'],
                'status': 'Booked',
                'date': 'Jul 2, 2026',
              });
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Booking confirmed for ${inquiry['tenantName']}. '
                    'Moved to inquiry history.',
                  ),
                  backgroundColor: context.appColors.ink,
                ),
              );
            },
            child: Text(
              'Confirm',
              style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      appBar: AppBar(
        backgroundColor: context.appColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.appColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accentSoft,
              child: Text(
                widget.inquiry['tenantInitials'] as String,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.ink,
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.inquiry['tenantName'] as String,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  Text(widget.inquiry['propertyName'] as String, style: AppTextStyles.caption(context)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: Center(child: PhaseBadge(phase: 2)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _MessageBubble(message: _messages[i]),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: Row(
              children: [
                _QuickReplyChip(
                  label: 'When can you move in?',
                  onTap: () => _sendMessage('When can you move in?'),
                ),
                SizedBox(width: AppSpacing.sm),
                _QuickReplyChip(
                  label: 'Any documents ready?',
                  onTap: () => _sendMessage('Do you have your documents ready?'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showMarkBookedDialog,
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
            padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: AppTextStyles.field(context),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: AppTextStyles.field(context).copyWith(color: context.appColors.hint),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: context.appColors.fieldFill,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: context.appColors.fieldBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: context.appColors.ink,
                      child: Icon(Icons.send_rounded, color: AppColors.onInk, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  _ChatMessage({required this.text, this.isOwner = false, this.isSystem = false});

  final String text;
  final bool isOwner;
  final bool isSystem;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: context.appColors.fieldFill,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(color: context.appColors.fieldBorder, width: 0.5),
        ),
        child: Text(message.text, style: AppTextStyles.caption(context), textAlign: TextAlign.center),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment:
            message.isOwner ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: message.isOwner ? context.appColors.ink : context.appColors.fieldFill,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(13),
                topRight: const Radius.circular(13),
                bottomLeft: message.isOwner ? const Radius.circular(13) : const Radius.circular(4),
                bottomRight: message.isOwner ? const Radius.circular(4) : const Radius.circular(13),
              ),
              border: message.isOwner ? null : Border.all(color: context.appColors.fieldBorder, width: 0.5),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: message.isOwner ? AppColors.onInk : context.appColors.textPrimary,
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
  final VoidCallback onTap;

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
          style: TextStyle(
            fontSize: 12,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }
}
