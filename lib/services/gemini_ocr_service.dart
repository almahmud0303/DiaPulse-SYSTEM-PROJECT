import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiOcrService {
  GeminiOcrService({String? apiKey, String? model})
    : _apiKey = apiKey ?? const String.fromEnvironment('GEMINI_API_KEY'),
      _modelName =
          model ??
          const String.fromEnvironment(
            'GEMINI_MODEL',
            defaultValue: 'gemini-2.0-flash',
          );

  final String _apiKey;
  final String _modelName;

  static const List<String> _fallbackModels = [
    'gemini-2.0-flash',
    'gemini-1.5-flash-latest',
    'gemini-1.5-flash-8b',
    'gemini-1.5-flash',
  ];

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  Future<String> extractTextFromImage({
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    if (!isConfigured) {
      throw Exception(
        'Gemini API key is missing. Run with --dart-define=GEMINI_API_KEY=your_key',
      );
    }

    if (imageBytes.isEmpty) {
      throw Exception('Selected image is empty.');
    }

    final prompt = TextPart(
      'Extract all readable text from this image using OCR. '
      'Return plain text only. Preserve line breaks where meaningful. '
      'Do not add explanation or extra formatting.',
    );
    final imagePart = DataPart(mimeType, imageBytes);

    final tried = <String>{};
    final modelsToTry = <String>[_modelName, ..._fallbackModels];
    Exception? lastError;

    for (final modelName in modelsToTry) {
      if (!tried.add(modelName)) continue;
      final model = GenerativeModel(model: modelName, apiKey: _apiKey);
      try {
        final response = await model.generateContent([
          Content.multi([prompt, imagePart]),
        ]);

        final text = response.text?.trim() ?? '';
        if (text.isNotEmpty) {
          return text;
        }
        lastError = Exception('No text detected in the image.');
      } catch (e) {
        final msg = e.toString().toLowerCase();
        final isModelNotFound =
            msg.contains('not found') ||
            msg.contains('not supported') ||
            msg.contains('models/');
        if (!isModelNotFound) {
          rethrow;
        }
        lastError = Exception('Model "$modelName" is unavailable for this key/runtime.');
      }
    }

    throw lastError ??
        Exception(
          'Unable to run OCR. No compatible Gemini model was available.',
        );
  }
}
