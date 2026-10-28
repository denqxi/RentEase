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
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => const _RejectReasonDialog(),
    );
    if (reason != null) cubit.reject(ownerId, reason: reason);
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
                        const SizedBox(width: AppSpacing.sm),
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
                            const SizedBox(height: AppSpacing.sm),
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
              const SizedBox(width: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Reason: ${item.profile.rejectionReason}',
              style: AppTextStyles.caption(context),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _DocumentsSection(
            documents: documents,
            onOpen: onOpenDocuments,
            ownerName: item.ownerName,
            urlOpener: urlOpener,
            onApprove: onApprove,
            onReject: onReject,
          ),
          if (isBusy) ...[
            const SizedBox(height: AppSpacing.md),
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
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Approve',
                    isSmall: true,
                    onPressed: onApprove,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
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

  @override
  Widget build(BuildContext context) {
    final docs = documents;
    if (docs == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onOpen,
          icon: const Icon(
            Icons.description_rounded,
            size: 15,
            color: AppColors.accent,
          ),
          label: const Text(
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

    final hasMultipleDocs = count >= 3;
    final frontUrl = docs.urls.isNotEmpty ? docs.urls[0] : null;
    final frontPublicId = docs.publicIds.isNotEmpty ? docs.publicIds[0] : null;
    final backUrl =
        (hasMultipleDocs && docs.urls.length > 1) ? docs.urls[1] : null;
    final backPublicId =
        (hasMultipleDocs && docs.publicIds.length > 1) ? docs.publicIds[1] : null;

    final propertyUrl = hasMultipleDocs
        ? (docs.urls.length > 2 ? docs.urls[2] : null)
        : (docs.urls.length > 1 ? docs.urls[1] : null);
    final propertyPublicId = hasMultipleDocs
        ? (docs.publicIds.length > 2 ? docs.publicIds[2] : null)
        : (docs.publicIds.length > 1 ? docs.publicIds[1] : null);

    final permitUrl =
        hasMultipleDocs && docs.urls.length > 3 ? docs.urls[3] : null;
    final permitPublicId =
        hasMultipleDocs && docs.publicIds.length > 3 ? docs.publicIds[3] : null;

    final hasBackId = backUrl != null || backPublicId != null;

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
        const SizedBox(height: 6),
        if (hasBackId) ...[
          _DocumentRow(
            label: 'Government ID (Front)',
            publicId: frontPublicId,
            url: frontUrl,
            secondaryTitle: 'Government ID (Back)',
            secondaryUrl: backUrl,
            secondaryPublicId: backPublicId,
            initialSideIsSecondary: false,
            primaryLabel: 'Front side',
            secondaryLabel: 'Back side',
            ownerName: ownerName,
            urlOpener: urlOpener,
            onApprove: onApprove,
            onReject: onReject,
          ),
          _DocumentRow(
            label: 'Government ID (Back)',
            publicId: backPublicId,
            url: backUrl,
            secondaryTitle: 'Government ID (Front)',
            secondaryUrl: frontUrl,
            secondaryPublicId: frontPublicId,
            initialSideIsSecondary: false,
            primaryLabel: 'Back side',
            secondaryLabel: 'Front side',
            ownerName: ownerName,
            urlOpener: urlOpener,
            onApprove: onApprove,
            onReject: onReject,
          ),
        ] else
          _DocumentRow(
            label: 'Government ID',
            publicId: frontPublicId,
            url: frontUrl,
            ownerName: ownerName,
            urlOpener: urlOpener,
            onApprove: onApprove,
            onReject: onReject,
          ),
        if (propertyUrl != null || propertyPublicId != null)
          _DocumentRow(
            label: 'Property ownership document',
            publicId: propertyPublicId,
            url: propertyUrl,
            ownerName: ownerName,
            urlOpener: urlOpener,
            onApprove: onApprove,
            onReject: onReject,
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'No property ownership document submitted.',
              style: AppTextStyles.caption(context),
            ),
          ),
        if (permitUrl != null || permitPublicId != null)
          _DocumentRow(
            label: 'Business permit',
            publicId: permitPublicId,
            url: permitUrl,
            ownerName: ownerName,
            urlOpener: urlOpener,
            isPermit: true,
            onApprove: onApprove,
            onReject: onReject,
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'No business permit submitted (optional).',
              style: AppTextStyles.caption(context),
            ),
          ),
        BusinessPermitCheckButton(ownerName: ownerName, urlOpener: urlOpener),
        if (hasMultipleDocs && count > 4)
          for (var i = 4; i < count; i++)
            _DocumentRow(
              label: 'Document ${i + 1}',
              publicId: i < docs.publicIds.length ? docs.publicIds[i] : null,
              url: i < docs.urls.length ? docs.urls[i] : null,
              ownerName: ownerName,
              urlOpener: urlOpener,
              onApprove: onApprove,
              onReject: onReject,
            ),
      ],
    );
  }
}

