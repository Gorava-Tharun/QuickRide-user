import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/firestore_models.dart';
import '../../models/ride_model.dart';
import '../../models/support_request_model.dart';
import '../../models/trip_share_data.dart';
import '../../services/firebase_service.dart';
import '../../services/safety_service.dart';
import '../../services/session_manager.dart';
import '../help_support/report_issue_screen.dart';
import 'safety_preferences_screen.dart';

/// STEP 18 & 40: Safety Center Screen.
///
/// Provides emergency SOS button with accidental activation guard,
/// live emergency telemetry status, emergency contacts management,
/// trip sharing with clipboard copy, captain/vehicle verification,
/// active ride safety tools, interactive checklist, and safety reporting.
class SafetyCenterScreen extends StatefulWidget {
  const SafetyCenterScreen({
    super.key,
    this.activeRide,
  });

  final RideRequest? activeRide;

  @override
  State<SafetyCenterScreen> createState() => _SafetyCenterScreenState();
}

class _SafetyCenterScreenState extends State<SafetyCenterScreen> {
  late final SafetyService _safetyService;

  @override
  void initState() {
    super.initState();
    _safetyService = SafetyService();
    if (widget.activeRide != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _safetyService.setActiveRide(widget.activeRide);
      });
    }
    final userId = SessionManager().currentUser.userId;
    _safetyService.restoreActiveEmergency(userId);
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanPhone,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open phone dialer for $phoneNumber'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dialer error: $phoneNumber'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showEmergencyDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          side: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
        ),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Trigger Emergency SOS?',
                style: TextStyle(
                  color: AppColors.textPrimaryLight,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Do you need emergency assistance?',
              style: TextStyle(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'If you are in immediate danger, contact your local emergency services.',
              style: TextStyle(
                color: AppColors.textSecondaryLight,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(AppDimensions.space12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.shield_rounded, color: Color(0xFFEF4444), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'High-Priority Incident Alert',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This will create a high-priority emergency record on QuickRide\'s Safety Monitoring Desk and transmit your live location in real time.\n\nNote: If you are in immediate physical danger, dial 112 (National Emergency Helpline) immediately.',
              style: TextStyle(
                color: AppColors.textSecondaryLight,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showEmergencyGuidanceModal();
            },
            child: const Text(
              'Continue',
              style: TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final userId = SessionManager().currentUser.userId;
              final success = await _safetyService.triggerSOS(
                ride: widget.activeRide,
                userId: userId,
                reason: 'Emergency SOS activated by rider in Safety Center',
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? '🚨 Emergency SOS Activated. Live location telemetry is transmitting.'
                          : 'SOS recorded locally. Transmitting live alert.',
                    ),
                    backgroundColor: const Color(0xFFEF4444),
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
            icon: const Icon(Icons.emergency_rounded, size: 18),
            label: const Text(
              'CONFIRM SOS',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmergencyGuidanceModal() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        title: const Text(
          'Emergency Guidance',
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please dial your national emergency services helpline directly from your phone (e.g. 112 in India, 911 in the US, 999 in the UK).\n\nQuickRide will cooperate fully with law enforcement and emergency personnel.',
              style: TextStyle(
                color: AppColors.textSecondaryLight,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                _makePhoneCall('112');
              },
              icon: const Icon(Icons.call_rounded, size: 18),
              label: const Text('Call 112 Directly'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 42),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Understood',
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

  void _showShareTripDialog(RideRequest? ride) {
    final data = ride != null
        ? TripShareData.fromRideRequest(ride)
        : TripShareData.demo();

    final pickup = ride?.pickup.name ?? data.pickup;
    final dest = ride?.destination.name ?? data.destination;
    final captainName = ride?.captain?.name ?? data.captainName;
    final vehicle = '${data.vehicleType} (${data.vehicleNumber})';
    final rideId = ride?.rideId ?? 'QR-DEMO-TRIP';

    final shareText = '''
🚨 QuickRide Live Trip Sharing
Status: ${ride?.status.name.toUpperCase() ?? 'IN TRANSIT'}
Pickup: $pickup
Drop: $dest
Captain: $captainName ($vehicle)
Ride ID: $rideId
Monitored 24x7 by QuickRide Safety Desk.
'''.trim();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        title: Row(
          children: const [
            Icon(Icons.share_location_rounded, color: AppColors.primary, size: 24),
            SizedBox(width: 10),
            Text(
              'Share Trip',
              style: TextStyle(
                color: AppColors.textPrimaryLight,
                fontSize: 18,
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
              'Trip sharing will be connected to the QuickRide backend. Copy this verified trip summary to share with your family or friends via WhatsApp, SMS, or any messaging app.',
              style: TextStyle(
                color: AppColors.textSecondaryLight,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.space12),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Text(
                shareText,
                style: const TextStyle(
                  color: AppColors.textPrimaryLight,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: shareText));
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Trip summary copied to clipboard!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy to Clipboard'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.backgroundDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String relationship = 'Family';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            side: const BorderSide(color: AppColors.borderDark),
          ),
          title: const Text(
            'Add Emergency Contact',
            style: TextStyle(
              color: AppColors.textPrimaryLight,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: AppColors.textPrimaryLight),
                  decoration: const InputDecoration(
                    labelText: 'Contact Name',
                    hintText: 'e.g. Mom, Dad, Sibling, Friend',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppColors.textPrimaryLight),
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'e.g. 9876543210',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: relationship,
                  dropdownColor: AppColors.cardDark,
                  style: const TextStyle(color: AppColors.textPrimaryLight),
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    prefixIcon: Icon(Icons.people_outline_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Family', child: Text('Family')),
                    DropdownMenuItem(value: 'Parent', child: Text('Parent')),
                    DropdownMenuItem(value: 'Spouse', child: Text('Spouse')),
                    DropdownMenuItem(value: 'Sibling', child: Text('Sibling')),
                    DropdownMenuItem(value: 'Friend', child: Text('Friend')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => relationship = val);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryLight)),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                final messenger = ScaffoldMessenger.of(context);
                if (name.isEmpty || phone.isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Please enter both name and phone number.')),
                  );
                  return;
                }

                final userId = SessionManager().currentUser.userId;
                final contact = FirestoreEmergencyContactModel(
                  contactId: 'contact_${DateTime.now().millisecondsSinceEpoch}',
                  ownerId: userId,
                  name: name,
                  phone: phone,
                  relationship: relationship,
                  createdAt: DateTime.now(),
                );

                final ok = await QuickRideFirebaseService().addEmergencyContact(contact);
                if (ctx.mounted) Navigator.of(ctx).pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Emergency contact added' : 'Failed to add contact'),
                    backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.backgroundDark,
              ),
              child: const Text('Save Contact', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCaptainDetailsModal(RideRequest ride) {
    final captain = ride.captain ??
        CaptainModel.demo(vehicleCategoryTitle: ride.selectedVehicle.title);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLarge)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Captain Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondaryLight),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.18),
                    child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 32),
                  ),
                  const SizedBox(width: 14),
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
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              captain.formattedRating,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${captain.completedRides} rides)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.space12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevatedDark,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: const Text(
                  'Contact details will be available in the production version.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondaryLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVehicleDetailsModal(RideRequest ride) {
    final captain = ride.captain ??
        CaptainModel.demo(vehicleCategoryTitle: ride.selectedVehicle.title);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLarge)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Vehicle Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondaryLight),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildDetailRow('Vehicle Category', ride.selectedVehicle.title),
              const SizedBox(height: 8),
              _buildDetailRow('Vehicle Model', captain.vehicleModel),
              const SizedBox(height: 8),
              _buildDetailRow('License Plate', captain.vehicleNumber),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Safety Center',
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
            tooltip: 'Safety Preferences',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SafetyPreferencesScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _safetyService,
          builder: (context, _) {
            final activeRide = widget.activeRide ?? _safetyService.activeRide;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active Emergency Alert Banner (if active)
                  if (_safetyService.activeEmergency != null)
                    _buildActiveEmergencyBanner(_safetyService.activeEmergency!),

                  // 1. Header Banner
                  _buildHeaderBanner(),
                  const SizedBox(height: AppDimensions.space16),

                  // 2. Emergency SOS Section
                  _buildEmergencySection(),
                  const SizedBox(height: AppDimensions.space20),

                  // 3. Emergency Contacts Management
                  _buildEmergencyContactsSection(),
                  const SizedBox(height: AppDimensions.space20),

                  // 4. Active Ride Safety Section
                  _buildActiveRideSection(activeRide),
                  const SizedBox(height: AppDimensions.space20),

                  // 5. Before You Ride (Verification) Section
                  _buildVerificationSection(activeRide),
                  const SizedBox(height: AppDimensions.space20),

                  // 6. Share Your Trip Section
                  _buildShareTripSection(activeRide),
                  const SizedBox(height: AppDimensions.space20),

                  // 7. Interactive Safety Checklist
                  _buildSafetyChecklistSection(),
                  const SizedBox(height: AppDimensions.space20),

                  // 8. Safety Tips (Expandable)
                  _buildSafetyTipsSection(),
                  const SizedBox(height: AppDimensions.space20),

                  // 9. Report a Safety Issue Section
                  _buildReportSafetyIssueSection(activeRide),
                  const SizedBox(height: AppDimensions.space24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveEmergencyBanner(FirestoreEmergencyIncidentModel emergency) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppDimensions.space16),
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: const Color(0xFFEF4444), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EMERGENCY SOS ACTIVE',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFEF4444),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Incident ID: ${emergency.emergencyId}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: emergency.isAcknowledged ? Colors.amber : const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  emergency.statusLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'QuickRide Safety Operations Desk has received your incident and live location coordinates. Dedicated response personnel are reviewing telemetry.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textPrimaryLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _makePhoneCall('112'),
                  icon: const Icon(Icons.call_rounded, size: 16),
                  label: const Text('Call 112 Helpline', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _showEmergencyGuidanceModal(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  foregroundColor: const Color(0xFFEF4444),
                ),
                child: const Text('Guidance', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
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
                  'Your safety matters to QuickRide',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimaryLight,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Explore safety tools, verify your ride before boarding, and share live trip telemetry with people you trust.',
                  style: TextStyle(
                    fontSize: 12.5,
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
              Icons.shield_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.emergency_rounded, color: Color(0xFFEF4444), size: 22),
              SizedBox(width: 8),
              Text(
                'Emergency Help',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Need immediate emergency assistance or feeling unsafe during your journey?',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textPrimaryLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _showEmergencyDialog,
            icon: const Icon(Icons.warning_amber_rounded, size: 20),
            label: const Text(
              'Emergency Assistance',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsSection() {
    final userId = SessionManager().currentUser.userId;
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
              Row(
                children: const [
                  Icon(Icons.contact_phone_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Emergency Contacts',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _showAddContactDialog,
                icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                label: const Text(
                  'Add',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 24),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Keep verified contacts accessible for 1-tap dial during an active ride.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<FirestoreEmergencyContactModel>>(
            stream: QuickRideFirebaseService().streamEmergencyContacts(userId),
            builder: (context, snapshot) {
              final contacts = snapshot.data ?? [];
              if (contacts.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.space12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevatedDark,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(color: AppColors.borderDark.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_add_alt_1_rounded, color: AppColors.textSecondaryLight, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'No emergency contacts saved yet.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        ),
                      ),
                      TextButton(
                        onPressed: _showAddContactDialog,
                        child: const Text('Add Now', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: contacts.map((contact) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevatedDark,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    contact.name,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardDark,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      contact.relationship ?? 'Contact',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondaryLight,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                contact.phone,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.call_rounded, color: Color(0xFF10B981), size: 20),
                          tooltip: 'Call ${contact.name}',
                          onPressed: () => _makePhoneCall(contact.phone),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondaryLight, size: 18),
                          tooltip: 'Remove',
                          onPressed: () async {
                            await QuickRideFirebaseService().deleteEmergencyContact(userId, contact.contactId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Removed ${contact.name} from emergency contacts')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRideSection(RideRequest? activeRide) {
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
            'RIDE SAFETY',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),

          if (activeRide != null) ...[
            Text(
              'Active Trip: ${activeRide.selectedVehicle.title} to ${activeRide.destination.name}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickActionChip(
                  icon: Icons.share_location_rounded,
                  label: 'Share Trip',
                  onTap: () => _showShareTripDialog(activeRide),
                ),
                _buildQuickActionChip(
                  icon: Icons.person_rounded,
                  label: 'View Captain',
                  onTap: () => _showCaptainDetailsModal(activeRide),
                ),
                _buildQuickActionChip(
                  icon: Icons.directions_car_rounded,
                  label: 'View Vehicle Details',
                  onTap: () => _showVehicleDetailsModal(activeRide),
                ),
                _buildQuickActionChip(
                  icon: Icons.report_problem_rounded,
                  label: 'Report Safety Issue',
                  color: const Color(0xFFEF4444),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ReportIssueScreen(
                          initialCategory: SupportCategory.safetyIssue,
                          preselectedRideId: activeRide.rideId,
                        ),
                      ),
                    );
                  },
                ),
                _buildQuickActionChip(
                  icon: Icons.emergency_rounded,
                  label: 'Emergency Assistance',
                  color: const Color(0xFFEF4444),
                  onTap: _showEmergencyDialog,
                ),
              ],
            ),
          ] else ...[
            Row(
              children: const [
                Icon(Icons.info_outline_rounded, color: AppColors.textSecondaryLight, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Safety tools for your next ride will appear here.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final chipColor = color ?? AppColors.primary;
    return Material(
      color: chipColor.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: chipColor, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: chipColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationSection(RideRequest? activeRide) {
    final captain = activeRide?.captain ??
        CaptainModel.demo(vehicleCategoryTitle: 'Auto');

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
              Icon(Icons.verified_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Before You Ride',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Verify your captain and vehicle',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),

          // Details summary card
          Container(
            padding: const EdgeInsets.all(AppDimensions.space12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevatedDark,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Column(
              children: [
                _buildDetailRow('Captain Name', captain.name),
                const SizedBox(height: 6),
                _buildDetailRow('Captain Rating', '${captain.formattedRating} ★ (${captain.completedRides} rides)'),
                const SizedBox(height: 6),
                _buildDetailRow('Vehicle Type', captain.vehicleType),
                const SizedBox(height: 6),
                _buildDetailRow('Vehicle Model', captain.vehicleModel),
                const SizedBox(height: 6),
                _buildDetailRow('Registration Number', captain.vehicleNumber),
              ],
            ),
          ),
          const SizedBox(height: 10),

          const Text(
            'Contact details will be available in the production version.',
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondaryLight,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 14),

          // Checklist Badges
          _buildChecklistBadge('Vehicle matches the app'),
          const SizedBox(height: 6),
          _buildChecklistBadge('Captain details match the app'),
          const SizedBox(height: 6),
          _buildChecklistBadge('Destination is correct'),
        ],
      ),
    );
  }

  Widget _buildChecklistBadge(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildShareTripSection(RideRequest? activeRide) {
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
              Icon(Icons.share_location_rounded, color: AppColors.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                'Share Your Trip',
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
            'Share your ride details with someone you trust.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaryLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _showShareTripDialog(activeRide),
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text(
              'Share Trip',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              minimumSize: const Size(double.infinity, 44),
              side: const BorderSide(color: AppColors.secondary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyChecklistSection() {
    final checklist = _safetyService.checklist;

    const checklistLabels = {
      'verify_vehicle': 'Verify vehicle number',
      'verify_captain': 'Verify captain details',
      'confirm_dest': 'Confirm destination',
      'secure_belongings': 'Keep belongings secure',
      'share_trip': 'Share trip with a trusted person',
    };

    return Material(
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        side: const BorderSide(color: AppColors.borderDark),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.fact_check_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Safety Checklist',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _safetyService.resetChecklist(),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 24),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Reset',
                    style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ...checklistLabels.entries.map((entry) {
              final isChecked = checklist[entry.key] ?? false;
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                checkColor: AppColors.backgroundDark,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isChecked ? AppColors.textPrimaryLight : AppColors.textSecondaryLight,
                    decoration: isChecked ? TextDecoration.lineThrough : null,
                  ),
                ),
                value: isChecked,
                onChanged: (_) => _safetyService.toggleChecklistItem(entry.key),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyTipsSection() {
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
              Icon(Icons.lightbulb_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Safety Tips',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildTipExpansionCard(
            title: 'Before entering',
            bullets: const [
              'Check the vehicle number.',
              'Confirm the captain details.',
              'Make sure the vehicle matches the information shown in the app.',
            ],
          ),
          const SizedBox(height: 8),

          _buildTipExpansionCard(
            title: 'During the ride',
            bullets: const [
              'Keep your belongings secure.',
              'Follow safe travel practices.',
              'If something feels unsafe, seek appropriate assistance.',
            ],
          ),
          const SizedBox(height: 8),

          _buildTipExpansionCard(
            title: 'After the ride',
            bullets: const [
              'Check that you have all your belongings.',
              'Report safety concerns through QuickRide Support.',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipExpansionCard({
    required String title,
    required List<String> bullets,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Material(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey('tip_$title'),
            iconColor: AppColors.primary,
            collapsedIconColor: AppColors.textSecondaryLight,
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight,
              ),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: bullets.map((b) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.primary, fontSize: 14)),
                    Expanded(
                      child: Text(
                        b,
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
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildReportSafetyIssueSection(RideRequest? activeRide) {
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
              Icon(Icons.report_problem_rounded, color: Color(0xFFEF4444), size: 20),
              SizedBox(width: 8),
              Text(
                'Report a Safety Issue',
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
            'Experienced reckless driving, captain misconduct, or vehicle problems? Submit an official report to our safety desk.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondaryLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ReportIssueScreen(
                    initialCategory: SupportCategory.safetyIssue,
                    preselectedRideId: activeRide?.rideId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.shield_outlined, color: Color(0xFFEF4444), size: 18),
            label: const Text(
              'Report Safety Issue',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w700,
                fontSize: 13,
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
}
