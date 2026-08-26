import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrImportService {
  OcrImportService._();

  static Future<String> recognize(String imagePath) async {
    final recognizer = TextRecognizer(
      script: TextRecognitionScript.chinese,
    );
    try {
      final image = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(image);
      return result.text;
    } finally {
      await recognizer.close();
    }
  }
}
