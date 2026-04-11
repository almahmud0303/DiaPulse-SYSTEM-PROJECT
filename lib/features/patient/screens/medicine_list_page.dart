import 'package:dia_plus/features/patient/screens/add_edit_medicine_page.dart';
import 'package:dia_plus/features/patient/screens/medicine_history_page.dart';
import 'package:dia_plus/models/medicine.dart';
import 'package:dia_plus/models/medicine_entry.dart';
import 'package:dia_plus/models/prescription.dart';
import 'package:dia_plus/models/meal_routine.dart';
import 'package:dia_plus/services/meal_routine_service.dart';
import 'package:dia_plus/services/medicine_service.dart';
import 'package:dia_plus/services/reminder_notification_service.dart';
import 'package:dia_plus/ui/responsive.dart';
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
  List<Prescription> _prescriptions = [];
  final Set<String> _expandedPrescriptionIds = {};
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
      MealRoutine? mealRoutine;
      try {
        mealRoutine = await MealRoutineService().getRoutine(_userId!);
      } catch (_) {}
      await ReminderNotificationService().scheduleMedicineReminders(
        medicines,
        mealRoutine: mealRoutine,
      );
      try {
        final prescriptions = await _service.getPrescriptions(_userId!);
        final entries =
            await _service.getEntries(_userId!, fromDate: today, toDate: today);
        final entryMap = {for (var e in entries) e.medicineId: e};
        if (!mounted) return;
        setState(() {
          _medicines = medicines;
          _prescriptions = prescriptions;
          _todayEntries = {for (var m in medicines) m.id: entryMap[m.id]};
          _loading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _medicines = medicines;
          // Keep old list if loading prescriptions fails.
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
      final prescriptions = await _service.getPrescriptions(_userId!);
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final entries = await _service.getEntries(_userId!, fromDate: today, toDate: today);
      final entryMap = {for (var e in entries) e.medicineId: e};
      if (mounted) {
        setState(() {
        _medicines = medicines;
        _prescriptions = prescriptions;
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

  Map<String?, List<Medicine>> get _medicinesByPrescription {
    final map = <String?, List<Medicine>>{};
    for (final m in _medicines) {
      map.putIfAbsent(m.prescriptionId, () => []).add(m);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    return map;
  }

  Widget _buildGroupedList() {
    final byRx = _medicinesByPrescription;
    final df = DateFormat('MMM d, yyyy · HH:mm');

    final tiles = <Widget>[];

    for (final rx in _prescriptions) {
      final meds = byRx[rx.id];
      if (meds == null || meds.isEmpty) continue;
      final expanded = _expandedPrescriptionIds.contains(rx.id);
      tiles.add(
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.assignment_outlined),
                title: Text(
                  'Prescription · ${df.format(rx.createdAt)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('${meds.length} medicine${meds.length == 1 ? '' : 's'}'),
                trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                onTap: () {
                  setState(() {
                    if (expanded) {
                      _expandedPrescriptionIds.remove(rx.id);
                    } else {
                      _expandedPrescriptionIds.add(rx.id);
                    }
                  });
                },
              ),
              if (expanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    children: meds.map(_medicineRow).toList(),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final legacy = byRx[null];
    if (legacy != null && legacy.isNotEmpty) {
      final expanded = _expandedPrescriptionIds.contains('legacy');
      tiles.add(
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.medication_outlined),
                title: const Text('Other medicines', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${legacy.length} item${legacy.length == 1 ? '' : 's'}'),
                trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                onTap: () {
                  setState(() {
                    if (expanded) {
                      _expandedPrescriptionIds.remove('legacy');
                    } else {
                      _expandedPrescriptionIds.add('legacy');
                    }
                  });
                },
              ),
              if (expanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    children: legacy.map(_medicineRow).toList(),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // If prescriptions aren't loaded yet but medicines exist, fallback to flat list.
    if (tiles.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _medicines.length,
        itemBuilder: (_, i) => _medicineRow(_medicines[i]),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: tiles,
    );
  }

  Widget _medicineRow(Medicine m) {
    final entry = _todayEntries[m.id];
    final taken = entry?.taken ?? false;
    final missed = entry != null && !entry.taken;
    final subtitle = missed
        ? 'Missed • ${m.dosage} • ${Medicine.medicineTimesLabel(m)}'
        : '${m.dosage} • ${Medicine.medicineTimesLabel(m)} • ${m.frequency.replaceAll('_', ' ')}';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          children: [
            ListTile(
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
              subtitle: Text(subtitle),
              // Use a compact trailing menu so text doesn't get squeezed on small screens.
              trailing: PopupMenuButton<String>(
                tooltip: 'Options',
                onSelected: (v) async {
                  if (v == 'edit') {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditMedicinePage(medicine: m),
                      ),
                    );
                    _load();
                  } else if (v == 'delete') {
                    await _deleteMedicine(m);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  if (!taken && !missed) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _markTaken(m),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Take'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _markMissed(m),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Missed'),
                      ),
                    ),
                  ] else
                    Expanded(
                      child: Text(
                        taken ? 'Taken today' : 'Missed today',
                        style: TextStyle(
                          color: taken ? Colors.green.shade700 : Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
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
                  child: ResponsiveCenter(child: _buildGroupedList()),
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
