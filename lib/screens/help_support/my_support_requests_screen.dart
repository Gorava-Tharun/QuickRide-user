import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/support_request_model.dart';
import '../../services/support_service.dart';
import 'report_issue_screen.dart';
import 'support_request_details_screen.dart';

/// Screen listing all past support requests submitted by the user with filtering and search.
class MySupportRequestsScreen extends StatefulWidget {
  const MySupportRequestsScreen({super.key});

  @override
  State<MySupportRequestsScreen> createState() => _MySupportRequestsScreenState();
}

class _MySupportRequestsScreenState extends State<MySupportRequestsScreen> {
  String _selectedFilter = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SupportRequest> _filterRequests(List<SupportRequest> requests) {
    return requests.where((r) {
      // Status filter
      if (_selectedFilter == 'OPEN' && r.status != SupportStatus.open) return false;
      if (_selectedFilter == 'IN_REVIEW' && r.status != SupportStatus.inReview) return false;
      if (_selectedFilter == 'RESOLVED' && r.status != SupportStatus.resolved) return false;
      if (_selectedFilter == 'CLOSED' && r.status != SupportStatus.closed) return false;

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesId = r.requestId.toLowerCase().contains(q);
        final matchesSubject = r.subject.toLowerCase().contains(q);
        final matchesIssue = r.issueType.toLowerCase().contains(q);
        final matchesCategory = r.category.title.toLowerCase().contains(q);
        final matchesRide = r.rideId?.toLowerCase().contains(q) ?? false;
        final matchesPayment = r.paymentId?.toLowerCase().contains(q) ?? false;
        return matchesId || matchesSubject || matchesIssue || matchesCategory || matchesRide || matchesPayment;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final supportService = SupportService();

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
          'My Complaints & Tickets',
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: supportService,
          builder: (context, _) {
            final allRequests = supportService.getSupportRequests();
            final filtered = _filterRequests(allRequests);

            return Column(
              children: [
                // Search Box
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space16,
                    vertical: AppDimensions.space8,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Search complaints by ID, subject, ride...',
                      hintStyle: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondaryLight, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surfaceDark,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        borderSide: const BorderSide(color: AppColors.borderDark),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        borderSide: const BorderSide(color: AppColors.borderDark),
                      ),
                    ),
                  ),
                ),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: 4),
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', 'All (${allRequests.length})'),
                      _buildFilterChip(
                        'OPEN',
                        'Open (${allRequests.where((r) => r.status == SupportStatus.open).length})',
                      ),
                      _buildFilterChip(
                        'IN_REVIEW',
                        'In Review (${allRequests.where((r) => r.status == SupportStatus.inReview).length})',
                      ),
                      _buildFilterChip(
                        'RESOLVED',
                        'Resolved (${allRequests.where((r) => r.status == SupportStatus.resolved).length})',
                      ),
                      _buildFilterChip(
                        'CLOSED',
                        'Closed (${allRequests.where((r) => r.status == SupportStatus.closed).length})',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // Complaint Cards List or Empty
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState(context, allRequests.isEmpty)
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.space16,
                            vertical: AppDimensions.space12,
                          ),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.space12),
                          itemBuilder: (context, index) {
                            final req = filtered[index];
                            return _buildRequestCard(context, req);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.backgroundDark,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'File Complaint',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ReportIssueScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String code, String label) {
    final isSelected = _selectedFilter == code;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppColors.backgroundDark : AppColors.textSecondaryLight,
          ),
        ),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surfaceDark,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.borderDark,
        ),
        onSelected: (_) => setState(() => _selectedFilter = code),
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, SupportRequest req) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 1.1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SupportRequestDetailsScreen(request: req),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: ID, Priority badge, Status badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Request #${req.requestId}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Row(
                      children: [
                        if (req.priority == SupportPriority.high || req.priority == SupportPriority.urgent) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: req.priority.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                              border: Border.all(color: req.priority.color.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              req.priority.label.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: req.priority.color,
                              ),
                            ),
                          ),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: req.status.badgeColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                            border: Border.all(color: req.status.badgeColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            req.status.label,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: req.status.badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Category & Subject
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: req.category.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      ),
                      child: Icon(req.category.icon, color: req.category.accentColor, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Category: ${req.category.title}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Issue: ${req.issueType}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Description snippet
                Text(
                  req.description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondaryLight,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Bottom row: Linked IDs, date, View details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      req.formattedCreatedAt,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    Row(
                      children: const [
                        Text(
                          'View Ticket',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isCompletelyEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevatedDark,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderDark),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                size: 40,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppDimensions.space20),
            Text(
              isCompletelyEmpty ? 'No Support Complaints' : 'No Matching Complaints',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCompletelyEmpty
                  ? 'You have not submitted any customer support complaints yet. If you ever experience any issue, submit a ticket and our team will resolve it.'
                  : 'No complaints match the selected filter or search term. Try adjusting your search.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppDimensions.space24),
            OutlinedButton.icon(
              icon: const Icon(Icons.add_rounded, color: AppColors.primary),
              label: Text(
                isCompletelyEmpty ? 'Submit a Complaint' : 'Clear Filters',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                ),
              ),
              onPressed: () {
                if (isCompletelyEmpty) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ReportIssueScreen(),
                    ),
                  );
                } else {
                  setState(() {
                    _selectedFilter = 'ALL';
                    _searchQuery = '';
                    _searchController.clear();
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
