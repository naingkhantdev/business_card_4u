import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/app_typography.dart';
import '../theme/glass.dart';
import '../theme/wallet_tokens.dart';
import '../../data/vos/business_card_model.dart';

/// The share panel: a frosted pane over the page, and a QR set as a plate.
///
/// This is one of the few surfaces that genuinely floats above the list, so it
/// is one of the few that gets glass. The code itself stays on an opaque white
/// plate with square corners — a QR read through a translucent panel loses
/// contrast, and scanners are unforgiving about that.
class MyQrPanel extends StatelessWidget {
  final BusinessCardModel? profileCard;
  final bool compact;

  const MyQrPanel({
    super.key,
    required this.profileCard,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qrData = profileCard?.qrCodeData?.trim() ?? '';
    final hasProfile = profileCard != null;
    final hasQr = qrData.isNotEmpty;
    final qrSize = compact ? 104.0 : 216.0;

    final eyebrow = Text(
      compact ? 'SHARE' : 'MY QR CODE',
      style: AppTypography.eyebrow(
        color: Wallet.accentOf(isDark),
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
      ),
    );

    final title = Text(
      compact ? 'Share my QR' : 'Scan to add me',
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
          ? (compact
              ? 'Show this to people nearby so they can add you fast.'
              : 'Let others scan this code to add your card instantly.')
          : 'Create your profile card first to generate your QR.',
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
                ],
              ],
            ),
    );
  }
}

class _QrPlate extends StatelessWidget {
  final bool isDark;
  final bool hasQr;
  final String qrData;
  final double size;

  const _QrPlate({
    required this.isDark,
    required this.hasQr,
    required this.qrData,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (hasQr) {
      return Container(
        padding: EdgeInsets.all(size * .06),
        decoration: BoxDecoration(
          // Always white, in both themes. The quiet zone is part of the code.
          color: Colors.white,
          borderRadius: BorderRadius.circular(Wallet.radiusCard),
          border: Border.all(color: Wallet.lineOf(false), width: Wallet.hairline),
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
