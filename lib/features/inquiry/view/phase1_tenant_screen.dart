import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/phase_badge.dart';
import '../../../shared/widgets/verified_badge.dart';

class Phase1TenantScreen extends StatelessWidget {
  const Phase1TenantScreen({required this.property, super.key});

  final Map<String, dynamic> property;

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          property['name'] as String,
<<<<<<< Updated upstream
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: const [
=======
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.appColors.textPrimary,
          ),
        ),
        actions: [
>>>>>>> Stashed changes
          PhaseBadge(phase: 1),
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
                // Auto info bubble
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
<<<<<<< Updated upstream
                      decoration: const BoxDecoration(
=======
                      decoration: BoxDecoration(
>>>>>>> Stashed changes
                        color: AppColors.tenantFillBlue,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
<<<<<<< Updated upstream
                            children: const [
=======
                            children: [
>>>>>>> Stashed changes
                              Icon(Icons.access_time,
                                  color: AppColors.tenantTextCyan, size: 13),
                              SizedBox(width: 4),
                              Text(
                                'Auto info from RentEase',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.tenantTextCyan,
                                ),
                              ),
                            ],
                          ),
<<<<<<< Updated upstream
                          const SizedBox(height: 8),
                          Text(
                            'Gender policy: ${property['allowedGender']}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
=======
                          SizedBox(height: 8),
                          Text(
                            'Gender policy: ${property['allowedGender']}',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.appColors.textPrimary,
>>>>>>> Stashed changes
                            ),
                          ),
                          Text(
                            'Curfew: ${property['curfew']}',
<<<<<<< Updated upstream
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Text(
                            'Deposit: 2 months · Advance: 1 month',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const VerifiedBadge(
                            state: VerifiedState.verified,
=======
                            style: TextStyle(
                              fontSize: 13,
                              color: context.appColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Deposit: 2 months · Advance: 1 month',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.appColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 6),
                          const VerifiedBadge(
                            isVerified: true,
>>>>>>> Stashed changes
                            isSmall: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
<<<<<<< Updated upstream
                const SizedBox(height: 12),
                // Profile sent bubble
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
=======
                SizedBox(height: 12),
                // Profile sent bubble
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
>>>>>>> Stashed changes
                    color: AppColors.tenantFillBlue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
<<<<<<< Updated upstream
                  child: const Text(
                    'Your profile has been sent to the owner.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
=======
                  child: Text(
                    'Your profile has been sent to the owner.',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.appColors.textPrimary,
>>>>>>> Stashed changes
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Locked waiting panel
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
<<<<<<< Updated upstream
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: const [
                Icon(Icons.access_time_rounded,
                    color: AppColors.textHint, size: 32),
=======
              color: context.appColors.fieldFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.appColors.fieldBorder),
            ),
            child: Column(
              children: [
                Icon(Icons.access_time_rounded,
                    color: context.appColors.hint, size: 32),
>>>>>>> Stashed changes
                SizedBox(height: 8),
                Text(
                  'Waiting for owner response...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
<<<<<<< Updated upstream
                    color: AppColors.textPrimary,
=======
                    color: context.appColors.textPrimary,
>>>>>>> Stashed changes
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Chat unlocks after owner accepts your inquiry.',
                  style: TextStyle(
                    fontSize: 12,
<<<<<<< Updated upstream
                    color: AppColors.textSecondary,
=======
                    color: context.appColors.textSecondary,
>>>>>>> Stashed changes
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Disabled input bar
          IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
<<<<<<< Updated upstream
                        color: AppColors.fieldBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Message locked...',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textHint,
=======
                        color: context.appColors.fieldFill,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: context.appColors.fieldBorder),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Message locked...',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.appColors.hint,
>>>>>>> Stashed changes
                        ),
                      ),
                    ),
                  ),
<<<<<<< Updated upstream
                  const SizedBox(width: 8),
                  const Icon(Icons.send_rounded,
=======
                  SizedBox(width: 8),
                  Icon(Icons.send_rounded,
>>>>>>> Stashed changes
                      color: AppColors.disabled, size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
