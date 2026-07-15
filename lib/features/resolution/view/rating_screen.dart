import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_button.dart';

class RatingScreen extends StatefulWidget {
  /// Tenant-side variant: rate the property after booking a room.
  const RatingScreen({
    this.subjectName = 'Sunshine Boarding House',
    this.moveInLabel = 'Move-in: August 1, 2026',
    super.key,
  })  : isOwnerView = false,
        subjectInitials = null;

  /// Owner-side variant: rate the tenant after confirming their booking.
  const RatingScreen.forOwner({
    required this.subjectName,
    required String this.subjectInitials,
    this.moveInLabel = 'Move-in: August 1, 2026',
    super.key,
  }) : isOwnerView = true;

  /// Who or what is being rated — the property name on the tenant side,
  /// the tenant name on the owner side.
  final String subjectName;

  /// Tenant initials shown in the header avatar (owner view only).
  final String? subjectInitials;

  final String moveInLabel;
  final bool isOwnerView;

  String get _heading => isOwnerView ? 'Tenant booked in!' : 'Room booked!';

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

  void _submit() {
    Navigator.of(context).pop();
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
              const SizedBox(height: 48),
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
                    : const Icon(Icons.check, color: Colors.white, size: 44),
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
                            : AppColors.border,
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
                    color: AppColors.textHint,
                    fontSize: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
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
                label: 'Submit Rating',
                color: AppColors.ink,
                onPressed: _starRating > 0 ? _submit : null,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
