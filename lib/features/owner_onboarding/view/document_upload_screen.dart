import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  List<bool> uploaded = [false, false, false];

  final List<String> _labels = [
    'Valid government ID',
    'Proof of ownership or barangay certificate',
    'Property photos (minimum 3)',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify your account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload the required documents to start listing properties.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 24),
            ...List.generate(3, (i) {
              final isUploaded = uploaded[i];
              return GestureDetector(
                onTap: () => setState(() => uploaded[i] = true),
                child: Container(
                  height: 80,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isUploaded ? AppColors.tenantFillBlue : AppColors.fieldBg,
                    border: Border.all(
                      color: isUploaded ? AppColors.primaryMid : AppColors.border,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.field),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isUploaded ? Icons.check_circle : Icons.upload_outlined,
                        color: isUploaded ? AppColors.primaryMid : AppColors.textHint,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _labels[i],
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),
            AppButton(
              label: 'Submit for verification',
              color: AppColors.ownerPrimary,
              onPressed: uploaded.every((u) => u) ? () {} : null,
            ),
            const SizedBox(height: 12),
            Text(
              'Admin will review your documents within 24–48 hours.',
              style: TextStyle(color: AppColors.textHint, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
