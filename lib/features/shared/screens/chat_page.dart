import 'dart:async';

import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/models/app_user.dart';
import 'package:dia_plus/models/chat_message.dart';
import 'package:dia_plus/services/messaging_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Chat screen between current user and another user (doctor-patient).
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
  StreamSubscription<List<ChatMessage>>? _messagesSub;

  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  ChatMessage? _editingMessage;
  int _lastMessageCount = 0;

  String get _conversationId => _messagingService.conversationId(
    widget.currentUser.uid,
    widget.otherUser.uid,
  );

  @override
  void initState() {
    super.initState();
    _messagesSub = _messagingService.streamMessages(_conversationId).listen((
      list,
    ) {
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
    _messagesSub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    final editing = _editingMessage;
    _controller.clear();
    setState(() => _sending = true);
    try {
      if (editing != null) {
        await _messagingService.editMessage(
          conversationId: _conversationId,
          messageId: editing.id,
          senderId: widget.currentUser.uid,
          text: text,
        );
        if (mounted) setState(() => _editingMessage = null);
      } else {
        await _messagingService.sendMessage(
          senderId: widget.currentUser.uid,
          receiverId: widget.otherUser.uid,
          text: text,
          senderName: widget.currentUser.displayName.isNotEmpty
              ? widget.currentUser.displayName
              : null,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _controller.text = text;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Message failed: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _startEdit(ChatMessage message) {
    setState(() {
      _editingMessage = message;
      _controller.text = message.text;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingMessage = null;
      _controller.clear();
    });
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    try {
      await _messagingService.deleteMessage(
        conversationId: _conversationId,
        messageId: message.id,
        senderId: widget.currentUser.uid,
      );
      if (!mounted) return;
      if (_editingMessage?.id == message.id) _cancelEdit();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Future<void> _showMessageActions(ChatMessage message) async {
    if (message.senderId != widget.currentUser.uid || message.isDeleted) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Delete',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;
    if (action == 'edit') {
      _startEdit(message);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('This message will be removed from the chat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _deleteMessage(message);
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
          style: const TextStyle(fontWeight: FontWeight.w600),
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
                        onLongPress: () => _showMessageActions(msg),
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
    final editing = _editingMessage;
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (editing != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECEFF1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Editing message',
                          style: TextStyle(
                            color: AppTheme.textPrimaryColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cancel edit',
                        onPressed: _sending ? null : _cancelEdit,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: editing == null
                            ? 'Type a message...'
                            : 'Edit message...',
                        hintStyle: TextStyle(
                          color: AppTheme.textSecondaryColor(
                            context,
                          ).withValues(alpha: 0.85),
                        ),
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
                        : Icon(
                            editing == null
                                ? Icons.send_rounded
                                : Icons.check_rounded,
                          ),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D6B),
                      foregroundColor: Colors.white,
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
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.onLongPress,
  });

  final ChatMessage message;
  final bool isMe;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(message.createdAt);
    final bubbleBg = message.isDeleted
        ? Colors.white.withValues(alpha: 0.8)
        : isMe
        ? const Color(0xFF2E7D6B)
        : Colors.white;
    final textColor = message.isDeleted
        ? AppTheme.textSecondaryColor(context)
        : isMe
        ? Colors.white
        : AppTheme.textPrimaryColor(context);
    final timeColor = isMe && !message.isDeleted
        ? Colors.white.withValues(alpha: 0.88)
        : AppTheme.textSecondaryColor(context);
    final displayText = message.isDeleted
        ? 'This message was deleted'
        : message.text;
    final metaText = message.isEdited ? '$time - Edited' : time;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
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
            border: isMe && !message.isDeleted
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
                displayText,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  height: 1.35,
                  fontStyle: message.isDeleted
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                metaText,
                style: TextStyle(
                  color: timeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
