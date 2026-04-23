import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/models/app_user.dart';
import 'package:dia_plus/models/chat_message.dart';
import 'package:dia_plus/services/messaging_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Chat screen between current user and another user (doctor ↔ patient).
/// Messages load from Firebase Realtime Database (oldest at top, newest at bottom).
class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.currentUser,
    required this.otherUser,
  });

  final AppUser currentUser;
  final AppUser otherUser;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final MessagingService _messagingService = MessagingService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  int _lastMessageCount = 0;

  String get _conversationId =>
      _messagingService.conversationId(widget.currentUser.uid, widget.otherUser.uid);

  @override
  void initState() {
    super.initState();
    _messagingService.streamMessages(_conversationId).listen((list) {
      if (!mounted) return;
      final grew = list.length > _lastMessageCount;
      _lastMessageCount = list.length;
      setState(() => _messages = list);
      if (grew || (_loading && list.isNotEmpty)) {
        _scrollToBottom();
      }
    });
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    final list = await _messagingService.getMessages(_conversationId);
    if (mounted) {
      setState(() {
        _messages = list;
        _lastMessageCount = list.length;
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        max,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() => _sending = true);
    try {
      await _messagingService.sendMessage(
        senderId: widget.currentUser.uid,
        receiverId: widget.otherUser.uid,
        text: text,
        senderName: widget.currentUser.displayName.isNotEmpty
            ? widget.currentUser.displayName
            : null,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherName = widget.otherUser.displayName.isNotEmpty
        ? widget.otherUser.displayName
        : widget.otherUser.email;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(
          otherName,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: AppTheme.primaryMint,
        foregroundColor: AppTheme.textPrimaryColor(context),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet. Say hello!',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor(context),
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return _MessageBubble(
                            message: msg,
                            isMe: msg.senderId == widget.currentUser.uid,
                          );
                        },
                      ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Material(
      elevation: 8,
      shadowColor: Colors.black26,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 8,
          bottom: 8 + MediaQuery.of(context).padding.bottom,
        ),
        child: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Type a message…',
                    hintStyle: TextStyle(color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.85)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFECEFF1),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textPrimaryColor(context),
                    height: 1.35,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 4,
                  minLines: 1,
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.send_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D6B),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});

  final ChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(message.createdAt);
    final bubbleBg = isMe ? const Color(0xFF2E7D6B) : Colors.white;
    final textColor = isMe ? Colors.white : AppTheme.textPrimaryColor(context);
    final timeColor =
        isMe ? Colors.white.withValues(alpha: 0.88) : AppTheme.textSecondaryColor(context);
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bubbleBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe
              ? null
              : Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: timeColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
