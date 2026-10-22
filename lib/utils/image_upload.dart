import 'package:image_picker/image_picker.dart';

/// What a picked photo is for, which decides how far it is scaled down
/// before it is uploaded.
enum UploadImageKind {
  /// Front or back of a printed card. OCR reads it, so it keeps enough
  /// detail for small print.
  card(1600, 85),

  /// A portrait. Shown at most a couple of hundred pixels across.
  avatar(800, 80);

  /// Longest side, in pixels. Aspect ratio is kept.
  final double maxSide;

  /// JPEG quality, 0–100.
  final int quality;

  const UploadImageKind(this.maxSide, this.quality);
}

/// [ImagePicker.pickImage], scaled and re-encoded on the device.
///
/// A phone photo arrives at around 4000px and 3–8 MB — slow on mobile data
/// and often over the API's 5 MB limit (BusinessCardController, `max:5120`).
/// At these sizes it is typically a few hundred KB. Throws whatever
/// pickImage throws, so callers keep their existing error handling.
Future<XFile?> pickImageForUpload(ImageSource source, UploadImageKind kind) {
  return ImagePicker().pickImage(
    source: source,
    maxWidth: kind.maxSide,
    maxHeight: kind.maxSide,
    imageQuality: kind.quality,
  );
}
