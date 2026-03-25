import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/app_user.dart';
import 'package:dia_plus/models/user_role.dart';
import 'package:dia_plus/services/admin_user_service.dart';
import 'package:dia_plus/ui/responsive.dart';
import 'package:flutter/material.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  final _searchController = TextEditingController();
  UserRole? _roleFilter;
  final _adminUserService = AdminUserService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Query<Map<String, dynamic>> _baseQuery() {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection('users');
    if (_roleFilter != null) {
      q = q.where('role', isEqualTo: _roleFilter!.value);
    }
    return q;
  }

  bool _matchesSearch(AppUser u) {
    final s = _searchController.text.trim().toLowerCase();
    if (s.isEmpty) return true;
    return u.displayName.toLowerCase().contains(s) ||
        u.email.toLowerCase().contains(s) ||
        u.uid.toLowerCase().contains(s) ||
        (u.phone ?? '').toLowerCase().contains(s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: Padding(
            padding: Responsive.pagePadding(context),
            child: Column(
              children: [
                _FiltersBar(
                  searchController: _searchController,
                  roleFilter: _roleFilter,
                  onRoleChanged: (r) => setState(() => _roleFilter = r),
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _baseQuery().snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Center(
                          child: Text('Failed to load users: ${snap.error}'),
                        );
                      }

                      final docs = snap.data?.docs ?? const [];
                      final users = <AppUser>[];
                      for (final d in docs) {
                        final u = AppUser.fromMap(d.id, d.data());
                        if (_matchesSearch(u)) users.add(u);
                      }

                      users.sort((a, b) {
                        final r = a.role.name.compareTo(b.role.name);
                        if (r != 0) return r;
                        return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
                      });

                      if (users.isEmpty) {
                        return const _EmptyUsers();
                      }

                      return ListView.separated(
                        itemCount: users.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _UserCard(
                          user: users[i],
                          onChangeRole: (newRole) async {
                            try {
                              await _adminUserService.setUserRole(
                                uid: users[i].uid,
                                role: newRole,
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Role updated to ${newRole.displayName}')),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to update role: $e')),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.searchController,
    required this.roleFilter,
    required this.onRoleChanged,
    required this.onChanged,
  });

  final TextEditingController searchController;
  final UserRole? roleFilter;
  final ValueChanged<UserRole?> onRoleChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: searchController,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            hintText: 'Search name, email, phone, uid…',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<UserRole?>(
                value: roleFilter,
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<UserRole?>(
                    value: null,
                    child: Text('All roles'),
                  ),
                  ...UserRole.values.map(
                    (r) => DropdownMenuItem<UserRole?>(
                      value: r,
                      child: Text(r.displayName),
                    ),
                  ),
                ],
                onChanged: onRoleChanged,
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              tooltip: 'Clear search',
              onPressed: () {
                searchController.clear();
                onChanged();
              },
              icon: const Icon(Icons.clear),
            ),
          ],
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onChangeRole});

  final AppUser user;
  final Future<void> Function(UserRole newRole) onChangeRole;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.deepPurple.withValues(alpha: 0.12),
              child: Text(
                user.initials,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.displayName.isEmpty ? '(No name)' : user.displayName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      _RoleChip(role: user.role),
                      const SizedBox(width: 6),
                      PopupMenuButton<_UserAction>(
                        tooltip: 'Actions',
                        onSelected: (action) async {
                          switch (action) {
                            case _UserAction.changeRole:
                              final picked = await showDialog<UserRole>(
                                context: context,
                                builder: (context) => _RolePickerDialog(current: user.role),
                              );
                              if (picked == null || picked == user.role) return;
                              await onChangeRole(picked);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: _UserAction.changeRole,
                            child: ListTile(
                              dense: true,
                              leading: Icon(Icons.admin_panel_settings_outlined),
                              title: Text('Change role'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email.isEmpty ? '(No email)' : user.email,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  if ((user.phone ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.phone!.trim(),
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'UID: ${user.uid}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (role) {
      UserRole.patient => (Colors.green.withValues(alpha: 0.12), Colors.green.shade800),
      UserRole.doctor => (Colors.blue.withValues(alpha: 0.12), Colors.blue.shade800),
      UserRole.admin => (Colors.deepPurple.withValues(alpha: 0.12), Colors.deepPurple.shade800),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        role.displayName,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _EmptyUsers extends StatelessWidget {
  const _EmptyUsers();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 10),
            const Text(
              'No users found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Try clearing the search or role filter.',
              style: TextStyle(color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

enum _UserAction { changeRole }

class _RolePickerDialog extends StatelessWidget {
  const _RolePickerDialog({required this.current});

  final UserRole current;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change role'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final r in UserRole.values)
            RadioListTile<UserRole>(
              value: r,
              groupValue: current,
              onChanged: (v) => Navigator.of(context).pop(v),
              title: Text(r.displayName),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

