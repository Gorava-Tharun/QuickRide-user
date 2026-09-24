import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimensions.dart';
import '../models/firestore_models.dart';

/// Common cancellation reasons for users
const List<String> kUserCancellationReasons = [
  'Changed my plans',
  'Captain is taking too long',
  'Wrong pickup location',
  'Found another ride',
  'Other',
];

/// Result returned when user successfully confirms cancellation
class UserCancellationResult {
  final String reason;
  final String? description;
  final double cancellationFee;
  final double refundAmount;
  final bool isRefunded;

  const UserCancellationResult({
    required this.reason,
    this.description,
    required this.cancellationFee,
    required this.refundAmount,
    required this.isRefunded,
  });
}

/// Interactive dialog for selecting cancellation reason and reviewing fee/refund
class UserCancellationDialog extends StatefulWidget {
  final String rideId;
  final SharedRideStatus currentStatus;
  final double fare;
  final bool isOnlinePaid;
  final DateTime? acceptedAt;

  const UserCancellationDialog({
    super.key,
    required this.rideId,
    required this.currentStatus,
    required this.fare,
    this.isOnlinePaid = false,
    this.acceptedAt,
  });

  /// Helper to display this dialog
  static Future<UserCancellationResult?> show(
    BuildContext context, {
    required String rideId,
    required SharedRideStatus currentStatus,
    required double fare,
    bool isOnlinePaid = false,
    DateTime? acceptedAt,
  }) {
    return showDialog<UserCancellationResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UserCancellationDialog(
        rideId: rideId,
        currentStatus: currentStatus,
        fare: fare,
        isOnlinePaid: isOnlinePaid,
        acceptedAt: acceptedAt,
      ),
    );
  }

  /// Displays post-cancellation summary bottom sheet
  static Future<void> showSummarySheet(
    BuildContext context, {
    required String rideId,
    required String reason,
    String? description,
    required double cancellationFee,
    required double refundAmount,
    required bool isOnlinePaid,
    VoidCallback? onDone,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLarge)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.borderDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ride Cancelled',
                          style: TextStyle(
                            color: AppColors.textPrimaryLight,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Your booking has been cancelled successfully',
                          style: TextStyle(
                            color: AppColors.textSecondaryLight,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Ride ID', '#${rideId.length > 8 ? rideId.substring(0, 8) : rideId}'),
                    const Divider(color: AppColors.borderDark, height: 16),
                    _buildSummaryRow('Cancelled By', 'You (Passenger)'),
                    const Divider(color: AppColors.borderDark, height: 16),
                    _buildSummaryRow('Reason', reason),
                    if (description != null && description.isNotEmpty) ...[
                      const Divider(color: AppColors.borderDark, height: 16),
                      _buildSummaryRow('Notes', description),
                    ],
                    const Divider(color: AppColors.borderDark, height: 16),
                    _buildSummaryRow(
                      'Cancellation Fee',
                      cancellationFee == 0 ? 'FREE (₹0)' : '₹${cancellationFee.toStringAsFixed(0)}',
                      valueColor: cancellationFee == 0 ? AppColors.success : AppColors.error,
                    ),
                    if (isOnlinePaid) ...[
                      const Divider(color: AppColors.borderDark, height: 16),
                      _buildSummaryRow(
                        'Refund Amount',
                        '₹${refundAmount.toStringAsFixed(0)}',
                        valueColor: AppColors.primary,
                        subtitle: 'Will be credited back to your payment method',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    if (onDone != null) onDone();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildSummaryRow(String label, String value, {Color? valueColor, String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondaryLight,
                fontSize: 13,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.textPrimaryLight,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondaryLight,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  @override
  State<UserCancellationDialog> createState() => _UserCancellationDialogState();
}

class _UserCancellationDialogState extends State<UserCancellationDialog> {
  String _selectedReason = kUserCancellationReasons.first;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _cancellationFee {
    switch (widget.currentStatus) {
      case SharedRideStatus.requested:
        return 0.0;
      case SharedRideStatus.accepted:
        if (widget.acceptedAt != null) {
          final diff = DateTime.now().difference(widget.acceptedAt!);
          if (diff.inSeconds <= 120) {
            return 0.0; // 2-minute grace period
          }
        }
        return 25.0;
      case SharedRideStatus.arrived:
      case SharedRideStatus.inProgress:
        return 50.0;
      case SharedRideStatus.completed:
      case SharedRideStatus.cancelled:
        return 0.0;
    }
  }

  double get _refundAmount {
    if (!widget.isOnlinePaid) return 0.0;
    final refund = widget.fare - _cancellationFee;
    return refund > 0 ? refund : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final fee = _cancellationFee;
    final refund = _refundAmount;

    return AlertDialog(
      backgroundColor: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        side: const BorderSide(color: AppColors.borderDark),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
          ),
          const SizedBox(width: 12),
          const Text(
            'Cancel Ride',
            style: TextStyle(
              color: AppColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fee & Refund preview badge
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: fee == 0 ? AppColors.success.withValues(alpha: 0.12) : AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(
                  color: fee == 0 ? AppColors.success.withValues(alpha: 0.3) : AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        fee == 0 ? 'Free Cancellation' : 'Cancellation Fee',
                        style: TextStyle(
                          color: fee == 0 ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        fee == 0 ? '₹0' : '₹${fee.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: fee == 0 ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  if (widget.isOnlinePaid) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Estimated Refund:',
                          style: TextStyle(
                            color: AppColors.textPrimaryLight,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '₹${refund.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please select reason for cancellation:',
              style: TextStyle(
                color: AppColors.textPrimaryLight,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...kUserCancellationReasons.map((reason) {
              final isSelected = _selectedReason == reason;
              return InkWell(
                onTap: () => setState(() => _selectedReason = reason),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          reason,
                          style: TextStyle(
                            color: isSelected ? AppColors.textPrimaryLight : AppColors.textSecondaryLight,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 13),
              decoration: InputDecoration(
                hintText: _selectedReason == 'Other' ? 'Describe reason (required)...' : 'Additional notes (optional)...',
                hintStyle: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
                filled: true,
                fillColor: AppColors.surfaceDark,
                contentPadding: const EdgeInsets.all(10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  borderSide: const BorderSide(color: AppColors.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text(
            'Keep Ride',
            style: TextStyle(
              color: AppColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedReason == 'Other' && _notesController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a description for "Other"')),
              );
              return;
            }
            Navigator.of(context).pop(
              UserCancellationResult(
                reason: _selectedReason,
                description: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                cancellationFee: fee,
                refundAmount: refund,
                isRefunded: widget.isOnlinePaid && refund > 0,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
          ),
          child: const Text(
            'Cancel Ride',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
