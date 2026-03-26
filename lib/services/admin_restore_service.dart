import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class BackupValidationResult {
  const BackupValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.detectedCollections,
    required this.totalDocuments,
  });

  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final List<String> detectedCollections;
  final int totalDocuments;
}

class BackupRestoreResult {
  const BackupRestoreResult({
    required this.dryRun,
    required this.processedDocuments,
    required this.writtenDocuments,
    required this.skippedDocuments,
    required this.failedDocuments,
    required this.collectionCounts,
    required this.failures,
  });

  final bool dryRun;
  final int processedDocuments;
  final int writtenDocuments;
  final int skippedDocuments;
  final int failedDocuments;
  final Map<String, int> collectionCounts;
  final List<String> failures;
}

class AdminRestoreService {
  AdminRestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const int _batchLimit = 400;
  static const List<String> defaultSkippedCollections = ['audit_logs'];

  BackupValidationResult validateBackupJson(String jsonText) {
    final errors = <String>[];
    final warnings = <String>[];
    final detectedCollections = <String>[];
    var totalDocuments = 0;

    dynamic decoded;
    try {
      decoded = jsonDecode(jsonText);
    } catch (e) {
      return BackupValidationResult(
        isValid: false,
        errors: ['Invalid JSON: $e'],
        warnings: const [],
        detectedCollections: const [],
        totalDocuments: 0,
      );
    }

    if (decoded is! Map) {
      return const BackupValidationResult(
        isValid: false,
        errors: ['Backup root must be a JSON object.'],
        warnings: [],
        detectedCollections: [],
        totalDocuments: 0,
      );
    }

    final root = Map<String, dynamic>.from(decoded);
    final collectionsNode = root['collections'];
    if (collectionsNode is! Map) {
      return const BackupValidationResult(
        isValid: false,
        errors: ['Missing `collections` object in backup JSON.'],
        warnings: [],
        detectedCollections: [],
        totalDocuments: 0,
      );
    }

    final collections = Map<String, dynamic>.from(collectionsNode);
    collections.forEach((name, value) {
      if (value is! List) {
        errors.add('Collection `$name` must be a list of documents.');
        return;
      }
      detectedCollections.add(name);
      totalDocuments += value.length;
      for (var i = 0; i < value.length; i++) {
        final row = value[i];
        if (row is! Map) {
          errors.add('Collection `$name` doc[$i] must be an object.');
          continue;
        }
        final docMap = Map<String, dynamic>.from(row);
        final id = docMap['id'];
        final data = docMap['data'];
        if (id is! String || id.trim().isEmpty) {
          errors.add('Collection `$name` doc[$i] has invalid `id`.');
        }
        if (data is! Map) {
          errors.add('Collection `$name` doc[$i] has invalid `data`.');
        }
      }
    });

    if (collections.containsKey('audit_logs')) {
      warnings.add(
        '`audit_logs` is included. Client-side import may fail due to strict write rules; skip unless rules are adjusted.',
      );
    }

    return BackupValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      detectedCollections: detectedCollections..sort(),
      totalDocuments: totalDocuments,
    );
  }

  Future<BackupRestoreResult> restoreFromJson({
    required String jsonText,
    required bool dryRun,
    required Set<String> selectedCollections,
  }) async {
    final validation = validateBackupJson(jsonText);
    if (!validation.isValid) {
      return BackupRestoreResult(
        dryRun: dryRun,
        processedDocuments: 0,
        writtenDocuments: 0,
        skippedDocuments: 0,
        failedDocuments: validation.errors.length,
        collectionCounts: const {},
        failures: validation.errors,
      );
    }

    final decoded = Map<String, dynamic>.from(jsonDecode(jsonText) as Map);
    final collections = Map<String, dynamic>.from(decoded['collections'] as Map);

    final failures = <String>[];
    final collectionCounts = <String, int>{};
    var processed = 0;
    var written = 0;
    var skipped = 0;
    var failed = 0;

    WriteBatch? batch = dryRun ? null : _firestore.batch();
    var batchOps = 0;

    for (final name in selectedCollections) {
      final list = collections[name];
      if (list is! List) {
        skipped++;
        failures.add('Collection `$name` is missing or not a list in backup.');
        continue;
      }
      var collectionProcessed = 0;

      for (var i = 0; i < list.length; i++) {
        final row = list[i];
        if (row is! Map) {
          failed++;
          failures.add('Collection `$name` doc[$i] invalid row type.');
          continue;
        }
        final docMap = Map<String, dynamic>.from(row);
        final id = docMap['id'];
        final dataNode = docMap['data'];
        if (id is! String || dataNode is! Map) {
          failed++;
          failures.add('Collection `$name` doc[$i] missing valid id/data.');
          continue;
        }

        processed++;
        collectionProcessed++;

        if (dryRun) {
          continue;
        }

        try {
          final payload = _decodeJsonSafe(Map<String, dynamic>.from(dataNode));
          batch!.set(_firestore.collection(name).doc(id), payload, SetOptions(merge: true));
          batchOps++;
          written++;
          if (batchOps >= _batchLimit) {
            await batch.commit();
            batch = _firestore.batch();
            batchOps = 0;
          }
        } catch (e) {
          failed++;
          failures.add('Collection `$name` doc `$id` failed: $e');
        }
      }
      collectionCounts[name] = collectionProcessed;
    }

    if (!dryRun && batchOps > 0) {
      try {
        await batch!.commit();
      } catch (e) {
        failed += batchOps;
        failures.add('Final batch commit failed: $e');
      }
    }

    return BackupRestoreResult(
      dryRun: dryRun,
      processedDocuments: processed,
      writtenDocuments: dryRun ? 0 : written,
      skippedDocuments: skipped,
      failedDocuments: failed,
      collectionCounts: collectionCounts,
      failures: failures,
    );
  }

  dynamic _decodeJsonSafe(dynamic value) {
    if (value == null || value is num || value is bool || value is String) {
      return value;
    }
    if (value is List) {
      return value.map(_decodeJsonSafe).toList();
    }
    if (value is Map) {
      final m = Map<String, dynamic>.from(value);
      final t = m['_type'];
      if (t == 'timestamp' && m['value'] is String) {
        final dt = DateTime.tryParse(m['value'] as String);
        if (dt != null) return Timestamp.fromDate(dt.toUtc());
      }
      if (t == 'geopoint') {
        final lat = m['latitude'];
        final lng = m['longitude'];
        if (lat is num && lng is num) {
          return GeoPoint(lat.toDouble(), lng.toDouble());
        }
      }
      if (t == 'document_reference' && m['path'] is String) {
        return _firestore.doc(m['path'] as String);
      }
      return m.map((k, v) => MapEntry(k, _decodeJsonSafe(v)));
    }
    return value.toString();
  }
}
