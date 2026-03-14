import 'package:dia_plus/models/medicine_entry.dart';
import 'package:dia_plus/services/medicine_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MedicineHistoryPage extends StatefulWidget {
  const MedicineHistoryPage({super.key});

  @override
  State<MedicineHistoryPage> createState() => _MedicineHistoryPageState();
}

class _MedicineHistoryPageState extends State<MedicineHistoryPage> {
  final MedicineService _service = MedicineService();
  String? _userId;
  List<MedicineEntry> _entries = [];
  bool _loading = true;
  bool _showTakenOnly = false;
  bool _showMissedOnly = false;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _load();
  }

  Future<void> _load() async {
    if (_userId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      var list = await _service.getEntries(_userId!);
      if (_showTakenOnly) list = list.where((e) => e.taken).toList();
      if (_showMissedOnly) list = list.where((e) => !e.taken).toList();
      if (mounted) {
        setState(() {
        _entries = list;
        _loading = false;
      });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
        _entries = [];
        _loading = false;
      });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicine History')),
      body: _userId == null
          ? const Center(child: Text('Please log in'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: !_showTakenOnly && !_showMissedOnly,
                        onSelected: (_) {
                          setState(() {
                            _showTakenOnly = false;
                            _showMissedOnly = false;
                            _load();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Taken'),
                        selected: _showTakenOnly,
                        onSelected: (_) {
                          setState(() {
                            _showTakenOnly = true;
                            _showMissedOnly = false;
                            _load();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Missed'),
                        selected: _showMissedOnly,
                        onSelected: (_) {
                          setState(() {
                            _showTakenOnly = false;
                            _showMissedOnly = true;
                            _load();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _entries.isEmpty
                          ? Center(
                              child: Text(
                                'No entries',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _entries.length,
                              itemBuilder: (context, index) {
                                final e = _entries[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: Icon(
                                      e.taken ? Icons.check_circle : Icons.cancel,
                                      color: e.taken ? Colors.green : Colors.orange,
                                      size: 32,
                                    ),
                                    title: Text(e.medicineName),
                                    subtitle: Text(
                                      '${e.date}${e.takenAt != null ? ' • ${DateFormat('h:mm a').format(e.takenAt!)}' : ''}',
                                    ),
                                    trailing: Text(
                                      e.taken ? 'Taken' : 'Missed',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: e.taken ? Colors.green : Colors.orange,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}
