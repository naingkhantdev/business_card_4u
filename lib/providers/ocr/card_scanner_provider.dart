import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/ocr/card_scanner.dart';

/// Keeps a single recogniser alive for the app and closes it with the provider,
/// so the native ML Kit resources are released when nothing is scanning.
final cardScannerProvider = Provider<CardScanner>((ref) {
  final scanner = MlKitCardScanner();
  ref.onDispose(scanner.dispose);
  return scanner;
});
