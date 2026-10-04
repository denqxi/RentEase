import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_links.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/cloudinary_url.dart';
import '../../../core/utils/url_opener.dart';
import '../../../shared/widgets/app_button.dart';
import '../cubit/verifications_cubit.dart';
import '../domain/entities/admin_entities.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/admin_state_views.dart';

class PendingVerificationsScreen extends StatelessWidget {
  const PendingVerificationsScreen({
    super.key,
    this.urlOpener = const UrlLauncherOpener(),
  });

  final UrlOpener urlOpener;

  static const routeName = '/admin/verifications';

  static const _filters = [
    ('pending', 'Pending'),
    ('verified', 'Approved'),
    ('rejected', 'Rejected'),
    ('all', 'All'),
  ];

  Future<void> _reject(BuildContext context, String ownerId) async {
    final cubit = context.read<VerificationsCubit>();
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
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
              'Reason for rejection (optional):',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 14),
            ),
            SizedBox(height: AppSpacing.sm),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              maxLength: 300,
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
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: ctx.appColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
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
    final reason = reasonCtrl.text;
    reasonCtrl.dispose();
    if (confirmed == true) cubit.reject(ownerId, reason: reason);
  }

  Future<void> _approve(BuildContext context, VerificationItem item) async {
    final cubit = context.read<VerificationsCubit>();
    final ok = await confirmAdminAction(
      context,
      title: 'Approve ${item.ownerName}?',
      body:
          'The owner becomes verified and their listings get the Verified '
          'badge.',
      confirmLabel: 'Approve',
      destructive: false,
    );
    if (ok) cubit.approve(item.ownerId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VerificationsCubit, VerificationsState>(
      listenWhen: (a, b) => a.noticeSeq != b.noticeSeq,
      listener: (context, state) => showAdminNotice(context, state.notice),
      builder: (context, state) {
        final pending = state.countOf('pending');
        final visible = state.visible;
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
                      for (final (key, label) in _filters) ...[
                        _FilterChip(
                          label: key == 'all'
                              ? label
                              : '$label (${state.countOf(key)})',
                          isSelected: state.filter == key,
                          onTap: () =>
                              context.read<VerificationsCubit>().setFilter(key),
                        ),
                        SizedBox(width: AppSpacing.sm),
                      ],
                    ],
                  ),
                ),
              ),
              Expanded(
                child: state.isLoading
                    ? const AdminLoadingView()
                    : state.errorMessage != null && state.items.isEmpty
                    ? AdminMessageView(
                        icon: Icons.error_outline_rounded,
                        message: state.errorMessage!,
                        onRetry: context.read<VerificationsCubit>().start,
                      )
                    : visible.isEmpty
                    ? const AdminMessageView(
                        icon: Icons.task_alt_rounded,
                        message: 'Nothing here.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          120,
                        ),
                        itemCount: visible.length,
                        separatorBuilder: (_, _) =>
                            SizedBox(height: AppSpacing.sm),
                        itemBuilder: (_, i) {
                          final item = visible[i];
                          final isPending = item.status == 'pending';
                          final busy = state.busyIds.contains(item.ownerId);
                          return _VerificationCard(
                            item: item,
                            documents: state.documents[item.ownerId],
                            isBusy: busy,
                            urlOpener: urlOpener,
                            onOpenDocuments: () => context
                                .read<VerificationsCubit>()
                                .loadDocuments(item.ownerId),
                            onApprove: isPending && !busy
                                ? () => _approve(context, item)
                                : null,
                            onReject: isPending && !busy
                                ? () => _reject(context, item.ownerId)
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
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
    required this.documents,
    required this.isBusy,
    required this.urlOpener,
    required this.onOpenDocuments,
    required this.onApprove,
    required this.onReject,
  });

  final VerificationItem item;
  final VerificationDocuments? documents;
  final bool isBusy;
  final UrlOpener urlOpener;
  final VoidCallback onOpenDocuments;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel) = switch (item.status) {
      'verified' => (AppColors.matchHigh, 'Approved'),
      'rejected' => (AppColors.destructive, 'Rejected'),
      _ => (AppColors.matchMedium, 'Pending'),
    };
    final initial = item.ownerName.isEmpty
        ? '?'
        : item.ownerName.substring(0, 1).toUpperCase();
    final submitted = item.profile.submittedAt?.toDate();

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
                  initial,
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
                      item.ownerName,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Owner · Submitted ${formatAdminDate(submitted)}',
                      style: AppTextStyles.caption(context),
                    ),
                    if (item.ownerEmail.isNotEmpty)
                      Text(
                        item.ownerEmail,
                        style: AppTextStyles.caption(context),
                      ),
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
          if (item.status == 'rejected' &&
              (item.profile.rejectionReason ?? '').isNotEmpty) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              'Reason: ${item.profile.rejectionReason}',
              style: AppTextStyles.caption(context),
            ),
          ],
          SizedBox(height: AppSpacing.sm),
          _DocumentsSection(
            documents: documents,
            onOpen: onOpenDocuments,
            ownerName: item.ownerName,
            urlOpener: urlOpener,
            onApprove: onApprove,
            onReject: onReject,
          ),
          if (isBusy) ...[
            SizedBox(height: AppSpacing.md),
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              ),
            ),
          ] else if (item.status == 'pending') ...[
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

/// Lazily loads the private document references when the admin asks.
class _DocumentsSection extends StatelessWidget {
  const _DocumentsSection({
    required this.documents,
    required this.onOpen,
    required this.ownerName,
    required this.urlOpener,
    required this.onApprove,
    required this.onReject,
  });

  final VerificationDocuments? documents;
  final VoidCallback onOpen;
  final String ownerName;
  final UrlOpener urlOpener;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  static const _permitIndex = 2;

  static const _labels = [
    'Government ID',
    'Property ownership document',
    'Business permit',
  ];

  @override
  Widget build(BuildContext context) {
    final docs = documents;
    if (docs == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onOpen,
          icon: Icon(
            Icons.description_rounded,
            size: 15,
            color: AppColors.accent,
          ),
          label: Text(
            'View submitted documents',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ),
      );
    }
    if (docs.isEmpty) {
      return Text(
        'No document references on file.',
        style: AppTextStyles.caption(context),
      );
    }
    final count = docs.publicIds.length > docs.urls.length
        ? docs.publicIds.length
        : docs.urls.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        for (var i = 0; i < count; i++)
          _DocumentRow(
            label: i < _labels.length ? _labels[i] : 'Document ${i + 1}',
            publicId: i < docs.publicIds.length ? docs.publicIds[i] : null,
            url: i < docs.urls.length ? docs.urls[i] : null,
            ownerName: ownerName,
            urlOpener: urlOpener,
            isPermit: i == _permitIndex,
            onApprove: onApprove,
            onReject: onReject,
          ),
        if (count > _permitIndex)
          BusinessPermitCheckButton(ownerName: ownerName, urlOpener: urlOpener),
        if (count < _labels.length)
          Text(
            'No ${_labels[count].toLowerCase()} submitted (optional).',
            style: AppTextStyles.caption(context),
          ),
      ],
    );
  }
}

