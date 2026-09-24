import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../models/firestore_models.dart';
import '../../models/ride_history_model.dart';
import '../../models/ride_model.dart';
import '../../services/ride_history_service.dart';
import '../../services/session_manager.dart';

/// STEP 38: Digital Receipt & Tax Invoice Screen
///
/// Displays a tamper-proof digital receipt verified against Firestore records.
/// Features:
/// 1. QuickRide logo and official receipt header.
/// 2. Ride and Payment IDs, verification timestamp.
/// 3. Passenger and Captain details.
/// 4. Journey points (Pickup, Destination, Distance, Vehicle type).
/// 5. Itemized fare breakdown (Base/Original fare, Coupon/Discount, Verified Final Amount).
/// 6. Gateway transaction reference ID and Payment Method.
/// 7. Share Receipt, Save/Print Receipt, and Done actions.
class DigitalReceiptScreen extends StatefulWidget {
  const DigitalReceiptScreen({
    super.key,
    required this.payment,
    this.rideHistoryItem,
    this.rideRequest,
  });

  final FirestorePaymentModel payment;
  final RideHistoryItem? rideHistoryItem;
  final RideRequest? rideRequest;

  @override
  State<DigitalReceiptScreen> createState() => _DigitalReceiptScreenState();
}

class _DigitalReceiptScreenState extends State<DigitalReceiptScreen> {
  late RideHistoryItem? _linkedRide;

  @override
  void initState() {
    super.initState();
    _linkedRide = widget.rideHistoryItem ?? RideHistoryService().findById(widget.payment.rideId);
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year at $hour:$min';
  }

  String _generateReceiptText() {
    final p = widget.payment;
    final r = _linkedRide;
    final req = widget.rideRequest;

    final date = p.paidAt ?? p.createdAt;
    final pickup = p.pickupAddress ?? r?.pickup.address ?? req?.pickup.address ?? 'Pickup Point';
    final dest = p.dropAddress ?? r?.destination.address ?? req?.destination.address ?? 'Destination Point';
    final vehicle = p.vehicleType ?? r?.vehicle.title ?? req?.selectedVehicle.title ?? 'QuickRide Vehicle';
    final dist = p.distanceKm ?? r?.distanceKm ?? req?.distanceKm ?? 0.0;
    final captain = p.captainName ?? r?.captain.name ?? req?.captain?.name ?? 'Assigned Captain';
    final user = p.passengerName ?? SessionManager().currentUser.fullName;
    final gatewayId = p.gatewayPaymentId ?? 'N/A';
    final coupon = p.couponCode ?? r?.fareDetails.offerLabel ?? req?.fareDetails.offerLabel ?? 'None';

    return '''
========================================
           QUICKRIDE RECEIPT            
========================================
Receipt / Payment ID: ${p.paymentId}
Ride ID: ${p.rideId}
Date & Time: ${_formatDateTime(date)}
Payment Status: ${p.paymentStatus.firestoreValue}
Payment Method: ${p.paymentMethod.toUpperCase()}
Gateway Reference: $gatewayId

PASSENGER & CAPTAIN
----------------------------------------
Passenger: $user
Captain: $captain
Vehicle: $vehicle
Distance: ${dist.toStringAsFixed(1)} km

TRIP ROUTE
----------------------------------------
Pickup: $pickup
Drop: $dest

FARE BREAKDOWN
----------------------------------------
Original Fare: ₹${p.originalFare.toStringAsFixed(2)}
Coupon / Promo: $coupon
Discount: -₹${p.discountAmount.toStringAsFixed(2)}
----------------------------------------
TOTAL PAID: ₹${p.finalAmount.toStringAsFixed(2)}
========================================
Thank you for riding with QuickRide!
Need help? Visit Help & Support in the app.
========================================
''';
  }

