import 'package:dia_plus/models/announcement.dart';
import 'package:dia_plus/services/admin_announcement_service.dart';
import 'package:dia_plus/ui/responsive.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminAnnouncementManagementPage extends StatefulWidget {
  const AdminAnnouncementManagementPage({super.key});

  @override
  State<AdminAnnouncementManagementPage> createState() => _AdminAnnouncementManagementPageState();
}

class _AdminAnnouncementManagementPageState extends State<AdminAnnouncementManagementPage> {
  final _service = AdminAnnouncementService();
  final _fmt = DateFormat('yyyy-MM-dd HH:mm');

  Future<void> _showCreateDialog() async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String? role;
    bool publishNow = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New announcement'),
          content: SizedBox(
            width: 540,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bodyController,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Body', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Target role', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem<String?>(value: null, child: Text('All users')),
                    DropdownMenuItem<String?>(value: 'patient', child: Text('Patients')),
                    DropdownMenuItem<String?>(value: 'doctor', child: Text('Doctors')),
                    DropdownMenuItem<String?>(value: 'admin', child: Text('Admins')),
                  ],
                  onChanged: (v) => setState(() => role = v),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: publishNow,
                  title: const Text('Publish now'),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => publishNow = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (titleController.text.trim().isEmpty || bodyController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and body are required.')));
      return;
    }
    await _service.create(
      title: titleController.text,
      body: bodyController.text,
      targetRole: role,
      published: publishNow,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement created.')));
  }

  Future<void> _showEditDialog(Announcement a) async {
    final titleController = TextEditingController(text: a.title);
    final bodyController = TextEditingController(text: a.body);
    String? role = a.targetRole;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit announcement'),
          content: SizedBox(
            width: 540,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bodyController,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Body', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Target role', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem<String?>(value: null, child: Text('All users')),
                    DropdownMenuItem<String?>(value: 'patient', child: Text('Patients')),
                    DropdownMenuItem<String?>(value: 'doctor', child: Text('Doctors')),
                    DropdownMenuItem<String?>(value: 'admin', child: Text('Admins')),
                  ],
                  onChanged: (v) => setState(() => role = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await _service.updateAnnouncement(
      id: a.id,
      title: titleController.text,
      body: bodyController.text,
      targetRole: role,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Management'),
        actions: [
          IconButton(onPressed: _showCreateDialog, icon: const Icon(Icons.add)),
        ],
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: Padding(
            padding: Responsive.pagePadding(context),
            child: StreamBuilder<List<Announcement>>(
              stream: _service.watchAll(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) return Center(child: Text('Failed: ${snap.error}'));
                final list = snap.data ?? const <Announcement>[];
                if (list.isEmpty) {
                  return Center(
                    child: FilledButton.icon(
                      onPressed: _showCreateDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Create first announcement'),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final a = list[i];
                    final created = a.createdAt != null ? _fmt.format(a.createdAt!.toLocal()) : '...';
                    return Card(
                      child: ListTile(
                        title: Text(a.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(a.body, maxLines: 3, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              children: [
                                Chip(label: Text(a.published ? 'Published' : 'Draft')),
                                Chip(label: Text('Target: ${a.targetRole ?? 'all'}')),
                                Chip(label: Text('Created: $created')),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'edit') return _showEditDialog(a);
                            if (v == 'toggle') {
                              return _service.setPublished(id: a.id, published: !a.published);
                            }
                            if (v == 'delete') {
                              final yes = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete announcement?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                  ],
                                ),
                              );
                              if (yes == true) {
                                await _service.delete(a.id);
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'toggle', child: Text(a.published ? 'Unpublish' : 'Publish')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.campaign),
        label: const Text('New'),
      ),
    );
  }
}
