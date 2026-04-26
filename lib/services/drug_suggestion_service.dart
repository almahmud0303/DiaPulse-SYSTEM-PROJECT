import 'dart:convert';

import 'package:http/http.dart' as http;

class DrugSuggestionService {
  static const String _baseUrl = 'https://api.fda.gov/drug/label.json';

  Future<List<String>> suggestMedicineNames(String query) async {
    final q = query.trim();
    if (q.length < 2) {
      return const [];
    }

    final escaped = q.replaceAll('"', '');
    final uri = Uri.parse(
      '$_baseUrl?search=(openfda.brand_name:$escaped*+OR+openfda.generic_name:$escaped*)&limit=20',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return const [];
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return const [];
      final results = (decoded['results'] as List?) ?? const [];
      final names = <String>[];
      final seen = <String>{};
      final lowerQuery = q.toLowerCase();

      for (final row in results) {
        if (row is! Map<String, dynamic>) continue;
        final openfda = row['openfda'];
        if (openfda is! Map<String, dynamic>) continue;

        final brand = (openfda['brand_name'] as List?) ?? const [];
        final generic = (openfda['generic_name'] as List?) ?? const [];
        final combined = [...brand, ...generic];

        for (final name in combined) {
          if (name is! String) continue;
          final trimmed = name.trim();
          if (trimmed.isEmpty) continue;
          if (!trimmed.toLowerCase().contains(lowerQuery)) continue;
          final key = trimmed.toLowerCase();
          if (seen.add(key)) {
            names.add(trimmed);
          }
        }
      }

      names.sort((a, b) {
        final aLower = a.toLowerCase();
        final bLower = b.toLowerCase();
        final aStarts = aLower.startsWith(lowerQuery);
        final bStarts = bLower.startsWith(lowerQuery);
        if (aStarts != bStarts) return aStarts ? -1 : 1;
        return aLower.compareTo(bLower);
      });

      return names.take(12).toList();
    } catch (_) {
      // Network errors, timeouts, or malformed responses — return empty list
      // so the UI shows no suggestions rather than crashing.
      return const [];
    }
  }
}
