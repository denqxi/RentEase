import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_button.dart';

class PendingVerificationsScreen extends StatelessWidget {
  const PendingVerificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending verifications'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {},
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.amberPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '2',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _VerificationCard(
            ownerName: 'Maria Reyes',
            submittedDate: 'Submitted Jun 20, 2025',
            docs: [
              'Government ID',
              'Barangay certificate',
              'Property photos (4 files)',
            ],
          ),
          _VerificationCard(
            ownerName: 'Ana Santos',
            submittedDate: 'Submitted Jun 20, 2025',
            docs: [
              'Government ID',
              'Proof of ownership',
              'Property photos (3 files)',
            ],
          ),
        ],
=======

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';

class PendingVerificationsScreen extends StatefulWidget {
  const PendingVerificationsScreen({super.key});

  static const routeName = '/admin/verifications';

  @override
  State<PendingVerificationsScreen> createState() => _PendingVerificationsScreenState();
}

class _PendingVerificationsScreenState extends State<PendingVerificationsScreen> {
  final List<Map<String, dynamic>> _items = [
    {
      'id': 'v001',
      'name': 'Carlos Mendoza',
      'type': 'Owner',
      'submitted': 'Jun 24, 2025',
      'docs': ['Government ID', 'Property document', 'Business permit'],
      'status': 'pending',
    },
    {
      'id': 'v002',
      'name': 'Rosa Villanueva',
      'type': 'Owner',
      'submitted': 'Jun 23, 2025',
      'docs': ['Government ID', 'Property document'],
      'status': 'pending',
    },
    {
      'id': 'v003',
      'name': 'Benito Cruz',
      'type': 'Owner',
      'submitted': 'Jun 22, 2025',
      'docs': ['Government ID', 'Property document', 'Business permit'],
      'status': 'pending',
    },
  ];

  void _approve(String id) {
    setState(() {
      final i = _items.indexWhere((x) => x['id'] == id);
      if (i != -1) _items[i] = {..._items[i], 'status': 'approved'};
    });
  }

  Future<void> _reject(String id) async {
    final reasonCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject verification', style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reason for rejection:', style: TextStyle(fontFamily: 'DM Sans', fontSize: 14)),
            SizedBox(height: AppSpacing.sm),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter reason...',
                filled: true,
                fillColor: context.appColors.fieldFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.field)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: context.appColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                final i = _items.indexWhere((x) => x['id'] == id);
                if (i != -1) _items[i] = {..._items[i], 'status': 'rejected'};
              });
            },
            child: Text('Reject', style: TextStyle(color: AppColors.destructive, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    reasonCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      appBar: AppBar(
        backgroundColor: context.appColors.surface,
        elevation: 0,
        title: Text(
          'Pending verifications',
          style: TextStyle(fontFamily: 'DM Sans', fontSize: 16, fontWeight: FontWeight.w700, color: context.appColors.textPrimary),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _items.length,
        separatorBuilder: (_, _) => SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, i) {
          final item = _items[i];
          final status = item['status'] as String;
          return _VerificationCard(
            item: item,
            onApprove: status == 'pending' ? () => _approve(item['id'] as String) : null,
            onReject: status == 'pending' ? () => _reject(item['id'] as String) : null,
          );
        },
>>>>>>> Stashed changes
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
<<<<<<< Updated upstream
    required this.ownerName,
    required this.submittedDate,
    required this.docs,
  });

  final String ownerName;
  final String submittedDate;
  final List<String> docs;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ownerName,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              submittedDate,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            ...docs.map(
              (doc) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.description_outlined,
                        color: AppColors.textSecondary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        doc,
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      ),
                    ),
                    Icon(Icons.check_circle, color: AppColors.primaryMid, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(foregroundColor: AppColors.primaryMid),
              child: const Text('View documents'),
            ),
            const SizedBox(height: 8),
=======
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> item;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final status = item['status'] as String;
    final docs = item['docs'] as List<String>;

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'approved':
        statusColor = AppColors.matchHigh;
        statusLabel = 'Approved';
      case 'rejected':
        statusColor = AppColors.destructive;
        statusLabel = 'Rejected';
      default:
        statusColor = AppColors.matchMedium;
        statusLabel = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.fieldBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.accentSoft,
                child: Text(
                  (item['name'] as String).substring(0, 1),
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w700, color: context.appColors.ink),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'] as String, style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w700, color: context.appColors.textPrimary)),
                    Text('${item['type']} Â· Submitted ${item['submitted']}', style: AppTextStyles.caption(context)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          ...docs.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.description_rounded, size: 14, color: context.appColors.textSecondary),
                SizedBox(width: 6),
                Text(d, style: AppTextStyles.caption(context)),
                const Spacer(),
                Text('View', style: AppTextStyles.caption(context).copyWith(color: AppColors.primary)),
              ],
            ),
          )),
          if (onApprove != null) ...[
            SizedBox(height: AppSpacing.sm),
>>>>>>> Stashed changes
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Approve',
<<<<<<< Updated upstream
                    color: AppColors.primaryMid,
                    isSmall: true,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: 'Reject',
                    isDanger: true,
                    isSmall: true,
                    onPressed: () {},
=======
                    isSmall: true,
                    onPressed: onApprove,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: 'Reject',
                    variant: AppButtonVariant.destructiveOutline,
                    isSmall: true,
                    onPressed: onReject,
>>>>>>> Stashed changes
                  ),
                ),
              ],
            ),
          ],
<<<<<<< Updated upstream
        ),
=======
        ],
>>>>>>> Stashed changes
      ),
    );
  }
}
