import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/firestore_models.dart';
import '../../models/support_request_model.dart';
import '../../services/session_manager.dart';
import '../../services/support_service.dart';

/// Screen displaying the full details, live conversation thread, and reply composer for a support complaint.
class SupportRequestDetailsScreen extends StatefulWidget {
  const SupportRequestDetailsScreen({
    super.key,
    required this.request,
  });

  final SupportRequest request;

  @override
  State<SupportRequestDetailsScreen> createState() => _SupportRequestDetailsScreenState();
}

class _SupportRequestDetailsScreenState extends State<SupportRequestDetailsScreen> {
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSendingReply = false;

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendReply(SupportRequest currentRequest) async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSendingReply = true);
    final user = SessionManager().currentUser;
    final userId = user.userId.isNotEmpty ? user.userId : 'user_quickride_01';
    final userName = user.fullName.isNotEmpty ? user.fullName : 'Rider';

    final success = await SupportService().sendReply(
      complaintId: currentRequest.requestId,
      senderId: userId,
      senderName: userName,
      message: text,
    );

    if (mounted) {
      if (success) {
        _replyController.clear();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send reply. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      setState(() => _isSendingReply = false);
    }
  }

  void _showImageZoom(String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.surfaceDark,
                  padding: const EdgeInsets.all(32),
                  child: const Text('Unable to load image', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close_rounded, color: Colors.white),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRequest =
        SupportService().getSupportRequestById(widget.request.requestId) ?? widget.request;
    final isClosed = currentRequest.status == SupportStatus.closed;

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
          'Request #${currentRequest.requestId}',
          style: const TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space16,
                  vertical: AppDimensions.space12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Status & Header Card
                    _buildHeaderCard(currentRequest),
                    const SizedBox(height: 14),

                    // 2. Linked Ride & Payment Cards
                    if (currentRequest.rideId != null || currentRequest.paymentId != null) ...[
                      _buildLinkedCards(currentRequest),
                      const SizedBox(height: 14),
                    ],

                    // 3. Issue Subject & Description
                    _buildDescriptionCard(currentRequest),
                    const SizedBox(height: 14),

                    // 4. Attached Photo
                    if (currentRequest.attachmentUrl != null &&
                        currentRequest.attachmentUrl!.isNotEmpty) ...[
                      _buildAttachmentCard(currentRequest.attachmentUrl!),
                      const SizedBox(height: 14),
                    ],

                    // 5. Official Resolution Summary (if resolved)
                    if (currentRequest.status == SupportStatus.resolved &&
                        currentRequest.resolutionSummary != null &&
                        currentRequest.resolutionSummary!.isNotEmpty) ...[
                      _buildResolutionCard(currentRequest.resolutionSummary!),
                      const SizedBox(height: 14),
                    ],

                    // 6. Conversation Thread Section Header
                    Row(
                      children: const [
                        Icon(Icons.forum_rounded, color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'CONVERSATION WITH SUPPORT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Live Replies Stream
                    _buildRepliesStream(currentRequest),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Reply Composer at Bottom
            _buildReplyComposer(currentRequest, isClosed),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(SupportRequest req) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: req.category.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    ),
                    child: Icon(
                      req.category.icon,
                      color: req.category.accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    req.category.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              // Status & Priority Badges
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: req.priority.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      border: Border.all(color: req.priority.color.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      req.priority.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: req.priority.color,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: req.status.badgeColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                      border: Border.all(color: req.status.badgeColor.withValues(alpha: 0.6)),
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
          const SizedBox(height: 14),
          const Divider(color: AppColors.borderDark, height: 1),
          const SizedBox(height: 12),
          _buildInfoRow('Ticket ID', '#${req.requestId}'),
          const SizedBox(height: 8),
          _buildInfoRow('Category', req.category.title),
          const SizedBox(height: 8),
          _buildInfoRow('Submitted On', req.formattedCreatedAt),
          if (req.resolvedAt != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              'Resolved On',
              '${req.resolvedAt!.day}/${req.resolvedAt!.month}/${req.resolvedAt!.year}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLinkedCards(SupportRequest req) {
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
            'ASSOCIATED DETAILS',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          if (req.rideId != null && req.rideId!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevatedDark,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_taxi_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ride Reference', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                        Text(req.rideId!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (req.paymentId != null && req.paymentId!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevatedDark,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_rounded, color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payment Reference', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                        Text(req.paymentId!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(SupportRequest req) {
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
            'ISSUE DETAILS',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            req.subject,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.space12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevatedDark,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Text(
              req.description,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textPrimaryLight,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentCard(String imageUrl) {
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
                'ATTACHED SCREENSHOT',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Tap to zoom',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _showImageZoom(imageUrl),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevatedDark,
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(Icons.broken_image_rounded, color: AppColors.textSecondaryLight, size: 36),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionCard(String summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
              SizedBox(width: 8),
              Text(
                'RESOLUTION SUMMARY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF10B981),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textPrimaryLight,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepliesStream(SupportRequest req) {
    return StreamBuilder<List<FirestoreComplaintReplyModel>>(
      stream: SupportService().streamReplies(req.requestId),
      builder: (context, snapshot) {
        final replies = snapshot.data ?? [];

        if (replies.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.space16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: const Text(
              'Support team response will appear here when backend support is connected.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: replies.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final reply = replies[index];
            final isAdmin = reply.senderRole == 'ADMIN';

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAdmin
                    ? AppColors.surfaceElevatedDark
                    : AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(
                  color: isAdmin
                      ? AppColors.secondary.withValues(alpha: 0.4)
                      : AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isAdmin ? Icons.support_agent_rounded : Icons.person_rounded,
                            size: 15,
                            color: isAdmin ? AppColors.secondary : AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAdmin ? 'QuickRide Support' : 'You',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isAdmin ? AppColors.secondary : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${reply.createdAt.hour.toString().padLeft(2, '0')}:${reply.createdAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reply.message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimaryLight,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReplyComposer(SupportRequest req, bool isClosed) {
    if (isClosed) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: AppColors.cardDark,
        child: const Center(
          child: Text(
            'This ticket is closed. Please submit a new complaint if you need further help.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.cardDark,
        border: Border(top: BorderSide(color: AppColors.borderDark)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Type your message or follow-up...',
                hintStyle: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                filled: true,
                fillColor: AppColors.surfaceElevatedDark,
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
          const SizedBox(width: 8),
          IconButton(
            icon: _isSendingReply
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.send_rounded, color: AppColors.primary),
            onPressed: _isSendingReply ? null : () => _sendReply(req),
            tooltip: 'Send Reply',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
