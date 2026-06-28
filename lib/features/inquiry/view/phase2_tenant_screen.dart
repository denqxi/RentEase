import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/phase_badge.dart';

class Phase2TenantScreen extends StatelessWidget {
  const Phase2TenantScreen({required this.property, super.key});

  final Map<String, dynamic> property;

  @override
  Widget build(BuildContext context) {
    final String ownerName = property['ownerName'] as String;
    final String ownerInitials = property['ownerInitials'] as String;

    return Scaffold(
<<<<<<< Updated upstream
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
=======
      backgroundColor: context.appColors.surface,
      appBar: AppBar(
        backgroundColor: context.appColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: context.appColors.textPrimary, size: 20),
>>>>>>> Stashed changes
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.tenantFillBlue,
              child: Text(
                ownerInitials,
<<<<<<< Updated upstream
                style: const TextStyle(
=======
                style: TextStyle(
>>>>>>> Stashed changes
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.tenantTextDeep,
                ),
              ),
            ),
<<<<<<< Updated upstream
            const SizedBox(width: 8),
=======
            SizedBox(width: 8),
>>>>>>> Stashed changes
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ownerName,
<<<<<<< Updated upstream
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
=======
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: 4),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
>>>>>>> Stashed changes
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                Text(
                  property['name'] as String,
<<<<<<< Updated upstream
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
=======
                  style: TextStyle(
                    fontSize: 11,
                    color: context.appColors.textSecondary,
>>>>>>> Stashed changes
                  ),
                ),
              ],
            ),
          ],
        ),
<<<<<<< Updated upstream
        actions: const [
=======
        actions: [
>>>>>>> Stashed changes
          PhaseBadge(phase: 2),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // System message
                Center(
                  child: Text(
                    'Owner accepted your inquiry!',
<<<<<<< Updated upstream
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
=======
                    style: TextStyle(
                      fontSize: 12,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(height: 12),
>>>>>>> Stashed changes

                // Owner message
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 16,
<<<<<<< Updated upstream
                      backgroundColor: AppColors.fieldBg,
                      child: Text(
                        ownerInitials,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth:
                            MediaQuery.of(context).size.width * 0.65,
=======
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
>>>>>>> Stashed changes
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
<<<<<<< Updated upstream
                          color: AppColors.fieldFill,
=======
                          color: context.appColors.fieldFill,
>>>>>>> Stashed changes
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
<<<<<<< Updated upstream
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Text(
                          'Kumusta! Yes, available pa ang room. 😊',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
=======
                          border: Border.all(color: context.appColors.fieldBorder),
                        ),
                        child: Text(
                          'Kumusta! Yes, available pa ang room. 😊',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.appColors.textPrimary,
>>>>>>> Stashed changes
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
<<<<<<< Updated upstream
                const SizedBox(height: 8),
=======
                SizedBox(height: 8),
>>>>>>> Stashed changes

                // Tenant message
                Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
<<<<<<< Updated upstream
                      maxWidth:
                          MediaQuery.of(context).size.width * 0.65,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
=======
                      maxWidth: MediaQuery.of(context).size.width * 0.65,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
>>>>>>> Stashed changes
                        color: AppColors.primaryMid,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
<<<<<<< Updated upstream
                      child: const Text(
=======
                      child: Text(
>>>>>>> Stashed changes
                        'Salamat! When can I schedule a visit?',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Quick reply chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
<<<<<<< Updated upstream
              children: const [
=======
              children: [
>>>>>>> Stashed changes
                _QuickReplyChip('When can I visit?'),
                SizedBox(width: 8),
                _QuickReplyChip('Is the room still available?'),
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
<<<<<<< Updated upstream
                      color: AppColors.fieldBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: AppColors.textHint,
=======
                      color: context.appColors.fieldFill,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: context.appColors.fieldBorder),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: context.appColors.hint,
>>>>>>> Stashed changes
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
<<<<<<< Updated upstream
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryMid,
                  child: const Icon(Icons.send_rounded,
=======
                SizedBox(width: 8),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryMid,
                  child: Icon(Icons.send_rounded,
>>>>>>> Stashed changes
                      color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickReplyChip extends StatelessWidget {
  const _QuickReplyChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.tenantFillBlue,
        border: Border.all(
            color: AppColors.primaryMid.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
<<<<<<< Updated upstream
        style: const TextStyle(
=======
        style: TextStyle(
>>>>>>> Stashed changes
          fontSize: 12,
          color: AppColors.primaryMid,
        ),
      ),
    );
  }
}
