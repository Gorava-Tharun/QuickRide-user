import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/firestore_models.dart';
import '../../models/ride_history_model.dart';
import '../../models/support_request_model.dart';
import '../../services/firebase_service.dart';
import '../../services/ride_history_service.dart';
import '../../services/session_manager.dart';
import '../../services/support_service.dart';
import '../../services/user_storage_service.dart';
import '../../widgets/primary_button.dart';
import 'support_success_screen.dart';

/// Screen allowing the user to report a ride, captain, payment, safety, lost item, or general problem.
class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({
    super.key,
    this.initialCategory = SupportCategory.rideIssue,
    this.preselectedRideId,
    this.preselectedPaymentId,
  });

  final SupportCategory initialCategory;
  final String? preselectedRideId;
  final String? preselectedPaymentId;

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  late SupportCategory _selectedCategory;
  SupportPriority _selectedPriority = SupportPriority.normal;
  String? _selectedRideId;
  String? _selectedPaymentId;
  String? _selectedIssueType;
  bool _isSubmitting = false;

  XFile? _attachedImage;
  double _uploadProgress = 0.0;
  bool _isUploadingAttachment = false;

  late final List<RideHistoryItem> _availableRides;
  List<FirestorePaymentModel> _availablePayments = [];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _selectedRideId = widget.preselectedRideId;
    _selectedPaymentId = widget.preselectedPaymentId;
    _availableRides = RideHistoryService().getHistory();

    if (_selectedCategory == SupportCategory.safetyIssue) {
      _selectedPriority = SupportPriority.high;
    }

    // Set default issue type for selected category
    final options = _getIssueOptionsForCategory(_selectedCategory);
    if (options.isNotEmpty) {
      _selectedIssueType = options.first;
    }

    _loadUserPayments();
  }

  Future<void> _loadUserPayments() async {
    final userId = SessionManager().currentUser.userId.isNotEmpty
        ? SessionManager().currentUser.userId
        : 'user_quickride_01';
    final payments = await QuickRideFirebaseService().fetchUserPayments(userId);
    if (mounted) {
      setState(() => _availablePayments = payments);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  List<String> _getIssueOptionsForCategory(SupportCategory category) {
    switch (category) {
      case SupportCategory.rideIssue:
        return const [
          "Captain didn't arrive",
          'Wrong fare charged',
          'Pickup problem',
          'Destination problem',
          'Ride cancellation issue',
          'Vehicle condition issue',
          'Other ride issue',
        ];
      case SupportCategory.captainIssue:
        return const [
          'Captain behavior / rudeness',
          'Unsafe or rash driving',
          'Wrong vehicle / captain mismatch',
          'Captain refused to start trip',
          'Other captain issue',
        ];
      case SupportCategory.paymentIssue:
        return const [
          'Incorrect fare or overcharge',
          'Payment deducted but failed',
          'Double charge on UPI / Card',
          'Cash paid but shown unpaid',
          'Refund not received',
          'Other payment issue',
        ];
      case SupportCategory.safetyIssue:
        return const [
          'Dangerous or intoxicated driving',
          'Harassment or inappropriate behavior',
          'Vehicle mismatch / fake captain',
          'Unauthorized route deviation',
          'Emergency assistance needed',
          'Other safety concern',
        ];
      case SupportCategory.pickupDestinationIssue:
        return const [
          'Pickup location inaccurate',
          'Destination drop point incorrect',
          'Route confusion by navigation',
          'Other navigation issue',
        ];
      case SupportCategory.offerCouponIssue:
        return const [
          'Coupon not applied to fare',
          'Discount amount incorrect',
          'Promo code failed at checkout',
          'Other offer issue',
        ];
      case SupportCategory.lostItem:
        return const [
          'Left wallet / purse in vehicle',
          'Left mobile phone in vehicle',
          'Left bag / luggage in vehicle',
          'Left keys / ID cards in vehicle',
          'Other lost item',
        ];
      case SupportCategory.accountIssue:
        return const [
          'Profile update failed',
          'Phone / email verification problem',
          'Security or unauthorized access',
          'Other account issue',
        ];
      case SupportCategory.other:
        return const [
          'App crash or bug',
          'Feature suggestion',
          'General query',
          'Other',
        ];
    }
  }

  void _onCategoryChanged(SupportCategory? newCat) {
    if (newCat == null || newCat == _selectedCategory) return;
    setState(() {
      _selectedCategory = newCat;
      // Auto-escalate safety issues
      if (newCat == SupportCategory.safetyIssue) {
        _selectedPriority = SupportPriority.high;
      } else if (_selectedPriority == SupportPriority.high &&
          widget.initialCategory != SupportCategory.safetyIssue) {
        _selectedPriority = SupportPriority.normal;
      }

      final options = _getIssueOptionsForCategory(newCat);
      _selectedIssueType = options.isNotEmpty ? options.first : null;
    });
  }

  Future<void> _pickAttachment(ImageSource source) async {
    final image = await UserStorageService().pickProfileImage(source: source);
    if (image != null && mounted) {
      setState(() {
        _attachedImage = image;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedIssueType == null || _selectedIssueType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an issue type.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = SessionManager().currentUser.userId.isNotEmpty
          ? SessionManager().currentUser.userId
          : 'user_quickride_01';
      final tempComplaintId = SupportService().generateNextRequestId();

      String? uploadedAttachmentUrl;
      if (_attachedImage != null) {
        setState(() => _isUploadingAttachment = true);
        final uploadResult = await UserStorageService().uploadComplaintAttachment(
          userId: userId,
          complaintId: tempComplaintId,
          file: _attachedImage!,
          onProgress: (p) {
            if (mounted) setState(() => _uploadProgress = p);
          },
        );
        if (uploadResult.success) {
          uploadedAttachmentUrl = uploadResult.downloadUrl;
        }
      }

      final request = SupportRequest(
        requestId: tempComplaintId,
        userId: userId,
        rideId: _selectedRideId,
        paymentId: _selectedPaymentId,
        attachmentUrl: uploadedAttachmentUrl,
        category: _selectedCategory,
        issueType: _selectedIssueType!,
        subject: _selectedIssueType!,
        description: _descriptionController.text.trim(),
        createdAt: DateTime.now(),
        status: SupportStatus.open,
        priority: _selectedPriority,
      );

      final savedRequest = await SupportService().createSupportRequest(request);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => SupportSuccessScreen(request: savedRequest),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isUploadingAttachment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final issueOptions = _getIssueOptionsForCategory(_selectedCategory);

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
        title: Text(
          'Report ${_selectedCategory.title}',
          style: const TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.space16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Safety Alert Banner
                if (_selectedCategory == SupportCategory.safetyIssue) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14.0),
                    margin: const EdgeInsets.only(bottom: AppDimensions.space16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(
                          Icons.shield_rounded,
                          color: Color(0xFFEF4444),
                          size: 22,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Safety First Priority',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Safety concerns are escalated immediately with HIGH priority to our 24/7 Trust & Safety Response Team. If in immediate danger, please dial 112 directly.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimaryLight,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Category Selector Card
                _buildCategorySelector(),
                const SizedBox(height: AppDimensions.space16),

                // Priority Indicator
                _buildPrioritySelector(),
                const SizedBox(height: AppDimensions.space16),

                // Subject / Issue Type
                _buildSubjectAndIssueTypeSelector(issueOptions),
                const SizedBox(height: AppDimensions.space16),

                // Select Ride (Optional)
                _buildRideSelector(),
                const SizedBox(height: AppDimensions.space16),

                // Select Payment (Optional)
                _buildPaymentSelector(),
                const SizedBox(height: AppDimensions.space16),

                // Payment Notice (for Payment Issue)
                if (_selectedCategory == SupportCategory.paymentIssue) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.space12),
                    margin: const EdgeInsets.only(bottom: AppDimensions.space16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Payment support will be connected to the QuickRide backend in a future version.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textPrimaryLight,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Description Field
                _buildDescriptionField(),
                const SizedBox(height: AppDimensions.space16),

                // Screenshot Attachment Picker
                _buildAttachmentPicker(),
                const SizedBox(height: AppDimensions.space24),

                // Submit Button
                PrimaryButton(
                  text: _isSubmitting
                      ? (_isUploadingAttachment ? 'Uploading Attachment...' : 'Submitting...')
                      : 'Submit Request',
                  onPressed: _isSubmitting ? () {} : _handleSubmit,
                  icon: Icons.send_rounded,
                ),
                const SizedBox(height: AppDimensions.space20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
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
          const Text(
            'CATEGORY',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<SupportCategory>(
            initialValue: _selectedCategory,
            dropdownColor: AppColors.cardDark,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceElevatedDark,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                borderSide: const BorderSide(color: AppColors.borderDark),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                borderSide: const BorderSide(color: AppColors.borderDark),
              ),
            ),
            items: SupportCategory.values.map((cat) {
              return DropdownMenuItem<SupportCategory>(
                value: cat,
                child: Row(
                  children: [
                    Icon(cat.icon, color: cat.accentColor, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      cat.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: _onCategoryChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySelector() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PRIORITY LEVEL',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _selectedPriority.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  border: Border.all(color: _selectedPriority.color.withValues(alpha: 0.5)),
                ),
                child: Text(
                  _selectedPriority.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _selectedPriority.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: SupportPriority.values.map((p) {
              final isSelected = _selectedPriority == p;
              final isSafetyForced = _selectedCategory == SupportCategory.safetyIssue &&
                  (p == SupportPriority.low || p == SupportPriority.normal);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: OutlinedButton(
                    onPressed: isSafetyForced
                        ? null
                        : () => setState(() => _selectedPriority = p),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      backgroundColor: isSelected
                          ? p.color.withValues(alpha: 0.2)
                          : AppColors.surfaceElevatedDark,
                      side: BorderSide(
                        color: isSelected ? p.color : AppColors.borderDark,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                    ),
                    child: Text(
                      p.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? p.color : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectAndIssueTypeSelector(List<String> options) {
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
          const Text(
            'ISSUE TYPE / SUBJECT',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey('issue_type_$_selectedCategory'),
            initialValue: _selectedIssueType,
            dropdownColor: AppColors.cardDark,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceElevatedDark,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                borderSide: const BorderSide(color: AppColors.borderDark),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                borderSide: const BorderSide(color: AppColors.borderDark),
              ),
            ),
            items: options.map((opt) {
              return DropdownMenuItem<String>(
                value: opt,
                child: Text(
                  opt,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedIssueType = val;
              });
            },
            validator: (val) =>
                val == null || val.isEmpty ? 'Please select an issue type' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildRideSelector() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'RELATED RIDE',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Optional',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            initialValue: _selectedRideId,
            dropdownColor: AppColors.cardDark,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceElevatedDark,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                borderSide: const BorderSide(color: AppColors.borderDark),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                borderSide: const BorderSide(color: AppColors.borderDark),
              ),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text(
                  'None (Not ride specific)',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
              ..._availableRides.map((r) {
                return DropdownMenuItem<String?>(
                  value: r.rideId,
                  child: Text(
                    '${r.rideId} • ${r.vehicle.title} (${r.destination.name})',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
            onChanged: (val) => setState(() => _selectedRideId = val),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSelector() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'RELATED PAYMENT',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Optional',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            initialValue: _selectedPaymentId,
            dropdownColor: AppColors.cardDark,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceElevatedDark,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                borderSide: const BorderSide(color: AppColors.borderDark),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                borderSide: const BorderSide(color: AppColors.borderDark),
              ),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text(
                  'None (Not payment specific)',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
              ..._availablePayments.map((p) {
                return DropdownMenuItem<String?>(
                  value: p.paymentId,
                  child: Text(
                    '${p.paymentId} • ₹${p.finalAmount.toStringAsFixed(0)} (${p.paymentMethod.toUpperCase()})',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
            onChanged: (val) => setState(() => _selectedPaymentId = val),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DETAILED DESCRIPTION',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.primary,
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _descriptionController,
                builder: (context, value, _) {
                  final length = value.text.length;
                  return Text(
                    '$length / 500',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: length >= 500 ? Colors.redAccent : AppColors.textSecondaryLight,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _descriptionController,
            maxLines: 5,
            maxLength: 500,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: 'Please provide detailed information regarding the problem...',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryLight,
              ),
              filled: true,
              fillColor: AppColors.surfaceElevatedDark,
              contentPadding: const EdgeInsets.all(14.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                borderSide: const BorderSide(color: AppColors.borderDark),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                borderSide: const BorderSide(color: AppColors.borderDark),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please describe your problem.';
              }
              if (value.trim().length < 5) {
                return 'Description must be at least 5 characters.';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentPicker() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'ATTACH SCREENSHOT / PHOTO',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Optional',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_attachedImage == null) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickAttachment(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded, size: 18, color: AppColors.primary),
                    label: const Text('From Gallery', style: TextStyle(fontSize: 12.5, color: AppColors.textPrimaryLight)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.borderDark),
                      backgroundColor: AppColors.surfaceElevatedDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickAttachment(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded, size: 18, color: AppColors.secondary),
                    label: const Text('Take Photo', style: TextStyle(fontSize: 12.5, color: AppColors.textPrimaryLight)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.borderDark),
                      backgroundColor: AppColors.surfaceElevatedDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevatedDark,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    ),
                    child: const Icon(Icons.image_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _attachedImage!.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Ready to attach with ticket',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                    tooltip: 'Remove photo',
                    onPressed: () => setState(() => _attachedImage = null),
                  ),
                ],
              ),
            ),
            if (_isUploadingAttachment) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _uploadProgress > 0 ? _uploadProgress : null,
                color: AppColors.primary,
                backgroundColor: AppColors.borderDark,
              ),
            ],
          ],
        ],
      ),
    );
  }
}
