import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/firestore_models.dart';
import '../../services/chat_service.dart';
import '../../widgets/offline_banner.dart';

/// Real-time chat screen between User (passenger) and assigned Captain.
class ChatScreen extends StatefulWidget {
  final String rideId;
  final String currentUserId;
  final String currentUserName;
  final String captainId;
  final String captainName;
  final String captainPhone;
  final String vehicleType;
  final String vehicleNumber;
  final String? rideStatus; // 'ACCEPTED', 'ARRIVED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'

  const ChatScreen({
    super.key,
    required this.rideId,
    required this.currentUserId,
    this.currentUserName = 'Rider',
    required this.captainId,
    this.captainName = 'Captain',
    this.captainPhone = '',
    this.vehicleType = 'Bike',
    this.vehicleNumber = '',
    this.rideStatus,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ChatService _chatService = ChatService();
  bool _isSending = false;

  static const List<String> _quickResponses = [
    "I'm at the pickup location",
    "On my way down now",
    "Please call when you arrive",
    "Where are you right now?",
    "Okay, got it!",
  ];

  bool get _isChatClosed {
    final status = widget.rideStatus?.toUpperCase().replaceAll(' ', '_');
    return status == 'COMPLETED' || status == 'CANCELLED';
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage([String? predefinedText]) async {
    final text = predefinedText ?? _messageController.text;
    final trimmed = text.trim();

    if (trimmed.isEmpty || _isSending || _isChatClosed) return;

    if (trimmed.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message cannot exceed 500 characters.')),
      );
      return;
    }

    setState(() => _isSending = true);
    if (predefinedText == null) {
      _messageController.clear();
    }

    final success = await _chatService.sendMessage(
      rideId: widget.rideId,
      senderId: widget.currentUserId,
      senderName: widget.currentUserName,
      senderRole: 'USER',
      message: trimmed,
      rideStatus: widget.rideStatus,
    );

    if (mounted) {
      setState(() => _isSending = false);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message. Please try again.')),
        );
      } else {
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimaryDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.captainName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${widget.vehicleType}${widget.vehicleNumber.isNotEmpty ? ' • ${widget.vehicleNumber}' : ''}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondaryDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.captainPhone.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.call_rounded, color: AppColors.primary),
              tooltip: 'Call Captain',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Calling ${widget.captainName} (${widget.captainPhone})...')),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            // Chat Closed Notice (if completed or cancelled)
            if (_isChatClosed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.amber.shade900.withValues(alpha: 0.3),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ride is ${widget.rideStatus ?? 'closed'}. New messages cannot be sent.',
                        style: const TextStyle(
                          color: AppColors.textPrimaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Messages Stream List
            Expanded(
              child: StreamBuilder<List<FirestoreChatMessageModel>>(
                stream: _chatService.streamMessages(widget.rideId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  final messages = snapshot.data ?? [];

                  // Auto mark unread messages as read
                  if (messages.isNotEmpty) {
                    _chatService.markAllReceivedAsRead(
                      rideId: widget.rideId,
                      currentUserId: widget.currentUserId,
                      messages: messages,
                    );
                  }

                  if (messages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimensions.space24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevatedDark,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: AppColors.secondary,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No messages yet',
                              style: TextStyle(
                                color: AppColors.textPrimaryDark,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Coordinate pickup details or ask questions directly with your Captain.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondaryDark,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == widget.currentUserId;
                      return _buildMessageBubble(msg, isMe);
                    },
                  );
                },
              ),
            ),

            // Quick Response Chips (shown only when chat is active)
            if (!_isChatClosed)
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _quickResponses.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final responseText = _quickResponses[index];
                    return ActionChip(
                      label: Text(
                        responseText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      backgroundColor: AppColors.surfaceElevatedDark,
                      side: const BorderSide(color: AppColors.borderDark),
                      onPressed: () => _handleSendMessage(responseText),
                    );
                  },
                ),
              ),

            // Input bar
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(FirestoreChatMessageModel msg, bool isMe) {
    final timeStr = '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primary.withValues(alpha: 0.9)
              : AppColors.surfaceElevatedDark,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: Border.all(
            color: isMe ? AppColors.primary : AppColors.borderDark,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe && msg.senderName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  msg.senderName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            Text(
              msg.message,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? const Color(0xFF0F172A) : AppColors.textPrimaryDark,
                fontWeight: isMe ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? const Color(0xFF334155)
                        : AppColors.textSecondaryDark,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.read ? Icons.done_all_rounded : Icons.check_rounded,
                    size: 13,
                    color: msg.read ? const Color(0xFF0F172A) : const Color(0xFF475569),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: const Border(top: BorderSide(color: AppColors.borderDark)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              enabled: !_isChatClosed && !_isSending,
              maxLength: 500,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
              style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 14),
              decoration: InputDecoration(
                hintText: _isChatClosed ? 'Chat is closed' : 'Type a message...',
                hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
                filled: true,
                fillColor: AppColors.surfaceElevatedDark,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.borderDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              onSubmitted: (_) => _handleSendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: (_isChatClosed || _isSending) ? null : () => _handleSendMessage(),
            icon: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.send_rounded),
            color: AppColors.primary,
            disabledColor: AppColors.textSecondaryDark.withValues(alpha: 0.4),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceElevatedDark,
              padding: const EdgeInsets.all(10),
            ),
          ),
        ],
      ),
    );
  }
}
