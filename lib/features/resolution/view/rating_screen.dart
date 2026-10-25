import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_button.dart';

class RatingScreen extends StatefulWidget {
  /// Tenant-side variant: rate the property after booking a room.
  const RatingScreen({
    this.subjectName = 'Sunshine Boarding House',
    this.moveInLabel = 'Move-in: August 1, 2026',
    this.onSubmit,
    super.key,
  })  : isOwnerView = false,
        subjectInitials = null;

  /// Owner-side variant: rate the tenant after confirming their booking.
  const RatingScreen.forOwner({
    required this.subjectName,
    required String this.subjectInitials,
    this.moveInLabel = 'Move-in: August 1, 2026',
    this.onSubmit,
    super.key,
  }) : isOwnerView = true;

  /// Persists the rating; resolves to whether it succeeded (failures are
  /// surfaced by the caller). Null only in preview/screenshot contexts.
  final Future<bool> Function(int stars, String review)? onSubmit;

  /// Who or what is being rated — the property name on the tenant side,
  /// the tenant name on the owner side.
  final String subjectName;

  /// Tenant initials shown in the header avatar (owner view only).
  final String? subjectInitials;

  final String moveInLabel;
  final bool isOwnerView;

  String get _heading => 'Stay confirmed!';

  String get _prompt =>
      isOwnerView ? 'Rate this tenant' : 'Rate your experience';

  String get _reviewHint => isOwnerView
      ? 'Share your experience with this tenant — future landlords will '
          'see this on their credibility profile...'
      : 'Share your experience with this boarding house...';

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _starRating = 0;
  final _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  bool _submitting = false;

  Future<void> _submit() async {
    if (_submitting) return;
    final onSubmit = widget.onSubmit;
    if (onSubmit == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _submitting = true);
    try {
      final ok = await onSubmit(_starRating, _reviewController.text);
      if (!mounted) return;
      setState(() => _submitting = false);
      if (!ok) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks — your rating was submitted.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.destructive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              // Top Bar with Back Button
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.fieldFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.slate200,
                        width: 0.8,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 19,
                      color: AppColors.slate900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Owner view: tenant initials avatar. Tenant view: check circle.
              CircleAvatar(
                radius: 44,
                backgroundColor:
                    widget.isOwnerView ? AppColors.accentSoft : AppColors.ink,
                child: widget.isOwnerView
                    ? Text(
                        widget.subjectInitials!,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      )
                    : const Icon(Icons.check, color: AppColors.onInk, size: 44),
              ),
              const SizedBox(height: 20),
              Text(
                widget._heading,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subjectName,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.moveInLabel,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget._prompt,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setState(() => _starRating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < _starRating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: i < _starRating
                            ? AppColors.amberPrimary
                            : AppColors.fieldBorder,
                        size: 40,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              // Review text area
              TextField(
                controller: _reviewController,
                maxLines: 5,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.fieldFill,
                  hintText: widget._reviewHint,
                  hintStyle: const TextStyle(
                    color: AppColors.hint,
                    fontSize: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.fieldBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.fieldBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.ink),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: _submitting ? 'Submitting...' : 'Submit Rating',
                color: AppColors.ink,
                onPressed: _starRating > 0 && !_submitting ? _submit : null,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
