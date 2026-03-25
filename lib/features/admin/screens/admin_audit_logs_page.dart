import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dia_plus/models/audit_log_entry.dart';
import 'package:dia_plus/services/audit_log_service.dart';
import 'package:dia_plus/ui/responsive.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Admin-only list of audit log entries with filters and cursor pagination.
class AdminAuditLogsPage extends StatefulWidget {
  const AdminAuditLogsPage({super.key});

  @override
  State<AdminAuditLogsPage> createState() => _AdminAuditLogsPageState();
}

class _AdminAuditLogsPageState extends State<AdminAuditLogsPage> {
  final _auditLog = AuditLogService();
  final _actorController = TextEditingController();
  final _targetController = TextEditingController();

  String? _actionFilter;
  String? _categoryFilter;
  DateTime? _from;
  DateTime? _to;

  final List<AuditLogEntry> _entries = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  static const int _pageSize = 25;

  static final _dateFmt = DateFormat('yyyy-MM-dd HH:mm');

  @override
  void initState() {
    super.initState();
    _reloadFirstPage();
  }

  @override
  void dispose() {
    _actorController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  AuditLogQueryParams _buildParams() {
    return AuditLogQueryParams(
      action: _actionFilter,
      category: _categoryFilter,
      actorUid: _actorController.text.trim().isEmpty ? null : _actorController.text.trim(),
      targetUid: _targetController.text.trim().isEmpty ? null : _targetController.text.trim(),
      from: _from,
      to: _to,
    );
  }

  Future<void> _reloadFirstPage() async {
    setState(() {
      _loading = true;
      _error = null;
      _entries.clear();
      _lastDoc = null;
      _hasMore = true;
    });
    await _loadNextPage(reset: true);
  }

  Future<void> _loadNextPage({bool reset = false}) async {
    if (_loadingMore) return;
    if (!reset && !_hasMore) return;

    setState(() {
      if (reset) {
        _loading = true;
      } else {
        _loadingMore = true;
      }
      _error = null;
    });

    try {
      final params = _buildParams();
      final result = await _auditLog.fetchAuditLogsPage(
        params: params,
        startAfter: reset ? null : _lastDoc,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _entries
            ..clear()
            ..addAll(result.entries);
        } else {
          _entries.addAll(result.entries);
        }
        _lastDoc = result.lastDocument;
        _hasMore = result.hasMore;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? (_from ?? DateTime.now()) : (_to ?? DateTime.now());
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(initial.year, initial.month, initial.day),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d == null) return;
    setState(() {
      if (isFrom) {
        _from = DateTime(d.year, d.month, d.day);
      } else {
        _to = DateTime(d.year, d.month, d.day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit logs'),
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: Responsive.pagePadding(context),
                child: _FilterPanel(
                  actionFilter: _actionFilter,
                  categoryFilter: _categoryFilter,
                  actorController: _actorController,
                  targetController: _targetController,
                  from: _from,
                  to: _to,
                  onActionChanged: (v) => setState(() => _actionFilter = v),
                  onCategoryChanged: (v) => setState(() => _categoryFilter = v),
                  onPickFrom: () => _pickDate(isFrom: true),
                  onPickTo: () => _pickDate(isFrom: false),
                  onClearDates: () => setState(() {
                    _from = null;
                    _to = null;
                  }),
                  onApply: () => _reloadFirstPage(),
                  onClearFilters: () {
                    setState(() {
                      _actionFilter = null;
                      _categoryFilter = null;
                      _actorController.clear();
                      _targetController.clear();
                      _from = null;
                      _to = null;
                    });
                    _reloadFirstPage();
                  },
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Material(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        _error!,
                        style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: _loading && _entries.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _reloadFirstPage,
                        child: _entries.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 80),
                                  Center(child: Text('No audit entries match these filters.')),
                                ],
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: Responsive.pagePadding(context).copyWith(top: 0),
                                itemCount: _entries.length + (_hasMore ? 1 : 0),
                                itemBuilder: (context, i) {
                                  if (i >= _entries.length) {
                                    return Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Center(
                                        child: _loadingMore
                                            ? const CircularProgressIndicator()
                                            : TextButton.icon(
                                                onPressed: () => _loadNextPage(),
                                                icon: const Icon(Icons.expand_more),
                                                label: const Text('Load more'),
                                              ),
                                      ),
                                    );
                                  }
                                  return _AuditLogTile(entry: _entries[i], dateFmt: _dateFmt);
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.actionFilter,
    required this.categoryFilter,
    required this.actorController,
    required this.targetController,
    required this.from,
    required this.to,
    required this.onActionChanged,
    required this.onCategoryChanged,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onClearDates,
    required this.onApply,
    required this.onClearFilters,
  });

  final String? actionFilter;
  final String? categoryFilter;
  final TextEditingController actorController;
  final TextEditingController targetController;
  final DateTime? from;
  final DateTime? to;
  final ValueChanged<String?> onActionChanged;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onClearDates;
  final VoidCallback onApply;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Filters',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String?>(
                key: ValueKey<String?>('action_$actionFilter'),
                initialValue: actionFilter,
                decoration: const InputDecoration(
                  labelText: 'Action',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('All')),
                  ...[
                    AuditLogActions.loginSuccess,
                    AuditLogActions.loginBlocked,
                    AuditLogActions.adminSetRole,
                    AuditLogActions.adminSetBlocked,
                    AuditLogActions.adminDeleteUser,
                  ].map(
                    (a) => DropdownMenuItem<String?>(
                      value: a,
                      child: Text(a, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: onActionChanged,
              ),
            ),
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<String?>(
                key: ValueKey<String?>('cat_$categoryFilter'),
                initialValue: categoryFilter,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem<String?>(value: null, child: Text('All')),
                  DropdownMenuItem<String?>(
                    value: AuditLogCategories.auth,
                    child: Text('auth'),
                  ),
                  DropdownMenuItem<String?>(
                    value: AuditLogCategories.admin,
                    child: Text('admin'),
                  ),
                ],
                onChanged: onCategoryChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: actorController,
          decoration: const InputDecoration(
            labelText: 'Actor UID',
            hintText: 'Filter by actor user id',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: targetController,
          decoration: const InputDecoration(
            labelText: 'Target UID',
            hintText: 'Filter by target user id (admin actions)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton(
              onPressed: onPickFrom,
              child: Text(from == null ? 'From date' : 'From: ${from!.toIso8601String().split('T').first}'),
            ),
            OutlinedButton(
              onPressed: onPickTo,
              child: Text(to == null ? 'To date' : 'To: ${to!.toIso8601String().split('T').first}'),
            ),
            TextButton(onPressed: onClearDates, child: const Text('Clear dates')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton(onPressed: onApply, child: const Text('Apply')),
            const SizedBox(width: 12),
            OutlinedButton(onPressed: onClearFilters, child: const Text('Reset filters')),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Entries are ordered by time (newest first). Use “Load more” for the next page. '
          'Deploy firestore.indexes.json if a query fails with a missing index.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}

class _AuditLogTile extends StatelessWidget {
  const _AuditLogTile({
    required this.entry,
    required this.dateFmt,
  });

  final AuditLogEntry entry;
  final DateFormat dateFmt;

  static String _actionLabel(String action) {
    switch (action) {
      case AuditLogActions.loginSuccess:
        return 'Login success';
      case AuditLogActions.loginBlocked:
        return 'Login blocked (suspended)';
      case AuditLogActions.adminSetRole:
        return 'Admin: set role';
      case AuditLogActions.adminSetBlocked:
        return 'Admin: suspend / unsuspend';
      case AuditLogActions.adminDeleteUser:
        return 'Admin: delete user data';
      default:
        return action;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = entry.createdAt;
    final timeStr = t != null ? dateFmt.format(t.toLocal()) : '—';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(
          _actionLabel(entry.action),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Time: $timeStr', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
              const SizedBox(height: 4),
              Text('Actor: ${entry.actorId}', style: const TextStyle(fontSize: 12)),
              if (entry.targetUserId != null && entry.targetUserId!.isNotEmpty)
                Text('Target: ${entry.targetUserId}', style: const TextStyle(fontSize: 12)),
              Text('Category: ${entry.category}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            ],
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SelectableText(
                entry.metadata.isEmpty
                    ? 'No metadata'
                    : entry.metadata.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
