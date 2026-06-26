import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class VerificationPendingScreen extends StatelessWidget {
  const VerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.amberFill,
                child: Icon(
                  Icons.access_time,
                  color: AppColors.amberPrimary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Verification in progress.',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your documents have been submitted and are being reviewed.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Row 1
              Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.primaryMid, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Documents submitted',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Row 2
              Row(
                children: [
                  Icon(Icons.access_time, color: AppColors.amberPrimary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Admin review',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.amberFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'In progress',
                      style: TextStyle(
                        color: AppColors.amberText,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Row 3
              Row(
                children: [
                  Icon(Icons.radio_button_unchecked, color: AppColors.border, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Account approved',
                    style: TextStyle(color: AppColors.textHint, fontSize: 14),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.fieldBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Waiting',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'You will be notified via email when your account is approved.',
                style: TextStyle(color: AppColors.textHint, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
