import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class PrescriptionOcrMedicine {
  const PrescriptionOcrMedicine({
    required this.name,
    required this.dosage,
    required this.timing,
    required this.sourceLine,
  });

  final String name;
  final String dosage;
  final String timing;
  final String sourceLine;

  bool get hasStructuredData =>
      name.isNotEmpty || dosage.isNotEmpty || timing.isNotEmpty;
}

class PrescriptionOcrResult {
  const PrescriptionOcrResult({required this.rawText, required this.medicines});

  final String rawText;
  final List<PrescriptionOcrMedicine> medicines;

  bool get hasMedicines => medicines.isNotEmpty;

  String get formattedText {
    final buffer = StringBuffer();
    if (medicines.isNotEmpty) {
      buffer.writeln('Extracted Prescription Details');
      for (var i = 0; i < medicines.length; i++) {
        final medicine = medicines[i];
        buffer.writeln('${i + 1}. Medicine: ${_valueOrDash(medicine.name)}');
        buffer.writeln('   Dosage: ${_valueOrDash(medicine.dosage)}');
        buffer.writeln('   Timing: ${_valueOrDash(medicine.timing)}');
      }
      buffer.writeln();
    }
    buffer.writeln('Raw OCR Text');
    buffer.write(rawText.trim());
    return buffer.toString().trim();
  }

  static String _valueOrDash(String value) =>
      value.trim().isEmpty ? '-' : value.trim();
}

class MlKitOcrService {
  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
  bool _closed = false;

