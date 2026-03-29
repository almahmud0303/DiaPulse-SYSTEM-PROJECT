import 'package:dia_plus/models/invite_access_request.dart';
import 'package:dia_plus/services/invite_access_request_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Lists pending Doctor/Admin access requests. Approve or reject.
class AdminInviteAccessRequestsPage extends StatefulWidget {
  const AdminInviteAccessRequestsPage({super.key});

  @override
  State<AdminInviteAccessRequestsPage> createState() =>
      _AdminInviteAccessRequestsPageState();
}

class _AdminInviteAccessRequestsPageState
    extends State<AdminInviteAccessRequestsPage> {
  final _service = InviteAccessRequestService();
  final _dateFmt = DateFormat.yMMMd().add_jm();
  int _streamTick = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professional access requests'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Card(
              color: Colors.teal.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Review each applicant. Tap Approve to let them set a second password in the app, '
                  'or Reject to decline (they can submit again if needed).',
                  style: TextStyle(
                    color: Colors.teal.shade900,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<InviteAccessRequest>>(
              key: ValueKey(_streamTick),
              stream: _service.streamPendingForAdmin(),
              builder: (context, snap) {
                if (snap.hasError) {
                  final err = snap.error.toString();
                  final perm = err.contains('permission-denied');
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            perm
                                ? 'Firestore denied this list. Deploy the latest rules '
                                    'and indexes (collection group: access_requests), then retry.'
                                : 'Error: $err',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () =>
                                setState(() => _streamTick++),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snap.data!;
                if (list.isEmpty) {
                  return const Center(
                    child: Text('No pending requests'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final r = list[i];
                    return _RequestTile(
                      request: r,
                      dateFmt: _dateFmt,
                      service: _service,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.request,
    required this.dateFmt,
    required this.service,
  });

  final InviteAccessRequest request;
  final DateFormat dateFmt;
  final InviteAccessRequestService service;

  Future<void> _approve(BuildContext context) async {
    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) return;
    try {
      await service.approve(
        userId: request.userId,
        requestId: request.id,
        adminUid: admin.uid,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Approved — user can finish setup (second password).'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _reject(BuildContext context) async {
    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) return;
    final reasonCtrl = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Reject request'),
          content: TextField(
            controller: reasonCtrl,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
      try {
        await service.reject(
          userId: request.userId,
          requestId: request.id,
          adminUid: admin.uid,
          reason: reasonCtrl.text,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request rejected')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red),
          );
        }
      }
    } finally {
      reasonCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final created = request.createdAt != null
        ? dateFmt.format(request.createdAt!.toLocal())
        : '—';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(request.role.displayName),
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                Text(
                  created,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              request.displayName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SelectableText(
              request.email,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (request.message != null && request.message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                request.message!,
                style: TextStyle(color: Colors.grey.shade800),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _reject(context),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _approve(context),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
