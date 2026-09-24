import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/ride_model.dart';
import '../../models/ride_review_model.dart';
import '../../routes/app_routes.dart';
import '../../services/ride_history_service.dart';
import '../../services/ride_review_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/star_rating_widget.dart';

/// STEP 12: Rating & Review Screen.
///
/// Features:
/// 1. Captain profile header derived from the completed [RideRequest].
/// 2. Animated 5-star [StarRatingWidget] with dynamic feedback message.
/// 3. Optional multiline review TextField with 500-character counter.
/// 4. Multi-select quick-feedback [FilterChip] row.
/// 5. "Submit Review" with validation — persists to [RideReviewService] and
///    marks ride as rated via [RideHistoryService].
/// 6. "Skip for now" — navigates home without saving.
/// 7. Duplicate-rating guard — shows a friendly "already rated" view.
class RatingReviewScreen extends StatefulWidget {
  const RatingReviewScreen({
    super.key,
    required this.rideRequest,
  });

  final RideRequest rideRequest;

  @override
  State<RatingReviewScreen> createState() => _RatingReviewScreenState();
}

class _RatingReviewScreenState extends State<RatingReviewScreen> {
  // ── Services ──────────────────────────────────────────────────────────────
  final _reviewService = RideReviewService();
  final _historyService = RideHistoryService();

  // ── Form state ────────────────────────────────────────────────────────────
  int _selectedRating = 0;
  final Set<RatingFeedbackTag> _selectedTags = {};
  final TextEditingController _reviewController = TextEditingController();
  static const int _maxChars = 500;

  // ── Screen state ──────────────────────────────────────────────────────────
  bool _isSubmitting = false;
  bool _submitted = false;
  bool _alreadyRated = false;
  bool _loading = true;
  String? _ratingError;

