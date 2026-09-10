import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../utils/business_card_parser.dart';

/// Runs on-device text recognition over photos of a business card and hands
/// back the parsed fields.
///
/// ML Kit holds native resources, so a recognizer is created per scan and
/// closed straight after. Scans are short and infrequent enough here that the
/// setup cost is not worth keeping one alive across the app's lifetime.
class CardOcrService {
  const CardOcrService();

  /// Recognizes [front] and, when given, [back], then parses both into one
  /// result. Returns an empty [ParsedCardData] when no text was found — the
  /// caller decides how to tell the user.
  Future<ParsedCardData> scan({required XFile front, XFile? back}) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final frontLines = await _readLines(recognizer, front);
      final backLines = back == null ? <String>[] : await _readLines(recognizer, back);
      return BusinessCardParser.parse(frontLines, backLines: backLines);
    } finally {
      await recognizer.close();
    }
  }

  Future<List<String>> _readLines(TextRecognizer recognizer, XFile file) async {
    final recognized =
        await recognizer.processImage(InputImage.fromFilePath(file.path));

    // Blocks come back in reading order, and lines within a block follow the
    // card's own layout — which is what the parser's "name comes first"
    // heuristics rely on, so the order is preserved as-is.
    return [
      for (final block in recognized.blocks)
        for (final line in block.lines) line.text,
    ];
  }
}
