import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../models/ride_history_model.dart';
import '../../models/ride_model.dart';
import '../../routes/app_routes.dart';
import '../../services/ride_history_service.dart';
import '../../widgets/primary_button.dart';
import '../offers/offers_screen.dart';
import '../profile/profile_screen.dart';
import 'ride_details_screen.dart';
import 'widgets/ride_history_card.dart';

enum RideHistoryFilter { all, completed, cancelled }

/// STEP 13: Ride History Screen.
///
/// Features:
/// 1. "My Rides" header with responsive Material 3 dark layout.
/// 2. Live search bar filtering by pickup, destination, captain, and vehicle.
/// 3. Filter tabs: All, Completed, Cancelled with dynamic ride counts.
/// 4. Newest rides displayed first using stored timestamps.
/// 5. High-performance [ListView.builder] rendering.
/// 6. Empty state illustration with "Book a Ride" CTA.
/// 7. Integrated Bottom Navigation with "My Rides" active.
class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  final _historyService = RideHistoryService();
  final _searchController = TextEditingController();

  RideHistoryFilter _selectedFilter = RideHistoryFilter.all;
  List<RideHistoryItem> _allRides = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  void _loadHistory() {
    setState(() {
      _allRides = _historyService.getHistory();
    });
  }

  List<RideHistoryItem> get _filteredRides {
    return _allRides.where((ride) {
      // 1. Status Filter
      if (_selectedFilter == RideHistoryFilter.completed &&
          ride.status != RideStatus.rideCompleted) {
        return false;
      }
      if (_selectedFilter == RideHistoryFilter.cancelled &&
          ride.status != RideStatus.cancelled) {
        return false;
      }

      // 2. Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final matchesPickup = ride.pickup.name.toLowerCase().contains(_searchQuery) ||
            ride.pickup.address.toLowerCase().contains(_searchQuery);
        final matchesDestination =
            ride.destination.name.toLowerCase().contains(_searchQuery) ||
                ride.destination.address.toLowerCase().contains(_searchQuery);
        final matchesCaptain =
            ride.captain.name.toLowerCase().contains(_searchQuery);
        final matchesVehicle =
            ride.vehicle.title.toLowerCase().contains(_searchQuery) ||
                ride.captain.vehicleModel.toLowerCase().contains(_searchQuery);

        return matchesPickup ||
            matchesDestination ||
            matchesCaptain ||
            matchesVehicle;
      }

      return true;
    }).toList();
  }

  int _countForFilter(RideHistoryFilter filter) {
    switch (filter) {
      case RideHistoryFilter.all:
        return _allRides.length;
      case RideHistoryFilter.completed:
        return _allRides
            .where((r) => r.status == RideStatus.rideCompleted)
            .length;
      case RideHistoryFilter.cancelled:
        return _allRides.where((r) => r.status == RideStatus.cancelled).length;
    }
  }

  Future<void> _openRideDetails(RideHistoryItem ride) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RideDetailsScreen(ride: ride),
      ),
    );
    // Refresh history in case rating was updated inside details
    _loadHistory();
  }

  void _navigateToHome() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedRides = _filteredRides;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimaryLight, size: 18),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text(
          'My Rides',
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Payment History',
            icon: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 22),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.paymentHistory),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filter Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space12,
              ),
              color: AppColors.surfaceDark,
              child: Column(
                children: [
                  // Search Field
                  _buildSearchField(),
                  const SizedBox(height: AppDimensions.space12),

                  // Filter Chips Row
                  _buildFilterChips(),
                ],
              ),
            ),

            // Rides List or Empty State
            Expanded(
              child: displayedRides.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppDimensions.space16),
                      itemCount: displayedRides.length,
                      itemBuilder: (context, index) {
                        final ride = displayedRides[index];
                        return RideHistoryCard(
                          ride: ride,
                          onTap: () => _openRideDetails(ride),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          color: AppColors.textPrimaryLight,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Search rides',
          hintStyle: const TextStyle(
            color: AppColors.textMutedDark,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondaryLight, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: [
        _buildFilterChip(
          title: 'All',
          filter: RideHistoryFilter.all,
          count: _countForFilter(RideHistoryFilter.all),
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          title: 'Completed',
          filter: RideHistoryFilter.completed,
          count: _countForFilter(RideHistoryFilter.completed),
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          title: 'Cancelled',
          filter: RideHistoryFilter.cancelled,
          count: _countForFilter(RideHistoryFilter.cancelled),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String title,
    required RideHistoryFilter filter,
    required int count,
  }) {
    final isSelected = _selectedFilter == filter;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : AppColors.surfaceElevatedDark,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderDark,
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$title ($count)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.black : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty State Visual Container
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  width: 2.0,
                ),
              ),
              child: const Icon(
                Icons.directions_car_filled_rounded,
                color: AppColors.primary,
                size: 44,
              ),
            ),
            const SizedBox(height: AppDimensions.space20),

            const Text(
              'No rides yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimaryLight,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your completed rides will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppDimensions.space24),

            SizedBox(
              width: 200,
              child: PrimaryButton(
                text: 'Book a Ride',
                onPressed: _navigateToHome,
                icon: Icons.add_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.borderDark, width: 1.0)),
      ),
      child: BottomNavigationBar(
        currentIndex: 1, // "My Rides" active
        onTap: (index) {
          if (index == 0) {
            _navigateToHome();
          } else if (index == 1) {
            // Already on My Rides
          } else if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const OffersScreen(),
              ),
            );
          } else if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ProfileScreen(),
              ),
            );
          }
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondaryLight,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: AppStrings.navHome,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: AppStrings.navMyRides,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer_rounded),
            label: AppStrings.navOffers,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: AppStrings.navProfile,
          ),
        ],
      ),
    );
  }
}