const documentLoadErrorMessage =
    'Could not load this document. If the file is private in Cloudinary, '
    'set the documents upload preset delivery type to Upload (public) or '
    'open it in the Cloudinary Media Library';

/// Full-screen, pinch-zoomable document viewer with support for switching
/// between Front and Back sides of multi-sided documents (like IDs).
/// Approve/Reject stay reachable so the admin keeps the document in view while deciding.
class DocumentViewerDialog extends StatefulWidget {
  const DocumentViewerDialog({
    super.key,
    required this.title,
    required this.url,
    required this.reference,
    this.secondaryTitle,
    this.secondaryUrl,
    this.secondaryReference,
    this.primaryLabel = 'Front side',
    this.secondaryLabel = 'Back side',
    this.initialSideIsSecondary = false,
    this.onApprove,
    this.onReject,
    this.permitCheck,
  });

  final String title;
  final String url;
  final String reference;
  final String? secondaryTitle;
  final String? secondaryUrl;
  final String? secondaryReference;
  final String primaryLabel;
  final String secondaryLabel;
  final bool initialSideIsSecondary;

  /// Set for the business permit only; shows the NegosyoKonek lookup button.
  final ({String ownerName, UrlOpener urlOpener})? permitCheck;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  State<DocumentViewerDialog> createState() => _DocumentViewerDialogState();
}

class _DocumentViewerDialogState extends State<DocumentViewerDialog> {
  late bool _showSecondary = widget.initialSideIsSecondary &&
      widget.secondaryUrl != null &&
      widget.secondaryUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final hasSecondary =
        widget.secondaryUrl != null && widget.secondaryUrl!.isNotEmpty;
    final currentTitle = _showSecondary
        ? (widget.secondaryTitle ?? widget.title)
        : widget.title;
    final currentUrl = _showSecondary ? widget.secondaryUrl! : widget.url;
    final currentReference = _showSecondary
        ? (widget.secondaryReference ?? widget.reference)
        : widget.reference;

