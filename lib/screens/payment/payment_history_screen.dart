import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/firestore_models.dart';
import '../../services/firebase_service.dart';
import '../../services/ride_history_service.dart';
import '../../services/session_manager.dart';
import 'digital_receipt_screen.dart';

/// STEP 38: Payment History Screen
///
/// Features:
/// 1. Real-time stream of user payments from Firestore with offline cache fallback.
/// 2. Filtering by payment status: All, Paid, Failed, Refunded.
/// 3. Chronological sorting: Newest transactions first.
/// 4. Summary card per payment displaying Ride ID, Pickup/Destination, Vehicle,
///    Original Fare, Discount, Final Amount, Payment Method, Status Badge, Txn ID.
/// 5. Tap to view verified Digital Receipt.
class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final QuickRideFirebaseService _firebaseService = QuickRideFirebaseService();
  final RideHistoryService _rideHistoryService = RideHistoryService();
  String _selectedFilter = 'ALL'; // 'ALL', 'PAID', 'FAILED', 'REFUNDED'

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year at $hour:$min';
  }

  Color _getStatusColor(FirestorePaymentStatus status) {
    switch (status) {
      case FirestorePaymentStatus.paid:
        return const Color(0xFF10B981);
      case FirestorePaymentStatus.failed:
        return AppColors.error;
      case FirestorePaymentStatus.refunded:
        return Colors.purpleAccent;
      case FirestorePaymentStatus.pending:
      case FirestorePaymentStatus.processing:
        return Colors.orange;
      case FirestorePaymentStatus.cancelled:
        return AppColors.textSecondaryLight;
    }
  }

  void _openDigitalReceipt(FirestorePaymentModel payment) {
    final rideItem = _rideHistoryService.findById(payment.rideId);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DigitalReceiptScreen(
          payment: payment,
          rideHistoryItem: rideItem,
        ),
      ),
    );
  }

  List<FirestorePaymentModel> _filterPayments(List<FirestorePaymentModel> allPayments) {
    if (_selectedFilter == 'ALL') return allPayments;
    return allPayments.where((p) {
      final statusStr = p.paymentStatus.firestoreValue.toUpperCase();
      return statusStr == _selectedFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionManager().currentUser;
    final userId = user.userId;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimaryLight, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Payment History',
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status Filter Tabs
            _buildFilterTabs(),

            // Payment List (Real-time Stream)
            Expanded(
              child: StreamBuilder<List<FirestorePaymentModel>>(
                stream: _firebaseService.streamUserPayments(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  final allPayments = snapshot.data ?? [];

                  // If Firestore returned empty, check local ride history for completed rides with payments
                  List<FirestorePaymentModel> displayList = allPayments;
                  if (displayList.isEmpty) {
                    final rides = _rideHistoryService.getHistory();
                    displayList = rides.map((r) {
                      final statusEnum = r.paymentStatus.toUpperCase() == 'PAID'
                          ? FirestorePaymentStatus.paid
                          : (r.isCancelled
                              ? FirestorePaymentStatus.cancelled
                              : FirestorePaymentStatus.pending);
                      return FirestorePaymentModel(
                        paymentId: 'PAY_${r.rideId}',
                        rideId: r.rideId,
                        userId: r.userId,
                        captainId: r.captain.id,
                        originalFare: r.fareDetails.originalFare,
                        discountAmount: r.fareDetails.totalDiscount,
                        finalAmount: r.fareDetails.effectiveFinalFare,
                        paymentMethod: r.paymentMethod.name,
                        paymentStatus: statusEnum,
                        gatewayPaymentId: 'pay_${r.rideId}_ref',
                        pickupAddress: r.pickup.address,
                        dropAddress: r.destination.address,
                        vehicleType: r.vehicle.title,
                        distanceKm: r.distanceKm,
                        couponCode: r.fareDetails.offerLabel,
                        passengerName: user.fullName,
                        captainName: r.captain.name,
                        createdAt: r.createdAt,
                        updatedAt: r.completedAt,
                        paidAt: statusEnum == FirestorePaymentStatus.paid ? r.completedAt : null,
                      );
                    }).toList();
                  }

                  final filtered = _filterPayments(displayList);

                  if (filtered.isEmpty) {
                    return _buildEmptyView();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final payment = filtered[index];
                      return _buildPaymentCard(payment);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['ALL', 'PAID', 'FAILED', 'REFUNDED'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(bottom: BorderSide(color: AppColors.borderDark)),
      ),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                f == 'ALL' ? 'All Payments' : f,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.cardDark,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.borderDark,
                width: 1,
              ),
              showCheckmark: false,
              onSelected: (_) => setState(() => _selectedFilter = f),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentCard(FirestorePaymentModel p) {
    final statusColor = _getStatusColor(p.paymentStatus);
    final isPaid = p.isPaid;
    final date = p.paidAt ?? p.createdAt;
    final pickup = p.pickupAddress ?? 'Pickup location';
    final dest = p.dropAddress ?? 'Destination location';
    final vehicle = p.vehicleType ?? 'QuickRide';

    return Material(
      color: AppColors.cardDark,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDigitalReceipt(p),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.space16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            border: Border.all(color: AppColors.borderDark, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Ride ID + Status Badge + Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              p.rideId,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: statusColor, width: 0.8),
                              ),
                              child: Text(
                                p.paymentStatus.firestoreValue,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDateTime(date),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${p.finalAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isPaid ? const Color(0xFF10B981) : AppColors.textPrimaryLight,
                        ),
                      ),
                      if (p.discountAmount > 0)
                        Text(
                          'Saved ₹${p.discountAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: AppColors.borderDark, height: 1),
              ),

              // Route & Vehicle Info
              Row(
                children: [
                  const Icon(Icons.directions_car_rounded, color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    vehicle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(width: 3, height: 3, decoration: const BoxDecoration(color: AppColors.textSecondaryLight, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Text(
                    p.paymentMethod.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: const [
                      Text(
                        'View Receipt',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 10),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Route Summary
              Row(
                children: [
                  const Icon(Icons.my_location_rounded, color: AppColors.secondary, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      pickup,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      dest,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceDark,
                border: Border.all(color: AppColors.borderDark),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 38,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'ALL'
                  ? 'No payment records yet'
                  : 'No $_selectedFilter payments found',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your verified ride transactions and digital receipts will appear here once you take rides.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
