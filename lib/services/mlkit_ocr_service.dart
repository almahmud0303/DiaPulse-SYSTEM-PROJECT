import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

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

  Future<void> close() async {
    if (_closed) return;
    await _recognizer.close();
    _closed = true;
  }
}
