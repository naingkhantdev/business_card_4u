import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../../data/vos/business_card_model.dart';

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
    final qrSize = compact ? 108.0 : 220.0;
    final outerPadding = compact ? 16.0 : 20.0;
    final titleSize = compact ? 16.0 : 20.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(outerPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1426) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2A44) : const Color(0xFFE6ECF5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? .20 : .05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: compact
          ? Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: AppColors.primary.withOpacity(.12),
                        ),
                        child: const Icon(
                          Icons.qr_code_2_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Share My QR',
                        style: AppTheme.withFontStack(TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFFEAF1FF)
                              : const Color(0xFF0B1220),
                        )),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasProfile
                            ? 'Show this to people nearby so they can add you fast.'
                            : 'Create your profile card first to generate your QR.',
                        style: AppTheme.withFontStack(TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color:
                              isDark ? const Color(0xFF98A7C2) : Colors.black54,
                        )),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _QrPreview(
                  isDark: isDark,
                  hasQr: hasQr,
                  qrData: qrData,
                  size: qrSize,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.primary.withOpacity(.12),
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'My QR Code',
                  textAlign: TextAlign.center,
                  style: AppTheme.withFontStack(TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                    color:
                        isDark ? const Color(0xFFEAF1FF) : const Color(0xFF0B1220),
                  )),
                ),
                const SizedBox(height: 8),
                Text(
                  hasProfile
                      ? 'Let others scan this code to add your card quickly.'
                      : 'Create your profile card first to generate your QR code.',
                  textAlign: TextAlign.center,
                  style: AppTheme.withFontStack(TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: isDark ? const Color(0xFF98A7C2) : Colors.black54,
                  )),
                ),
                const SizedBox(height: 20),
                _QrPreview(
                  isDark: isDark,
                  hasQr: hasQr,
                  qrData: qrData,
                  size: qrSize,
                ),
                if (hasQr) ...[
                  const SizedBox(height: 16),
                  SelectableText(
                    qrData,
                    textAlign: TextAlign.center,
                    style: AppTheme.withFontStack(TextStyle(
                      fontSize: 11.5,
                      color: isDark ? const Color(0xFF98A7C2) : Colors.black45,
                    )),
                  ),
                ],
              ],
            ),
    );
  }
}

class _QrPreview extends StatelessWidget {
  final bool isDark;
  final bool hasQr;
  final String qrData;
  final double size;

  const _QrPreview({
    required this.isDark,
    required this.hasQr,
    required this.qrData,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (hasQr) {
      return Container(
        padding: EdgeInsets.all(size * .07),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: QrImageView(
          data: qrData,
          version: QrVersions.auto,
          size: size,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Color(0xFF0B1220),
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Color(0xFF0B1220),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: isDark ? const Color(0xFF10182B) : const Color(0xFFF4F7FB),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2A44) : const Color(0xFFE1E8F2),
        ),
      ),
      child: Icon(
        Icons.qr_code_2_rounded,
        size: size * .4,
        color: isDark ? const Color(0xFF4A5D84) : const Color(0xFFB9C5D8),
      ),
    );
  }
}