  Future<String> extractTextFromFilePath(String imagePath) async {
    if (kIsWeb) {
      throw Exception('ML Kit OCR is not supported on Flutter web.');
    }
    if (_closed) {
      throw Exception('OCR service has been closed. Create a new instance.');
    }
    if (imagePath.trim().isEmpty) {
      throw Exception('Invalid image path.');
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    final recognized = await _recognizer.processImage(inputImage);
    final text = recognized.text.trim();
    if (text.isEmpty) {
      throw Exception('No text detected in the selected image.');
    }
    return text;
  }

  Future<PrescriptionOcrResult> extractPrescriptionFromFilePath(
    String imagePath,
  ) async {
    final text = await extractTextFromFilePath(imagePath);
    return parsePrescriptionText(text);
  }

  static PrescriptionOcrResult parsePrescriptionText(String rawText) {
    final cleanedText = rawText.trim();
    if (cleanedText.isEmpty) {
      return const PrescriptionOcrResult(rawText: '', medicines: []);
    }

    final medicines = <PrescriptionOcrMedicine>[];
    for (final line in _prescriptionLines(cleanedText)) {
      if (_shouldSkipLine(line)) continue;

      final parsed = _parsePrescriptionLine(line);
      if (parsed == null || !parsed.hasStructuredData) continue;

      final isTimingOnly =
          parsed.name.isEmpty &&
          parsed.dosage.isEmpty &&
          parsed.timing.isNotEmpty;
      if (isTimingOnly && medicines.isNotEmpty) {
        final previous = medicines.removeLast();
        medicines.add(
          PrescriptionOcrMedicine(
            name: previous.name,
            dosage: previous.dosage,
            timing: _joinParts([previous.timing, parsed.timing]),
            sourceLine: _joinParts([previous.sourceLine, parsed.sourceLine]),
          ),
        );
        continue;
      }

      if (parsed.name.isNotEmpty ||
          parsed.dosage.isNotEmpty ||
          parsed.timing.isNotEmpty) {
        medicines.add(parsed);
      }
    }

    return PrescriptionOcrResult(rawText: cleanedText, medicines: medicines);
  }

  static List<String> _prescriptionLines(String rawText) {
    return rawText
        .split(RegExp(r'\r?\n'))
        .map(_normalizeLine)
        .where((line) => line.length > 1)
        .toList();
  }

  static String _normalizeLine(String line) {
    return line
        .replaceAll(RegExp(r'[\t|]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _shouldSkipLine(String line) {
    final lower = line.toLowerCase();
    final hasMedicineSignal =
        _dosagePattern.hasMatch(line) ||
        _timingPattern.hasMatch(line) ||
        _schedulePattern.hasMatch(line);
    if (hasMedicineSignal) return false;

    return RegExp(
      r'\b(patient|age|sex|date|doctor|dr\.?|hospital|clinic|phone|mobile|address|diagnosis|advice|follow\s*up|signature|registration|reg\.?|rx)\b',
      caseSensitive: false,
    ).hasMatch(lower);
  }

  static PrescriptionOcrMedicine? _parsePrescriptionLine(String line) {
    final cleaned = _stripLeadingMarkers(line);
    if (cleaned.isEmpty) return null;

    final dosages = _matches(_dosagePattern, cleaned);
    final timings = <String>[
      ..._matches(_schedulePattern, cleaned),
      ..._matches(_timingPattern, cleaned),
      ..._matches(_durationPattern, cleaned),
    ];

    final hasSignal = dosages.isNotEmpty || timings.isNotEmpty;
    if (!hasSignal) return null;

    final name = _extractMedicineName(
      cleaned,
      firstSignalIndex: _firstSignalIndex(cleaned),
    );

    return PrescriptionOcrMedicine(
      name: name,
      dosage: _joinParts(dosages),
      timing: _joinParts(timings),
      sourceLine: cleaned,
    );
  }

  static String _stripLeadingMarkers(String line) {
    return line
        .replaceFirst(
          RegExp(r'^\s*(?:rx|r/x)\s*[:\-]?\s*', caseSensitive: false),
          '',
        )
        .replaceFirst(RegExp(r'^\s*[\d]+[\).\-:]?\s*'), '')
        .replaceFirst(RegExp('^\\s*[-*\\u2022]+\\s*'), '')
        .trim();
  }

  static String _extractMedicineName(
    String line, {
    required int? firstSignalIndex,
  }) {
    var source = firstSignalIndex != null && firstSignalIndex > 0
        ? line.substring(0, firstSignalIndex)
        : line;

    for (final pattern in [
      _dosagePattern,
      _schedulePattern,
      _timingPattern,
      _durationPattern,
    ]) {
      source = source.replaceAll(pattern, ' ');
    }

    source = source
        .replaceFirst(
          RegExp(
            r'^\s*(?:tab|tablet|cap|capsule|syp|syrup|inj|injection|drop|drops|cream|oint|ointment|soln|solution)\.?\s+',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(r'\b(?:po|oral|after|before|with)\b', caseSensitive: false),
          ' ',
        )
        .replaceAll(RegExp(r'[:;,\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (source.length < 2) return '';
    return source;
  }

  static int? _firstSignalIndex(String line) {
    final indexes = <int>[];
    for (final pattern in [
      _dosagePattern,
      _schedulePattern,
      _timingPattern,
      _durationPattern,
    ]) {
      final match = pattern.firstMatch(line);
      if (match != null) indexes.add(match.start);
    }
    if (indexes.isEmpty) return null;
    indexes.sort();
    return indexes.first;
  }

  static List<String> _matches(RegExp pattern, String input) {
    final values = <String>[];
    for (final match in pattern.allMatches(input)) {
      final value = match.group(0)?.trim();
      if (value == null || value.isEmpty) continue;
      if (values.any(
        (existing) => existing.toLowerCase() == value.toLowerCase(),
      )) {
        continue;
      }
      values.add(value);
    }
    return values;
  }

  static String _joinParts(List<String> parts) {
    final cleaned = <String>[];
    for (final part in parts) {
      final value = part.trim();
      if (value.isEmpty) continue;
      if (cleaned.any(
        (existing) => existing.toLowerCase() == value.toLowerCase(),
      )) {
        continue;
      }
      cleaned.add(value);
    }
    return cleaned.join(', ');
  }

  Future<void> close() async {
    if (_closed) return;
    await _recognizer.close();
    _closed = true;
  }

  static final RegExp _dosagePattern = RegExp(
    r'\b(?:\d+(?:[.,]\d+)?\s*(?:mg|mcg|ug|g|gm|gram|grams|ml|iu|units?|tablet|tablets|tab|tabs|capsule|capsules|cap|caps|drop|drops|puff|puffs|spoon|teaspoon|tsp|sachet|vial|ampoule|amp|injection|inj|dose|doses)|(?:half|one|two|three|four)\s*(?:tablet|tablets|tab|tabs|capsule|capsules|cap|caps|spoon|drop|drops|puff|puffs))\b',
    caseSensitive: false,
  );

  static final RegExp _schedulePattern = RegExp(
    r'\b\d\s*[+\-]\s*\d\s*[+\-]\s*\d(?:\s*[+\-]\s*\d)?\b',
    caseSensitive: false,
  );

  static final RegExp _timingPattern = RegExp(
    r'\b(?:od|bd|bid|tds|tid|qid|qhs|hs|sos|prn|daily|once daily|twice daily|three times daily|four times daily|morning|noon|afternoon|evening|night|before meal|before meals|after meal|after meals|before food|after food|empty stomach|with food|with meal|with meals|before breakfast|after breakfast|before lunch|after lunch|before dinner|after dinner|at bedtime|bedtime|every\s+\d+\s*hours?|q\s*\d+\s*h)\b',
    caseSensitive: false,
  );

  static final RegExp _durationPattern = RegExp(
    r'\b(?:for|x)\s*\d+\s*(?:day|days|week|weeks|month|months)\b',
    caseSensitive: false,
  );
}
