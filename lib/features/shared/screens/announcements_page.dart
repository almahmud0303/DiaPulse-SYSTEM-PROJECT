import 'package:dia_plus/models/app_user.dart';
import 'package:dia_plus/models/announcement.dart';
import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/services/announcement_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnnouncementsPage extends StatelessWidget {
  const AnnouncementsPage({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final service = AnnouncementService();
    final fmt = DateFormat('MMM d • HH:mm');

    return StreamBuilder<List<Announcement>>(
      stream: service.streamPublished(role: user.role.value),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              'Failed to load announcements: ${snap.error}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }
        final list = snap.data ?? const <Announcement>[];
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No announcements',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: list.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final a = list[i];
            final ts = a.publishedAt ?? a.createdAt;
            final time = ts == null ? '—' : fmt.format(ts.toLocal());
            return Card(
              color: AppTheme.cardTintLavender,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: AppTheme.secondaryLavender.withValues(alpha: 0.35),
                ),
              ),
              child: ListTile(
                onTap: () async {
                  await service.markRead(uid: user.uid, announcementId: a.id);
                  if (!context.mounted) return;
                  showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(a.title),
                      content: SingleChildScrollView(child: Text(a.body)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundColor: AppTheme.accentPeach.withValues(alpha: 0.4),
                  child: const Icon(
                    Icons.campaign_outlined,
                    color: AppTheme.textPrimary,
                  ),
                ),
                title: Text(
                  a.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  a.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  time,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
