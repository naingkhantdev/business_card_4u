import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/vos/business_card_model.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../utils/save_to_gallery.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/glass.dart';
import '../theme/wallet_tokens.dart';
import 'app_toast.dart';

/// The share panel: a frosted pane over the page, and a QR set as a plate.
///
/// This is one of the few surfaces that genuinely floats above the list, so it
/// is one of the few that gets glass. The code itself stays on an opaque white
/// plate with square corners — a QR read through a translucent panel loses
/// contrast, and scanners are unforgiving about that.
class MyQrPanel extends StatelessWidget {
  final BusinessCardModel? profileCard;
  final bool compact;

  MyQrPanel({
    super.key,
    required this.profileCard,
    this.compact = false,
  });

  // Wraps the rendered QR plate so it can be captured as an image for the
  // "Save QR to Gallery" button below, without re-painting it separately.
  final GlobalKey _qrBoundaryKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qrData = profileCard?.qrCodeData?.trim() ?? '';
    final hasProfile = profileCard != null;
    final hasQr = qrData.isNotEmpty;
    // A 216pt plate plus its quiet zone needs more width than a narrow phone
    // has left after the sheet and panel padding, so the plate takes what the
    // panel can actually give it.
    final panelWidth = MediaQuery.of(context).size.width;
    final qrSize = compact
        ? 104.0
        : ((panelWidth - 2 * Wallet.margin - 2 * 24 - 28).clamp(140.0, 216.0));

    final eyebrow = Text(
      compact ? l10n.myQrPanelShareEyebrow : l10n.myQrPanelTitleEyebrow,
      style: AppTypography.eyebrow(
        color: Wallet.accentOf(isDark),
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
      ),
    );

    final title = Text(
      compact ? l10n.myQrPanelShareTitle : l10n.myQrPanelScanTitle,
      textAlign: compact ? TextAlign.start : TextAlign.center,
      style: AppTypography.primary(TextStyle(
        color: Wallet.inkOf(isDark),
        fontSize: compact ? 18 : 26,
        fontWeight: FontWeight.w700,
        height: 1.1,
      )),
    );

    final blurb = Text(
      hasProfile
          ? (compact ? l10n.myQrPanelCompactBlurb : l10n.myQrPanelFullBlurb)
          : l10n.myQrPanelNoProfileBlurb,
      textAlign: compact ? TextAlign.start : TextAlign.center,
      style: AppTypography.secondary(TextStyle(
        fontSize: 13,
        height: 1.5,
        color: Wallet.mutedOf(isDark),
      )),
    );

    return GlassPanel(
      padding: EdgeInsets.all(compact ? 18 : 24),
      child: compact
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      eyebrow,
                      const SizedBox(height: 10),
                      title,
                      const SizedBox(height: 8),
                      blurb,
                    ],
                  ),
                ),
                const SizedBox(width: Wallet.gutter),
                _QrPlate(
                  isDark: isDark,
                  hasQr: hasQr,
                  qrData: qrData,
                  size: qrSize,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: eyebrow),
                const SizedBox(height: 12),
                title,
                const SizedBox(height: 10),
                blurb,
                const SizedBox(height: 24),
                // A hairline above the plate: the Swiss way of saying "the
                // block below is a different kind of thing".
                Divider(height: 1, thickness: 1, color: Wallet.lineOf(isDark)),
                const SizedBox(height: 24),
                Center(
                  child: _QrPlate(
                    boundaryKey: _qrBoundaryKey,
                    isDark: isDark,
                    hasQr: hasQr,
                    qrData: qrData,
                    size: qrSize,
                  ),
                ),
                if (hasQr) ...[
                  const SizedBox(height: 16),
                  SelectableText(
                    qrData,
                    textAlign: TextAlign.center,
                    style: AppTypography.tertiary(TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: Wallet.faintOf(isDark),
                    )),
                  ),
                  const SizedBox(height: 14),
                  Center(child: _SaveQrButton(boundaryKey: _qrBoundaryKey)),
                ],
              ],
            ),
    );
  }
}

class _QrPlate extends StatelessWidget {
  final Key? boundaryKey;
  final bool isDark;
  final bool hasQr;
  final String qrData;
  final double size;

  const _QrPlate({
    this.boundaryKey,
    required this.isDark,
    required this.hasQr,
    required this.qrData,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (hasQr) {
      return RepaintBoundary(
        key: boundaryKey,
        child: Container(
          padding: EdgeInsets.all(size * .06),
          decoration: BoxDecoration(
            // Always white, in both themes. The quiet zone is part of the code.
            color: Colors.white,
            borderRadius: BorderRadius.circular(Wallet.radiusCard),
            border:
                Border.all(color: Wallet.lineOf(false), width: Wallet.hairline),
          ),
          child: QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: size,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Wallet.ink,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Wallet.ink,
            ),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Wallet.radiusCard),
        color: Wallet.tintOf(isDark),
        border: Border.all(color: Wallet.lineOf(isDark), width: Wallet.hairline),
      ),
      child: Icon(
        Icons.qr_code_2_rounded,
        size: size * .38,
        color: Wallet.faintOf(isDark),
      ),
    );
  }
}

/// Captures the QR plate at [boundaryKey] as a PNG and saves it to the
/// phone's gallery.
class _SaveQrButton extends StatefulWidget {
  final GlobalKey boundaryKey;

  const _SaveQrButton({required this.boundaryKey});

  @override
  State<_SaveQrButton> createState() => _SaveQrButtonState();
}

class _SaveQrButtonState extends State<_SaveQrButton> {
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final boundary = widget.boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      final image = await boundary?.toImage(pixelRatio: 3);
      final byteData = await image?.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();
      if (bytes == null) throw Exception('QR image not ready');

      if (!mounted) return;
      await saveImageBytesToGallery(
        context,
        bytes,
        fileName: 'my_qr_code_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (_) {
      if (mounted) {
        AppToast.show(
          context,
          AppLocalizations.of(context)!.myQrPanelSaveError,
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextButton.icon(
      onPressed: _saving ? null : _save,
      icon: _saving
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.download_rounded, size: 18, color: AppColors.primary),
      label: Text(
        _saving ? l10n.myQrPanelSaving : l10n.myQrPanelSaveToGallery,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
