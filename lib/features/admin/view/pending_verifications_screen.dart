import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../widgets/admin_page_header.dart';

class PendingVerificationsScreen extends StatefulWidget {
  const PendingVerificationsScreen({super.key});

  static const routeName = '/admin/verifications';

  @override
  State<PendingVerificationsScreen> createState() =>
      _PendingVerificationsScreenState();
}

class _PendingVerificationsScreenState
    extends State<PendingVerificationsScreen> {
  String _filter = 'Pending';

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

  int _count(String status) =>
      _items.where((x) => x['status'] == status).length;

  List<Map<String, dynamic>> get _visible => switch (_filter) {
        'Pending' => _items.where((x) => x['status'] == 'pending').toList(),
        'Approved' => _items.where((x) => x['status'] == 'approved').toList(),
        'Rejected' => _items.where((x) => x['status'] == 'rejected').toList(),
        _ => _items,
      };

  void _approve(String id) {
    setState(() {
      final i = _items.indexWhere((x) => x['id'] == id);
      if (i != -1) _items[i] = {..._items[i], 'status': 'approved'};
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Owner approved — they can now list properties.'),
        backgroundColor: context.appColors.ink,
      ),
    );
  }

  Future<void> _reject(String id) async {
    final reasonCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.appColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reject verification',
          style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reason for rejection:',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 14),
            ),
            SizedBox(height: AppSpacing.sm),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter reason...',
                filled: true,
                fillColor: ctx.appColors.fieldFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.field),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: ctx.appColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                final i = _items.indexWhere((x) => x['id'] == id);
                if (i != -1) _items[i] = {..._items[i], 'status': 'rejected'};
              });
            },
            child: Text(
              'Reject',
              style: TextStyle(
                color: AppColors.destructive,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    reasonCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pending = _count('pending');
    final visible = _visible;

    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: Column(
        children: [
          AdminPageHeader(
            title: 'Verifications',
            subtitle: pending == 0
                ? 'No owners waiting for review'
                : '$pending owner${pending == 1 ? '' : 's'} waiting for review',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in ['Pending', 'Approved', 'Rejected', 'All']) ...[
                    _FilterChip(
                      label: f == 'All' ? 'All' : '$f (${_countFor(f)})',
                      isSelected: _filter == f,
                      onTap: () => setState(() => _filter = f),
                    ),
                    SizedBox(width: AppSpacing.sm),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.task_alt_rounded,
                          size: 40,
                          color: context.appColors.indicatorInactive,
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          'Nothing here.',
                          style: AppTextStyles.body(context),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      120,
                    ),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) {
                      final item = visible[i];
                      final status = item['status'] as String;
                      return _VerificationCard(
                        item: item,
                        onApprove: status == 'pending'
                            ? () => _approve(item['id'] as String)
                            : null,
                        onReject: status == 'pending'
                            ? () => _reject(item['id'] as String)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  int _countFor(String filter) => switch (filter) {
        'Pending' => _count('pending'),
        'Approved' => _count('approved'),
        'Rejected' => _count('rejected'),
        _ => _items.length,
      };
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : context.appColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : context.appColors.fieldBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? AppColors.onInk
                : context.appColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> item;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  void _previewDocument(BuildContext context, String docName) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.appColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          docName,
          style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w700),
        ),
        content: Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: ctx.appColors.fieldFill,
            borderRadius: BorderRadius.circular(AppRadii.field),
          ),
          child: Icon(
            Icons.description_rounded,
            size: 48,
            color: ctx.appColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: ctx.appColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = item['status'] as String;
    final docs = item['docs'] as List<String>;

    final (statusColor, statusLabel) = switch (status) {
      'approved' => (AppColors.matchHigh, 'Approved'),
      'rejected' => (AppColors.destructive, 'Rejected'),
      _ => (AppColors.matchMedium, 'Pending'),
    };

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
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
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
                      item['name'] as String,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${item['type']} · Submitted ${item['submitted']}',
                      style: AppTextStyles.caption(context),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'SUBMITTED DOCUMENTS',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: docs
                .map(
                  (d) => GestureDetector(
                    onTap: () => _previewDocument(context, d),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.description_rounded,
                            size: 13,
                            color: AppColors.accent,
                          ),
                          SizedBox(width: 4),
                          Text(
                            d,
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 11,
                            color: AppColors.accent,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          if (onApprove != null) ...[
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Approve',
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
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