    return Dialog.fullscreen(
      backgroundColor: AppColors.ink,
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded, color: AppColors.onInk),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    currentTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onInk,
                    ),
                  ),
                ),
              ],
            ),
            if (hasSecondary)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.xs,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.onInk.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SideToggleButton(
                        label: widget.primaryLabel,
                        isSelected: !_showSecondary,
                        onTap: () {
                          if (_showSecondary) {
                            setState(() => _showSecondary = false);
                          }
                        },
                      ),
                      _SideToggleButton(
                        label: widget.secondaryLabel,
                        isSelected: _showSecondary,
                        onTap: () {
                          if (!_showSecondary) {
                            setState(() => _showSecondary = true);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: InteractiveViewer(
                key: ValueKey(currentUrl),
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: Image.network(
                    CloudinaryUrl.optimized(currentUrl, width: 1600),
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
                            const Text(
                              documentLoadErrorMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                color: AppColors.onInk,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            SelectableText(
                              currentReference,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                color: AppColors.hint,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: currentReference.isEmpty
                                  ? null
                                  : () {
                                      Clipboard.setData(
                                        ClipboardData(text: currentReference),
                                      );
                                      showAdminNotice(context, 'Copied');
                                    },
                              icon: const Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              label: const Text(
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
            if (widget.permitCheck != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: BusinessPermitCheckButton(
                  ownerName: widget.permitCheck!.ownerName,
                  urlOpener: widget.permitCheck!.urlOpener,
                  onDark: true,
                ),
              ),
            if (widget.onApprove != null || widget.onReject != null)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    if (widget.onApprove != null)
                      Expanded(
                        child: AppButton(
                          label: 'Approve',
                          isSmall: true,
                          onPressed: widget.onApprove,
                        ),
                      ),
                    if (widget.onApprove != null && widget.onReject != null)
                      const SizedBox(width: AppSpacing.sm),
                    if (widget.onReject != null)
                      Expanded(
                        child: AppButton(
                          label: 'Reject',
                          variant: AppButtonVariant.destructiveOutline,
                          isSmall: true,
                          onPressed: widget.onReject,
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

class _SideToggleButton extends StatelessWidget {
  const _SideToggleButton({
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
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? AppColors.onInk
                : AppColors.onInk.withValues(alpha: 0.75),
          ),
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
    this.secondaryTitle,
    this.secondaryUrl,
    this.secondaryPublicId,
    this.primaryLabel = 'Front side',
    this.secondaryLabel = 'Back side',
    this.initialSideIsSecondary = false,
    this.onApprove,
    this.onReject,
  });

  final String label;
  final String ownerName;
  final UrlOpener urlOpener;
  final bool isPermit;
  final String? publicId;
  final String? url;
  final String? secondaryTitle;
  final String? secondaryUrl;
  final String? secondaryPublicId;
  final String primaryLabel;
  final String secondaryLabel;
  final bool initialSideIsSecondary;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  String get _reference =>
      (publicId != null && publicId!.isNotEmpty) ? publicId! : (url ?? '');

  void _openViewer(BuildContext context) {
    final bRef = (secondaryPublicId != null && secondaryPublicId!.isNotEmpty)
        ? secondaryPublicId!
        : (secondaryUrl ?? '');

    showDialog<void>(
      context: context,
      builder: (ctx) => DocumentViewerDialog(
        title: '$label - $ownerName',
        url: url!,
        reference: _reference,
        secondaryTitle:
            secondaryTitle != null ? '$secondaryTitle - $ownerName' : null,
        secondaryUrl: secondaryUrl,
        secondaryReference: bRef.isNotEmpty ? bRef : null,
        primaryLabel: primaryLabel,
        secondaryLabel: secondaryLabel,
        initialSideIsSecondary: initialSideIsSecondary,
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
                          child: const Icon(
                            Icons.broken_image_rounded,
                            color: AppColors.hint,
                          ),
                        ),
                      )
                    : Container(
                        color: context.appColors.surface,
                        child: const Icon(
                          Icons.description_rounded,
                          color: AppColors.hint,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: hasUrl ? () => _openViewer(context) : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
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
          ),
          IconButton(
            tooltip: 'Copy public ID',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.accent),
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
      const SnackBar(
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
                ? const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    color: AppColors.hint,
                  )
                : AppTextStyles.caption(context),
          ),
          const SizedBox(height: 4),
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


class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog();

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  late final TextEditingController _reasonCtrl;

  @override
  void initState() {
    super.initState();
    _reasonCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.appColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Reject verification',
        style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reason for rejection (optional):',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _reasonCtrl,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: 'Enter reason...',
                filled: true,
                fillColor: context.appColors.fieldFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.field),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: context.appColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_reasonCtrl.text),
          child: const Text(
            'Reject',
            style: TextStyle(
              color: AppColors.destructive,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
