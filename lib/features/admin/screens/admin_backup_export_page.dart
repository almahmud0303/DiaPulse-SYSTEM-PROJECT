import 'package:dia_plus/services/admin_backup_service.dart';
import 'package:dia_plus/services/backup_file_saver.dart';
import 'package:dia_plus/ui/responsive.dart';
import 'package:flutter/material.dart';

class AdminBackupExportPage extends StatefulWidget {
  const AdminBackupExportPage({super.key});

  @override
  State<AdminBackupExportPage> createState() => _AdminBackupExportPageState();
}

class _AdminBackupExportPageState extends State<AdminBackupExportPage> {
  final _backupService = AdminBackupService();
  final Set<String> _selected = {...AdminBackupService.defaultCollections};
  bool _isExporting = false;
  String? _lastResult;

  Future<void> _export() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select at least one collection.')));
      return;
    }
    setState(() {
      _isExporting = true;
      _lastResult = null;
    });

    try {
      final backup = await _backupService.generateBackup(
        collections: _selected.toList(),
      );
      final json = _backupService.toPrettyJson(backup);
      final path = await saveBackupJson(
        filename: _backupService.buildDefaultFilename(),
        jsonContent: json,
      );
      if (!mounted) return;
      setState(() {
        _lastResult = path;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup export completed: $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup export failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Backup Export')),
      body: SafeArea(
        child: ResponsiveCenter(
          child: Padding(
            padding: Responsive.pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export selected collections to JSON',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Web: file download starts in browser. Desktop: file is written to Downloads (or app documents fallback).',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selected
                            ..clear()
                            ..addAll(AdminBackupService.defaultCollections);
                        });
                      },
                      child: const Text('Select all'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        setState(_selected.clear);
                      },
                      child: const Text('Clear all'),
                    ),
                    FilledButton.icon(
                      onPressed: _isExporting ? null : _export,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download),
                      label: Text(_isExporting ? 'Exporting...' : 'Export backup'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_lastResult != null)
                  SelectableText(
                    'Last export: $_lastResult',
                    style: TextStyle(color: Colors.green.shade800, fontSize: 12),
                  ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: AdminBackupService.defaultCollections.map((c) {
                      return CheckboxListTile(
                        value: _selected.contains(c),
                        title: Text(c),
                        dense: true,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selected.add(c);
                            } else {
                              _selected.remove(c);
                            }
                          });
                        },
                      );
                    }).toList(),
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