  @override
  void initState() {
    super.initState();
    _checkAlreadyRated();
    _reviewController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _checkAlreadyRated() async {
    final rated = await _reviewService.hasRated(widget.rideRequest.rideId);
    if (mounted) {
      setState(() {
        _alreadyRated = rated;
        _loading = false;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedRating == 0) {
      setState(() => _ratingError = 'Please select a rating.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _ratingError = null;
    });

    final review = RideReview(
      reviewId: '${widget.rideRequest.rideId}_user',
      rideId: widget.rideRequest.rideId,
      captainId: widget.rideRequest.captain?.id ??
          widget.rideRequest.rideId,
      rating: _selectedRating,
      reviewText: _reviewController.text.trim(),
      feedbackTags: _selectedTags.toList(),
      createdAt: DateTime.now(),
    );

    await _reviewService.submitReview(
      review,
      userId: widget.rideRequest.userId,
      captainId: widget.rideRequest.captain?.id,
    );
    _historyService.markAsRated(
      review.rideId,
      review.reviewId,
      rating: review.rating,
      reviewText: review.reviewText,
      reviewTags: review.feedbackTags.map((t) => t.label).toList(),
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _submitted = true;
      });
    }
  }

  void _handleSkip() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );
  }

  void _handleBackToHome() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_alreadyRated) {
      return _buildAlreadyRatedView();
    }

    if (_submitted) {
      return _buildThankYouView();
    }

    return _buildRatingForm();
  }

  // ── Already Rated View ────────────────────────────────────────────────────

  Scaffold _buildAlreadyRatedView() {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.primary, width: 2.0),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: AppColors.primary,
                    size: 52,
                  ),
                ),
                const SizedBox(height: AppDimensions.space24),
                const Text(
                  'Already Rated',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: AppDimensions.space8),
                const Text(
                  'You have already rated this ride.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppDimensions.space32),
                PrimaryButton(
                  text: 'Back to Home',
                  onPressed: _handleBackToHome,
                  icon: Icons.home_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Thank You View (post-submit) ──────────────────────────────────────────

  Scaffold _buildThankYouView() {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glow Star Badge
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.primary, width: 2.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.primary,
                    size: 52,
                  ),
                ),
                const SizedBox(height: AppDimensions.space24),

                const Text(
                  'Thank You! 🎉',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimaryLight,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppDimensions.space8),
                const Text(
                  'Your feedback helps us improve QuickRide.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondaryLight,
                  ),
                ),

                const SizedBox(height: AppDimensions.space20),

                // Show selected rating as read-only stars
                StarRatingWidget(
                  rating: _selectedRating,
                  onRatingChanged: (_) {},
                  readOnly: true,
                  size: 36,
                ),

                const SizedBox(height: AppDimensions.space32),
                PrimaryButton(
                  text: 'Back to Home',
                  onPressed: _handleBackToHome,
                  icon: Icons.home_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Main Rating Form ──────────────────────────────────────────────────────

  Scaffold _buildRatingForm() {
    final captain = widget.rideRequest.captain ??
        CaptainModel.demo(
            vehicleCategoryTitle:
                widget.rideRequest.selectedVehicle.title);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space16,
                  vertical: AppDimensions.space16,
                ),
                child: Column(
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: AppDimensions.space20),

                    // Captain Card
                    _buildCaptainCard(captain),
                    const SizedBox(height: AppDimensions.space24),

                    // Stars
                    _buildStarSection(),
                    const SizedBox(height: AppDimensions.space20),

                    // Quick Feedback Chips
                    _buildFeedbackChips(),
                    const SizedBox(height: AppDimensions.space20),

                    // Review text field
                    _buildReviewField(),
                    const SizedBox(height: AppDimensions.space24),
                  ],
                ),
              ),
            ),

            // Fixed bottom action bar
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'How was your ride?',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimaryLight,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Rate your experience with your QuickRide captain',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildCaptainCard(CaptainModel captain) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 1.2),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2.0),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  captain.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${captain.vehicleType} • ${captain.vehicleModel}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevatedDark,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Text(
                    captain.vehicleNumber,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Rating badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevatedDark,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded,
                    color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  captain.formattedRating,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarSection() {
    return Column(
      children: [
        // Stars
        StarRatingWidget(
          rating: _selectedRating,
          onRatingChanged: (rating) {
            setState(() {
              _selectedRating = rating;
              _ratingError = null;
            });
          },
        ),

        // Validation error
        if (_ratingError != null) ...[
          const SizedBox(height: 10),
          Text(
            _ratingError!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
        ],

        // Rating message
        if (_selectedRating > 0) ...[
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Container(
              key: ValueKey(_selectedRating),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35)),
              ),
              child: Text(
                RideReview(
                  reviewId: '',
                  rideId: '',
                  captainId: '',
                  rating: _selectedRating,
                  createdAt: DateTime.now(),
                ).ratingMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFeedbackChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Feedback',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondaryLight,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: RatingFeedbackTag.values.map((tag) {
            final selected = _selectedTags.contains(tag);
            return FilterChip(
              key: Key('chip_${tag.name}'),
              label: Text(tag.label),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  if (selected) {
                    _selectedTags.remove(tag);
                  } else {
                    _selectedTags.add(tag);
                  }
                });
              },
              backgroundColor: AppColors.surfaceElevatedDark,
              selectedColor: AppColors.primary.withValues(alpha: 0.18),
              checkmarkColor: AppColors.primary,
              side: BorderSide(
                color: selected ? AppColors.primary : AppColors.borderDark,
                width: selected ? 1.4 : 1.0,
              ),
              labelStyle: TextStyle(
                fontSize: 12.5,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppColors.primary
                    : AppColors.textSecondaryLight,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReviewField() {
    final charCount = _reviewController.text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Write a Review (optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondaryLight,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevatedDark,
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: TextField(
            controller: _reviewController,
            maxLines: 5,
            maxLength: _maxChars,
            style: const TextStyle(
              color: AppColors.textPrimaryLight,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Tell us about your ride...',
              hintStyle: const TextStyle(
                color: AppColors.textMutedDark,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.all(AppDimensions.space16),
              // Hide the built-in counter; we render our own below.
              counterText: '',
            ),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$charCount / $_maxChars',
            style: TextStyle(
              fontSize: 11.5,
              color: charCount >= _maxChars
                  ? AppColors.error
                  : AppColors.textMutedDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border:
            Border(top: BorderSide(color: AppColors.borderDark, width: 1.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            text: 'Submit Review',
            onPressed: _isSubmitting ? null : _handleSubmit,
            icon: _isSubmitting ? null : Icons.send_rounded,
            isLoading: _isSubmitting,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _handleSkip,
            child: const Text(
              'Skip for now',
              style: TextStyle(
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
