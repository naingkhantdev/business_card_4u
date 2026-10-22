import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

import '../l10n/generated/app_localizations.dart';
import '../ui/widgets/app_toast.dart';

/// Saves [bytes] to the phone's photo gallery, requesting access first if it
/// hasn't been granted yet. Shows a toast on success or failure.
///
/// [fileName] must not include a file extension — `Gal.putImageBytes` adds
/// one itself based on the image format.
Future<bool> saveImageBytesToGallery(
  BuildContext context,
  Uint8List bytes, {
  required String fileName,
}) async {
  try {
    if (!await Gal.hasAccess()) {
      final granted = await Gal.requestAccess();
      if (!granted) {
        if (context.mounted) {
          AppToast.show(
            context,
            AppLocalizations.of(context)!.saveToGalleryAccessDenied,
            type: AppToastType.error,
          );
        }
        return false;
      }
    }

    await Gal.putImageBytes(bytes, name: fileName, album: 'businessCard4U');

    if (context.mounted) {
      AppToast.show(
        context,
        AppLocalizations.of(context)!.saveToGallerySuccess,
        type: AppToastType.success,
      );
    }
    return true;
  } catch (_) {
    if (context.mounted) {
      AppToast.show(
        context,
        AppLocalizations.of(context)!.saveToGalleryError,
        type: AppToastType.error,
      );
    }
    return false;
  }
}
