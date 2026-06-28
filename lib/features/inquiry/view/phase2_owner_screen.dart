import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../shared/widgets/phase_badge.dart';

class Phase2OwnerScreen extends StatelessWidget {
  const Phase2OwnerScreen({super.key, required this.inquiry});

  final Map<String, dynamic> inquiry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.ownerFill,
              child: Text(
                inquiry['tenantInitials'] as String,
<<<<<<< Updated upstream
                style: const TextStyle(
=======
                style: TextStyle(
>>>>>>> Stashed changes
                  color: AppColors.ownerText,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
<<<<<<< Updated upstream
            const SizedBox(width: AppSpacing.sm),
=======
            SizedBox(width: AppSpacing.sm),
>>>>>>> Stashed changes
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  inquiry['tenantName'] as String,
<<<<<<< Updated upstream
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
=======
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: context.appColors.textPrimary,
>>>>>>> Stashed changes
                  ),
                ),
                Text(
                  inquiry['propertyName'] as String,
<<<<<<< Updated upstream
                  style: const TextStyle(
                    color: AppColors.textSecondary,
=======
                  style: TextStyle(
                    color: context.appColors.textSecondary,
>>>>>>> Stashed changes
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PhaseBadge(phase: 2),
<<<<<<< Updated upstream
          const SizedBox(width: AppSpacing.md),
=======
          SizedBox(width: AppSpacing.md),
>>>>>>> Stashed changes
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // System message
                Container(
                  margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
<<<<<<< Updated upstream
                    color: AppColors.fieldBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'Owner accepted your inquiry. You can now chat.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
=======
                    color: context.appColors.fieldFill,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'Owner accepted your inquiry. You can now chat.',
                      style: TextStyle(
                        color: context.appColors.textSecondary,
>>>>>>> Stashed changes
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                // Owner bubble (right)
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: const EdgeInsets.all(10),
<<<<<<< Updated upstream
                    decoration: const BoxDecoration(
=======
                    decoration: BoxDecoration(
>>>>>>> Stashed changes
                      color: AppColors.ownerPrimary,
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
                      'Hello! Yes the room is still available.',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
<<<<<<< Updated upstream
                const SizedBox(height: AppSpacing.sm),
=======
                SizedBox(height: AppSpacing.sm),
>>>>>>> Stashed changes

                // Tenant bubble (left)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
<<<<<<< Updated upstream
                      color: AppColors.fieldBg,
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
                      'Great! Can I visit this weekend?',
                      style: TextStyle(
                        color: AppColors.textPrimary,
=======
                      border: Border.all(color: context.appColors.fieldBorder),
                    ),
                    child: Text(
                      'Great! Can I visit this weekend?',
                      style: TextStyle(
                        color: context.appColors.textPrimary,
>>>>>>> Stashed changes
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mark as booked
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
<<<<<<< Updated upstream
                  foregroundColor: AppColors.textSecondary,
                ),
                child: const Text('Mark as booked'),
=======
                  foregroundColor: context.appColors.textSecondary,
                ),
                child: Text('Mark as booked'),
>>>>>>> Stashed changes
              ),
            ),
          ),

          // Message input
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
<<<<<<< Updated upstream
                      color: AppColors.fieldBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const TextField(
=======
                      color: context.appColors.fieldFill,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.appColors.fieldBorder),
                    ),
                    child: TextField(
>>>>>>> Stashed changes
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ),
                ),
<<<<<<< Updated upstream
                const SizedBox(width: AppSpacing.sm),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.ownerPrimary,
                  child: const Icon(Icons.send, color: Colors.white, size: 18),
=======
                SizedBox(width: AppSpacing.sm),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.ownerPrimary,
                  child: Icon(Icons.send, color: Colors.white, size: 18),
>>>>>>> Stashed changes
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
