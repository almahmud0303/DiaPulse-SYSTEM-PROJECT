import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminBackupService {
  AdminBackupService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const List<String> defaultCollections = <String>[
    'users',
    'glucose_readings',
    'prescriptions',
    'medicines',
    'medicine_entries',
    'meals',
    'activities',
    'appointments',
    'consultation_notes',
    'conversations',
    'messages',
    'notifications',
    'audit_logs',
  ];

  String buildDefaultFilename() {
    final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return 'dia_plus_backup_$ts.json';
  }

  Future<Map<String, dynamic>> generateBackup({
    required List<String> collections,
  }) async {
    final selected =
        collections.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final data = <String, dynamic>{};
    var totalDocs = 0;

    for (final c in selected) {
      final snap = await _firestore.collection(c).get();
      final docs = <Map<String, dynamic>>[];
      for (final d in snap.docs) {
        docs.add({
          'id': d.id,
          'data': _jsonSafe(d.data()),
        });
      }
      data[c] = docs;
      totalDocs += docs.length;
    }

    return {
      'meta': {
        'schemaVersion': 1,
        'generatedAt': DateTime.now().toUtc().toIso8601String(),
        'collections': selected,
        'collectionCount': selected.length,
        'totalDocuments': totalDocs,
      },
      'collections': data,
    };
  }

  String toPrettyJson(Map<String, dynamic> backup) {
    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  dynamic _jsonSafe(dynamic value) {
    if (value == null || value is num || value is bool || value is String) {
      return value;
    }
    if (value is Timestamp) {
      return {
        '_type': 'timestamp',
        'value': value.toDate().toUtc().toIso8601String(),
      };
    }
    if (value is GeoPoint) {
      return {
        '_type': 'geopoint',
        'latitude': value.latitude,
        'longitude': value.longitude,
      };
    }
    if (value is DocumentReference) {
      return {
        '_type': 'document_reference',
        'path': value.path,
      };
    }
    if (value is List) {
      return value.map(_jsonSafe).toList();
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry('$k', _jsonSafe(v)));
    }
    return {
      '_type': 'unknown',
      'value': value.toString(),
    };
  }
}
