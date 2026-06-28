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
      backgroundColor: context.appColors.surface,
      appBar: AppBar(
        backgroundColor: context.appColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: context.appColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          property['name'] as String,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.appColors.textPrimary,
          ),
        ),
        actions: [
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
                      decoration: BoxDecoration(
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
                            children: [
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
                          SizedBox(height: 8),
                          Text(
                            'Gender policy: ${property['allowedGender']}',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.appColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Curfew: ${property['curfew']}',
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
                            isSmall: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Profile sent bubble
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.tenantFillBlue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Your profile has been sent to the owner.',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.appColors.textPrimary,
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
              color: context.appColors.fieldFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.appColors.fieldBorder),
            ),
            child: Column(
              children: [
                Icon(Icons.access_time_rounded,
                    color: context.appColors.hint, size: 32),
                SizedBox(height: 8),
                Text(
                  'Waiting for owner response...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.appColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Chat unlocks after owner accepts your inquiry.',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.appColors.textSecondary,
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
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.send_rounded,
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
