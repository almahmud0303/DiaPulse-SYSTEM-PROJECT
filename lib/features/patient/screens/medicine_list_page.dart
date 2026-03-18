import 'package:dia_plus/features/patient/screens/add_edit_medicine_page.dart';
import 'package:dia_plus/features/patient/screens/medicine_history_page.dart';
import 'package:dia_plus/models/medicine.dart';
import 'package:dia_plus/models/medicine_entry.dart';
import 'package:dia_plus/services/medicine_service.dart';
import 'package:dia_plus/services/reminder_notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class MedicineListPage extends StatefulWidget {
  const MedicineListPage({super.key});

  @override
  State<MedicineListPage> createState() => _MedicineListPageState();
}

class _MedicineListPageState extends State<MedicineListPage> {
  final MedicineService _service = MedicineService();
  String? _userId;
  List<Medicine> _medicines = [];
  Map<String, MedicineEntry?> _todayEntries = {};
  bool _loading = true;
  StreamSubscription<List<Medicine>>? _medSub;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _startRealtime();
  }

  @override
  void dispose() {
    _medSub?.cancel();
    super.dispose();
  }

  void _startRealtime() {
    if (_userId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    _medSub?.cancel();
    _medSub = _service.getMedicinesStream(_userId!).listen((medicines) async {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      // Schedule local notifications at each medicine time when list changes.
      ReminderNotificationService().scheduleMedicineReminders(medicines);
      try {
        final entries =
            await _service.getEntries(_userId!, fromDate: today, toDate: today);
        final entryMap = {for (var e in entries) e.medicineId: e};
        if (!mounted) return;
        setState(() {
          _medicines = medicines;
          _todayEntries = {for (var m in medicines) m.id: entryMap[m.id]};
          _loading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _medicines = medicines;
          _todayEntries = {for (var m in medicines) m.id: null};
          _loading = false;
        });
      }
    }, onError: (_) {
      if (!mounted) return;
      setState(() {
        _medicines = [];
        _todayEntries = {};
        _loading = false;
      });
    });
  }

  Future<void> _load() async {
    // Manual refresh still supported; realtime keeps it updated.
    if (_userId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final medicines = await _service.getMedicines(_userId!);
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final entries = await _service.getEntries(_userId!, fromDate: today, toDate: today);
      final entryMap = {for (var e in entries) e.medicineId: e};
      if (mounted) {
        setState(() {
        _medicines = medicines;
        _todayEntries = {for (var m in medicines) m.id: entryMap[m.id]};
        _loading = false;
      });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
        _medicines = [];
        _todayEntries = {};
        _loading = false;
      });
      }
    }
  }

  Future<void> _markTaken(Medicine medicine) async {
    if (_userId == null) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      await _service.markTaken(userId: _userId!, medicine: medicine, date: today);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as taken'), backgroundColor: Colors.green),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _markMissed(Medicine medicine) async {
    if (_userId == null) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      await _service.markMissed(userId: _userId!, medicine: medicine, date: today);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as missed'), backgroundColor: Colors.orange),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteMedicine(Medicine medicine) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete medicine?'),
        content: Text('Remove ${medicine.name} from your list?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.deleteMedicine(medicine.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medicines'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicineHistoryPage())).then((_) => _load()),
            tooltip: 'History',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _medicines.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medication, size: 80, color: Colors.purple.shade200),
                      const SizedBox(height: 16),
                      Text('No medicines added', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Text('Tap + to add your first medicine', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _medicines.length,
                    itemBuilder: (context, index) {
                      final m = _medicines[index];
                      final entry = _todayEntries[m.id];
                      final taken = entry?.taken ?? false;
                      final missed = entry != null && !entry.taken;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: taken
                                ? Colors.green.shade100
                                : missed
                                    ? Colors.orange.shade100
                                    : Colors.purple.shade50,
                            child: Icon(
                              taken ? Icons.check : (missed ? Icons.close : Icons.medication),
                              color: taken ? Colors.green : (missed ? Colors.orange : Colors.purple),
                            ),
                          ),
                          title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            missed
                                ? 'Missed • ${m.dosage} • ${m.time}'
                                : '${m.dosage} • ${m.time} • ${m.frequency.replaceAll('_', ' ')}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!taken && !missed) ...[
                                TextButton(
                                  onPressed: () => _markTaken(m),
                                  child: const Text('Take'),
                                ),
                                TextButton(
                                  onPressed: () => _markMissed(m),
                                  child: const Text('Missed'),
                                ),
                              ],
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddEditMedicinePage(medicine: m),
                                    ),
                                  );
                                  _load();
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                                onPressed: () => _deleteMedicine(m),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditMedicinePage()),
          );
          _load();
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add),
      ),
    );
  }
}
