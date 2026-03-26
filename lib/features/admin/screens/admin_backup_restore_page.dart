import 'package:dia_plus/services/admin_restore_service.dart';
import 'package:dia_plus/ui/responsive.dart';
import 'package:flutter/material.dart';

class AdminBackupRestorePage extends StatefulWidget {
  const AdminBackupRestorePage({super.key});

  @override
  State<AdminBackupRestorePage> createState() => _AdminBackupRestorePageState();
}

class _AdminBackupRestorePageState extends State<AdminBackupRestorePage> {
  final _restoreService = AdminRestoreService();
  final _jsonController = TextEditingController();
  BackupValidationResult? _validation;
  Set<String> _selected = {};
  bool _busy = false;
  String? _result;

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  void _runValidation() {
    final validation = _restoreService.validateBackupJson(_jsonController.text);
    setState(() {
      _validation = validation;
      _result = null;
      _selected = validation.detectedCollections
          .where(
            (c) => !AdminRestoreService.defaultSkippedCollections.contains(c),
          )
          .toSet();
    });
  }

  Future<void> _runRestore({required bool dryRun}) async {
    if (_validation == null || !_validation!.isValid) {
      _runValidation();
      if (_validation == null || !_validation!.isValid) return;
    }
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select at least one collection.')));
      return;
    }
    if (!dryRun) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Confirm restore import'),
            content: const Text(
              'This writes data to Firestore and may overwrite existing fields.\n\nContinue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Import now'),
              ),
            ],
          );
        },
      );
      if (confirm != true) return;
    }

    setState(() {
      _busy = true;
      _result = null;
    });

    try {
      final res = await _restoreService.restoreFromJson(
        jsonText: _jsonController.text,
        dryRun: dryRun,
        selectedCollections: _selected,
      );
      if (!mounted) return;
      final summary =
          '${dryRun ? 'Dry-run' : 'Import'} complete. '
          'Processed: ${res.processedDocuments}, '
          'Written: ${res.writtenDocuments}, '
          'Failed: ${res.failedDocuments}.';
      setState(() {
        _result = [
          summary,
          if (res.collectionCounts.isNotEmpty)
            'Collections: ${res.collectionCounts.entries.map((e) => '${e.key}=${e.value}').join(', ')}',
          if (res.failures.isNotEmpty) ...res.failures.take(20),
          if (res.failures.length > 20)
            '...and ${res.failures.length - 20} more failure(s).',
        ].join('\n');
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(summary)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _validation;
    return Scaffold(
      appBar: AppBar(title: const Text('Data Restore Import')),
      body: SafeArea(
        child: ResponsiveCenter(
          child: Padding(
            padding: Responsive.pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paste backup JSON',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Step 1: Paste exported JSON.\n'
                  'Step 2: Validate.\n'
                  'Step 3: Dry-run.\n'
                  'Step 4: Import.',
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TextField(
                    controller: _jsonController,
                    expands: true,
                    maxLines: null,
                    minLines: null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '{ "meta": ..., "collections": ... }',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _runValidation,
                      icon: const Icon(Icons.rule),
                      label: const Text('Validate'),
                    ),
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _runRestore(dryRun: true),
                      icon: _busy
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.visibility),
                      label: const Text('Dry-run'),
                    ),
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _runRestore(dryRun: false),
                      icon: const Icon(Icons.publish),
                      label: const Text('Import'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (v != null) ...[
                  Text(
                    v.isValid
                        ? 'Validation passed. ${v.totalDocuments} docs detected.'
                        : 'Validation failed (${v.errors.length} error(s)).',
                    style: TextStyle(
                      color: v.isValid ? Colors.green.shade800 : Colors.red.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (v.warnings.isNotEmpty)
                    Text(
                      'Warnings: ${v.warnings.join(' | ')}',
                      style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: v.detectedCollections.map((c) {
                      final selected = _selected.contains(c);
                      return FilterChip(
                        label: Text(c),
                        selected: selected,
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _selected.add(c);
                            } else {
                              _selected.remove(c);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
                if (_result != null) ...[
                  const SizedBox(height: 10),
                  SelectableText(
                    _result!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