const documentLoadErrorMessage =
    'Could not load this document. If the file is private in Cloudinary, '
    'set the documents upload preset delivery type to Upload (public) or '
    'open it in the Cloudinary Media Library';

/// Full-screen, pinch-zoomable document viewer. Approve/Reject stay reachable
/// so the admin keeps the document in view while deciding.
class DocumentViewerDialog extends StatelessWidget {
  const DocumentViewerDialog({
    super.key,
    required this.title,
    required this.url,
    required this.reference,
    this.onApprove,
    this.onReject,
    this.permitCheck,
  });

  final String title;
  final String url;
  final String reference;

  /// Set for the business permit only; shows the NegosyoKonek lookup button.
  final ({String ownerName, UrlOpener urlOpener})? permitCheck;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: AppColors.ink,
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Close',
                  icon: Icon(Icons.close_rounded, color: AppColors.onInk),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onInk,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: Image.network(
                    CloudinaryUrl.optimized(url, width: 1600),
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                    errorBuilder: (_, _, _) => Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              documentLoadErrorMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                color: AppColors.onInk,
                              ),
                            ),
                            SizedBox(height: AppSpacing.sm),
                            SelectableText(
                              reference,
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                color: AppColors.hint,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: reference.isEmpty
                                  ? null
                                  : () {
                                      Clipboard.setData(
                                        ClipboardData(text: reference),
                                      );
                                      showAdminNotice(context, 'Copied');
                                    },
                              icon: Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              label: Text(
                                'Copy public ID',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (permitCheck != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: BusinessPermitCheckButton(
                  ownerName: permitCheck!.ownerName,
                  urlOpener: permitCheck!.urlOpener,
                  onDark: true,
                ),
              ),
            if (onApprove != null || onReject != null)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    if (onApprove != null)
                      Expanded(
                        child: AppButton(
                          label: 'Approve',
                          isSmall: true,
                          onPressed: onApprove,
                        ),
                      ),
                    if (onApprove != null && onReject != null)
                      SizedBox(width: AppSpacing.sm),
                    if (onReject != null)
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
              ),
          ],
        ),
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.label,
    required this.ownerName,
    required this.urlOpener,
    this.isPermit = false,
    this.publicId,
    this.url,
    this.onApprove,
    this.onReject,
  });

  final String label;
  final String ownerName;
  final UrlOpener urlOpener;
  final bool isPermit;
  final String? publicId;
  final String? url;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  String get _reference =>
      (publicId != null && publicId!.isNotEmpty) ? publicId! : (url ?? '');

  void _openViewer(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => DocumentViewerDialog(
        title: '$label - $ownerName',
        url: url!,
        reference: _reference,
        permitCheck: isPermit
            ? (ownerName: ownerName, urlOpener: urlOpener)
            : null,
        onApprove: onApprove == null
            ? null
            : () {
                Navigator.of(ctx).pop();
                onApprove!();
              },
        onReject: onReject == null
            ? null
            : () {
                Navigator.of(ctx).pop();
                onReject!();
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reference = _reference;
    final shown = reference.split('/').last;
    final hasUrl = url != null && url!.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: hasUrl ? () => _openViewer(context) : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 64,
                height: 64,
                child: hasUrl
                    ? Image.network(
                        CloudinaryUrl.thumbnail(url!),
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                        errorBuilder: (_, _, _) => Container(
                          color: context.appColors.surface,
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: AppColors.hint,
                          ),
                        ),
                      )
                    : Container(
                        color: context.appColors.surface,
                        child: Icon(
                          Icons.description_rounded,
                          color: AppColors.hint,
                        ),
                      ),
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
                Text(
                  shown,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context),
                ),
                if (hasUrl)
                  Text('Tap to enlarge', style: AppTextStyles.caption(context)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy public ID',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.copy_rounded, size: 16, color: AppColors.accent),
            onPressed: reference.isEmpty
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: reference));
                    showAdminNotice(context, 'Copied $shown');
                  },
          ),
        ],
      ),
    );
  }
}

/// Opens the DTI NegosyoKonek search so the admin can look up the owner's
/// business name. Shown only when the optional business permit was submitted.
class BusinessPermitCheckButton extends StatelessWidget {
  const BusinessPermitCheckButton({
    super.key,
    required this.ownerName,
    required this.urlOpener,
    this.onDark = false,
  });

  final String ownerName;
  final UrlOpener urlOpener;
  final bool onDark;

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await urlOpener.open(
      Uri.parse(AppLinks.dtiNegosyoKonekSearch),
    );
    if (opened) return;
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.destructive,
        content: Text(
          'Could not open the NegosyoKonek page. Please try again or open '
          'it in your browser.',
          style: TextStyle(color: AppColors.onInk),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Owner: $ownerName',
            style: onDark
                ? TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    color: AppColors.hint,
                  )
                : AppTextStyles.caption(context),
          ),
          SizedBox(height: 4),
          AppButton(
            label: 'Check business permit (NegosyoKonek)',
            variant: AppButtonVariant.outline,
            isSmall: true,
            onPressed: () => _open(context),
          ),
        ],
      ),
    );
  }
}
