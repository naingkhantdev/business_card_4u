import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../data/vos/error_vo.dart';
import '../../data/vos/scanned_card_data.dart';
import '../../exception/custom_exception.dart';
import 'card_text_parser.dart';

/// Reads a photo of a business card and returns the fields it could recognise.
///
/// UI and providers depend on this abstraction, never on ML Kit, so scanning
/// can be faked in tests and swapped for another engine later.
abstract class CardScanner {
  /// Recognises text in the image at [imagePath].
  ///
  /// Returns [ScannedCardData.empty] when the image holds no readable text.
  /// Throws [CustomException] when the recogniser itself fails.
  Future<ScannedCardData> scan(String imagePath);

  void dispose();
}

/// On-device recognition through Google ML Kit, Latin script (English).
///
/// Latin covers English, which is the only script this feature promises; the
/// model ships with the app on Android and is downloaded on demand on iOS.
class MlKitCardScanner implements CardScanner {
  MlKitCardScanner({TextRecognizer? recognizer})
      : _recognizer =
            recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  @override
  Future<ScannedCardData> scan(String imagePath) async {
    try {
      final recognized =
          await _recognizer.processImage(InputImage.fromFilePath(imagePath));

      final lines = <OcrLine>[
        for (final block in recognized.blocks)
          for (final line in block.lines)
            OcrLine(line.text, line.boundingBox.height),
      ];

      if (lines.isEmpty) return ScannedCardData.empty;

      return CardTextParser.parse(lines);
    } catch (e) {
      throw CustomException(
        errorVo: ErrorVo(
          message: 'Could not read this photo. Try a sharper, closer shot.',
        ),
      );
    }
  }

  @override
  void dispose() => _recognizer.close();
}
