import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/phase_badge.dart';

class Phase2TenantScreen extends StatefulWidget {
  const Phase2TenantScreen({required this.property, super.key});

  final Map<String, dynamic> property;

  @override
  State<Phase2TenantScreen> createState() => _Phase2TenantScreenState();
}

class _Phase2TenantScreenState extends State<Phase2TenantScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  late final List<_ChatMessage> _messages = <_ChatMessage>[
    _ChatMessage(text: 'Owner accepted your inquiry!', isSystem: true),
    _ChatMessage(
      text: 'Kumusta! Yes, available pa ang room. \u{1F60A}',
      isTenant: false,
    ),
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

  String _ownerReplyFor(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('visit') || lower.contains('schedule')) {
      return 'Sure! You can visit anytime this week, 9am-6pm. Just message me before you head over.';
    }
    if (lower.contains('available') || lower.contains('vacant')) {
      return 'Yes, still available! Room is ready for move-in.';
    }
    if (lower.contains('deposit') || lower.contains('advance')) {
      final int deposit = (widget.property['deposit'] as num?)?.toInt() ?? 0;
      final int advance = (widget.property['advanceMonths'] as num?)?.toInt() ?? 1;
      return 'Deposit is ₱$deposit and advance is $advance month(s).';
    }
    if (lower.contains('curfew')) {
      return 'Curfew here is ${widget.property['curfew'] ?? 'flexible'}.';
    }
    return 'Got it, thanks for the message! Let me know if you have other questions.';
  }

  void _sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: trimmed, isTenant: true));
      _messageController.clear();
    });
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(text: _ownerReplyFor(trimmed)));
      });
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    final String ownerName = widget.property['ownerName'] as String;
    final String ownerInitials = widget.property['ownerInitials'] as String;

    return Scaffold(
      backgroundColor: context.appColors.surface,
      appBar: AppBar(
        backgroundColor: context.appColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: context.appColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accentSoft,
              child: Text(
                ownerInitials,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.appColors.ink,
                ),
              ),
            ),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ownerName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.appColors.textPrimary,
                  ),
                ),
                Text(
                  widget.property['name'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PhaseBadge(phase: 2),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _MessageBubble(
                message: _messages[i],
                ownerInitials: ownerInitials,
              ),
            ),
          ),

          // Quick reply chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _QuickReplyChip(
                  label: 'When can I visit?',
                  onTap: () => _sendMessage('When can I visit?'),
                ),
                SizedBox(width: 8),
                _QuickReplyChip(
                  label: 'Is the room still available?',
                  onTap: () => _sendMessage('Is the room still available?'),
                ),
                SizedBox(width: 8),
                _QuickReplyChip(
                  label: 'How much is the deposit?',
                  onTap: () => _sendMessage('How much is the deposit?'),
                ),
              ],
            ),
          ),

          // Input bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.appColors.fieldFill,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: context.appColors.fieldBorder),
                    ),
                    child: TextField(
                      controller: _messageController,
                      onSubmitted: _sendMessage,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: context.appColors.hint,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(_messageController.text),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: context.appColors.ink,
                    child: Icon(Icons.send_rounded,
                        color: AppColors.onInk, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  _ChatMessage({required this.text, this.isTenant = false, this.isSystem = false});

  final String text;
  final bool isTenant;
  final bool isSystem;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.ownerInitials});

  final _ChatMessage message;
  final String ownerInitials;

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Center(
          child: Text(
            message.text,
            style: TextStyle(
              fontSize: 12,
              color: context.appColors.textSecondary,
            ),
          ),
        ),
      );
    }

    if (!message.isTenant) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: context.appColors.fieldFill,
              child: Text(
                ownerInitials,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: context.appColors.textSecondary,
                ),
              ),
            ),
            SizedBox(width: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.appColors.fieldFill,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border.all(color: context.appColors.fieldBorder),
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.appColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.65,
          ),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.appColors.ink,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.onInk,
              ),
            ),
          ),
        ),
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