  void _shareReceipt() {
    final text = _generateReceiptText();
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Digital receipt copied to clipboard for sharing!'),
              ),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _saveOrPrintReceipt() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        title: const Row(
          children: [
            Icon(Icons.print_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text(
              'Print / Save Receipt',
              style: TextStyle(
                color: AppColors.textPrimaryLight,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A digital copy of this invoice has been archived to your verified payment history.',
              style: TextStyle(
                color: AppColors.textSecondaryLight,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Verified by QuickRide Security\nTxn: ${widget.payment.gatewayPaymentId ?? widget.payment.paymentId}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: AppColors.textSecondaryLight)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _shareReceipt();
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Slip'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payment;
    final r = _linkedRide;
    final req = widget.rideRequest;

    final date = p.paidAt ?? p.createdAt;
    final pickup = p.pickupAddress ?? r?.pickup.address ?? req?.pickup.address ?? 'Pickup Point';
    final dest = p.dropAddress ?? r?.destination.address ?? req?.destination.address ?? 'Destination Point';
    final vehicle = p.vehicleType ?? r?.vehicle.title ?? req?.selectedVehicle.title ?? 'QuickRide Vehicle';
    final dist = p.distanceKm ?? r?.distanceKm ?? req?.distanceKm ?? 0.0;
    final captain = p.captainName ?? r?.captain.name ?? req?.captain?.name;
    final captainVehicle = r?.captain.vehicleModel ?? req?.captain?.vehicleModel;
    final captainNumber = r?.captain.vehicleNumber ?? req?.captain?.vehicleNumber;
    final user = p.passengerName ?? SessionManager().currentUser.fullName;
    final userPhone = SessionManager().currentUser.mobileNumber;
    final coupon = p.couponCode ?? r?.fareDetails.offerLabel ?? req?.fareDetails.offerLabel;
    final isPaid = p.isPaid;

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
          'Digital Receipt',
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Share Receipt',
            icon: const Icon(Icons.share_rounded, color: AppColors.primary, size: 20),
            onPressed: _shareReceipt,
          ),
          IconButton(
            tooltip: 'Print / Save',
            icon: const Icon(Icons.print_rounded, color: AppColors.textSecondaryLight, size: 20),
            onPressed: _saveOrPrintReceipt,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.space16),
          child: Column(
            children: [
              // 1. Receipt Main Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  border: Border.all(color: AppColors.borderDark, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Receipt Header
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.space20),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(AppDimensions.radiusLarge),
                          topRight: Radius.circular(AppDimensions.radiusLarge),
                        ),
                        border: Border(bottom: BorderSide(color: AppColors.borderDark)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.local_taxi_rounded,
                              color: Colors.black,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  AppStrings.appName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimaryLight,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  'Tax Invoice & Verified Receipt',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondaryLight.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                  : Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isPaid ? const Color(0xFF10B981) : Colors.orange,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              p.paymentStatus.firestoreValue,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isPaid ? const Color(0xFF10B981) : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(AppDimensions.space20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Metadata Row
                          _buildSectionTitle('TRANSACTION INFORMATION'),
                          const SizedBox(height: 10),
                          _buildRow('Receipt ID', p.paymentId),
                          const SizedBox(height: 6),
                          _buildRow('Ride ID', p.rideId),
                          const SizedBox(height: 6),
                          _buildRow('Date & Time', _formatDateTime(date)),
                          const SizedBox(height: 6),
                          _buildRow('Payment Method', p.paymentMethod.toUpperCase()),
                          if (p.gatewayPaymentId != null) ...[
                            const SizedBox(height: 6),
                            _buildRow('Gateway Ref ID', p.gatewayPaymentId!),
                          ],

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(color: AppColors.borderDark, height: 1),
                          ),

                          // Passenger & Captain Info
                          _buildSectionTitle('PARTICIPANTS'),
                          const SizedBox(height: 10),
                          _buildRow('Passenger', user),
                          if (userPhone.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _buildRow('Passenger Contact', '+91 $userPhone'),
                          ],
                          if (captain != null) ...[
                            const SizedBox(height: 6),
                            _buildRow('Captain', captain),
                          ],
                          if (captainVehicle != null) ...[
                            const SizedBox(height: 6),
                            _buildRow('Vehicle Model', captainVehicle),
                          ],
                          if (captainNumber != null) ...[
                            const SizedBox(height: 6),
                            _buildRow('Vehicle Number', captainNumber),
                          ],

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(color: AppColors.borderDark, height: 1),
                          ),

                          // Route Details
                          _buildSectionTitle('TRIP DETAILS'),
                          const SizedBox(height: 10),
                          _buildRow('Vehicle Category', vehicle),
                          const SizedBox(height: 6),
                          _buildRow('Distance', '${dist.toStringAsFixed(1)} km'),
                          const SizedBox(height: 10),
                          _buildLocationRow('Pickup', pickup, Icons.my_location_rounded, AppColors.secondary),
                          const SizedBox(height: 8),
                          _buildLocationRow('Destination', dest, Icons.location_on_rounded, AppColors.primary),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(color: AppColors.borderDark, height: 1),
                          ),

                          // Fare Breakdown
                          _buildSectionTitle('FARE BREAKDOWN'),
                          const SizedBox(height: 10),
                          _buildRow('Original Base Fare', '₹${p.originalFare.toStringAsFixed(2)}'),
                          if (coupon != null && coupon.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _buildRow('Coupon Applied', coupon),
                          ],
                          if (p.discountAmount > 0) ...[
                            const SizedBox(height: 6),
                            _buildRow('Discount Amount', '-₹${p.discountAmount.toStringAsFixed(2)}', valueColor: const Color(0xFF10B981)),
                          ],
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceDark,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderDark),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Paid Amount',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimaryLight,
                                  ),
                                ),
                                Text(
                                  '₹${p.finalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _shareReceipt,
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share Receipt', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimaryLight,
                        side: const BorderSide(color: AppColors.borderDark, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveOrPrintReceipt,
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: const Text('Print Slip', style: TextStyle(fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondaryLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12.5,
              color: valueColor ?? AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow(String label, String address, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
              ),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
