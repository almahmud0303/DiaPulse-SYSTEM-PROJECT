import 'package:dia_plus/models/app_user.dart';
import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/models/conversation.dart';
import 'package:dia_plus/services/auth_service.dart';
import 'package:dia_plus/services/doctor_patient_service.dart';
import 'package:dia_plus/services/messaging_service.dart';
import 'package:dia_plus/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'chat_page.dart';
import 'notifications_page.dart';
import 'select_conversation_partner_page.dart';

/// Lists conversations for the current user (doctor or patient). Tap to open chat.
class ConversationListPage extends StatefulWidget {
  const ConversationListPage({super.key});

  @override
  State<ConversationListPage> createState() => _ConversationListPageState();
}

class _ConversationListPageState extends State<ConversationListPage> {
  final AuthService _authService = AuthService();
  final MessagingService _messagingService = MessagingService();
  final DoctorPatientService _userService = DoctorPatientService();
  final NotificationService _notificationService = NotificationService();

  AppUser? _currentUser;
  List<Conversation> _conversations = [];
  Map<String, AppUser> _otherUsers = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _authService.getAppUser();
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _error = 'Not signed in';
          _loading = false;
        });
        return;
      }
      final list = await _messagingService.getConversations(user.uid);
      final others = <String, AppUser>{};
      for (final c in list) {
        final otherId = c.otherParticipantId(user.uid);
        if (otherId.isNotEmpty && !others.containsKey(otherId)) {
          final other = await _userService.getPatientProfile(otherId);
          if (other != null) others[otherId] = other;
        }
      }
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _conversations = list;
        _otherUsers = others;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          if (_currentUser != null)
            StreamBuilder<int>(
              stream: _notificationService.streamUnreadCount(_currentUser!.uid),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return IconButton(
                  tooltip: 'Notifications',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const NotificationsPage(),
                      ),
                    );
                  },
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(Icons.notifications),
                      if (count > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.softError,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              count > 99 ? '99+' : '$count',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: _currentUser != null
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute<void>(
                        builder: (context) =>
                            const SelectConversationPartnerPage(),
                      ),
                    )
                    .then((_) => _load());
              },
              backgroundColor: AppTheme.primaryMint,
              child: Icon(Icons.add),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : _conversations.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 12),
                itemCount: _conversations.length,
                itemBuilder: (context, index) {
                  final c = _conversations[index];
                  final otherId = _currentUser != null
                      ? c.otherParticipantId(_currentUser!.uid)
                      : '';
                  final other = _otherUsers[otherId];
                  final name = (other != null && other.displayName.isNotEmpty)
                      ? other.displayName
                      : (other?.email ?? 'Unknown');
                  return _ConversationTile(
                    conversation: c,
                    otherName: name,
                    onTap: () {
                      if (_currentUser != null && other != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => ChatPage(
                              currentUser: _currentUser!,
                              otherUser: other,
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondaryColor(context)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textSecondaryColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'When you or a patient sends a message, it will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondaryColor(context),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.otherName,
    required this.onTap,
  });

  final Conversation conversation;
  final String otherName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('MMM d').format(conversation.lastMessageAt);
    return Card(
      color: AppTheme.cardTintMintColor(context),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: AppTheme.secondaryLavender.withValues(alpha: 0.25),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppTheme.secondaryLavender.withValues(alpha: 0.35),
          child: Text(
            otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
            style: TextStyle(
              color: AppTheme.textPrimaryColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Text(
          otherName,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          conversation.lastMessageText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppTheme.textSecondaryColor(context), fontSize: 13),
        ),
        trailing: Text(
          time,
          style: TextStyle(color: AppTheme.textSecondaryColor(context), fontSize: 12),
        ),
      ),
    );
  }
}
