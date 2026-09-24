import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/support_request_model.dart';
import 'my_support_requests_screen.dart';
import 'report_issue_screen.dart';

/// STEP 17: Comprehensive Help & Customer Support Screen.
///
/// Features:
/// - Real-time FAQ search filtering across keywords/categories
/// - Expandable FAQ cards with in-app deep links (e.g. to My Rides, Offers)
/// - Support Categories grid with direct issue reporting
/// - Dedicated Safety First section with guidelines & safety report action
/// - Contact Support placeholders (Chat with Support, Email Support)
/// - Fast navigation to My Support Requests
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<FaqItem> _allFaqs = FaqItem.defaultFaqs;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FaqItem> get _filteredFaqs {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _allFaqs;

    return _allFaqs.where((faq) {
      final matchesQuestion = faq.question.toLowerCase().contains(query);
      final matchesAnswer = faq.answer.toLowerCase().contains(query);
      final matchesCategory = faq.category.toLowerCase().contains(query);
      final matchesKeywords = faq.keywords.any((k) => k.toLowerCase().contains(query));

      return matchesQuestion || matchesAnswer || matchesCategory || matchesKeywords;
    }).toList();
  }

  void _showPlaceholderDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        title: Row(
          children: [
            const Icon(Icons.headset_mic_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimaryLight,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: AppColors.textSecondaryLight,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToReport(SupportCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportIssueScreen(initialCategory: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final faqs = _filteredFaqs;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimaryLight,
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.primary,
            ),
            tooltip: 'My Requests',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MySupportRequestsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16,
            vertical: AppDimensions.space8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Banner
              _buildHeaderBanner(),
              const SizedBox(height: AppDimensions.space16),

              // 2. Search Field
              _buildSearchField(),
              const SizedBox(height: AppDimensions.space20),

              // 3. Support Categories ("What do you need help with?")
              _buildSupportCategoriesSection(),
              const SizedBox(height: AppDimensions.space24),

              // 4. FAQ Section
              _buildFaqSection(faqs),
              const SizedBox(height: AppDimensions.space24),

              // 5. Safety First Section
              _buildSafetySection(),
              const SizedBox(height: AppDimensions.space24),

              // 6. Contact QuickRide Support Section
              _buildContactSupportSection(),
              const SizedBox(height: AppDimensions.space24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'How can we help you?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimaryLight,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Find quick answers, browse helpful guides, or report an issue directly to our support team.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          color: AppColors.textPrimaryLight,
          fontSize: 14,
        ),
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search for help (e.g. Ride, Fare, Cancel, Coupon)',
          hintStyle: const TextStyle(
            color: AppColors.textSecondaryLight,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: AppColors.textSecondaryLight,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16,
            vertical: 14.0,
          ),
        ),
      ),
    );
  }

  Widget _buildSupportCategoriesSection() {
    const categories = [
      SupportCategory.rideIssue,
      SupportCategory.captainIssue,
      SupportCategory.paymentIssue,
      SupportCategory.pickupDestinationIssue,
      SupportCategory.offerCouponIssue,
      SupportCategory.accountIssue,
      SupportCategory.safetyIssue,
      SupportCategory.other,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'WHAT DO YOU NEED HELP WITH?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.primary,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MySupportRequestsScreen(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 24),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'My Requests',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space12),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.1,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final cat = categories[index];
            return Material(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                onTap: () => _navigateToReport(cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cat.accentColor.withValues(alpha: 0.16),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusSmall),
                        ),
                        child: Icon(cat.icon, color: cat.accentColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cat.title,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFaqSection(List<FaqItem> faqs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'FREQUENTLY ASKED QUESTIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.primary,
              ),
            ),
            if (_searchQuery.isNotEmpty)
              Text(
                '${faqs.length} results',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryLight,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.space12),

        if (faqs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.space20),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.search_off_rounded,
                  size: 36,
                  color: AppColors.textSecondaryLight,
                ),
                const SizedBox(height: 10),
                Text(
                  'No FAQs found matching "$_searchQuery"',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Try searching for Ride, Captain, Payment, Account, Offers, or Cancellation.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...faqs.map((faq) => _buildFaqCard(faq)),
      ],
    );
  }

  Widget _buildFaqCard(FaqItem faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Material(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
          ),
        child: ExpansionTile(
          key: PageStorageKey('faq_${faq.id}'),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textSecondaryLight,
          title: Text(
            faq.question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppDimensions.space16,
            0,
            AppDimensions.space16,
            AppDimensions.space16,
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: AppColors.borderDark, height: 1),
            const SizedBox(height: 10),
            Text(
              faq.answer,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryLight,
                height: 1.45,
              ),
            ),
            if (faq.actionLabel != null && faq.actionRoute != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(faq.actionRoute!);
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: Text(
                    faq.actionLabel!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildSafetySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.shield_rounded, color: Color(0xFFEF4444), size: 22),
              SizedBox(width: 8),
              Text(
                'Safety First',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSafetyTip(Icons.verified_user_rounded, 'Verify vehicle details & license plate before boarding.'),
          _buildSafetyTip(Icons.badge_rounded, 'Check your captain’s photo, name, and rating in the app.'),
          _buildSafetyTip(Icons.share_location_rounded, 'Share your live trip with loved ones (coming soon).'),
          _buildSafetyTip(Icons.emergency_rounded, 'Contact local emergency services immediately if in danger.'),
          const SizedBox(height: 14),

          OutlinedButton.icon(
            onPressed: () => _navigateToReport(SupportCategory.safetyIssue),
            icon: const Icon(Icons.report_problem_rounded, color: Color(0xFFEF4444), size: 18),
            label: const Text(
              'Report a Safety Issue',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              side: const BorderSide(color: Color(0xFFEF4444)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFEF4444).withValues(alpha: 0.8), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondaryLight,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSupportSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.headset_mic_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Contact QuickRide Support',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Need to speak directly with an agent? Our support specialists are available 24/7.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondaryLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showPlaceholderDialog(
                      'Live Support',
                      'Live support will be available in a future version.',
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text(
                    'Chat with Support',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(0, 44),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showPlaceholderDialog(
                      'Email Support',
                      'Live support will be available in a future version.',
                    );
                  },
                  icon: const Icon(Icons.mail_outline_rounded, size: 18),
                  label: const Text(
                    'Email Support',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimaryLight,
                    minimumSize: const Size(0, 44),
                    side: const BorderSide(color: AppColors.borderDark),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
