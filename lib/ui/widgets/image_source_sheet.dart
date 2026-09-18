import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_typography.dart';
import '../theme/wallet_tokens.dart';

/// Asks where a photo should come from, returning null when the user dismisses
/// the sheet without choosing.
///
/// Camera first: for card photos it is nearly always what the user wants, and
/// it is the only source that exists before the photo is taken. Gallery still
/// has to be offered — cards are often photographed, received, or screenshotted
/// long before they get entered.
Future<ImageSource?> showImageSourceSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Wallet.surfaceOf(isDark),
    // A sheet is a plane sliding in from an edge, so only the leading corners
    // are eased — rounding all four would make it read as a floating card that
    // happens to be stuck to the bottom.
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(Wallet.radiusPanel),
      ),
    ),
    // Title, subtitle and two rows are taller than the default sheet cap in
    // landscape, so the sheet sizes itself and scrolls instead of clipping.
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 32,
                height: 3,
                color: Wallet.lineOf(isDark),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Wallet.margin),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTypography.primary(TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                      color: Wallet.inkOf(isDark),
                    )),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: AppTypography.secondary(TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: Wallet.mutedOf(isDark),
                      )),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Divider(
              height: Wallet.hairline,
              thickness: Wallet.hairline,
              color: Wallet.lineOf(isDark),
            ),
            _SourceRow(
              icon: Icons.photo_camera_outlined,
              label: 'Take a photo',
              // Named as the expected path so the choice is not two equal
              // options with nothing to separate them.
              hint: 'Recommended',
              isDark: isDark,
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            Divider(
              height: Wallet.hairline,
              thickness: Wallet.hairline,
              color: Wallet.lineOf(isDark),
            ),
            _SourceRow(
              icon: Icons.photo_library_outlined,
              label: 'Choose from gallery',
              isDark: isDark,
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

class _SourceRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  final bool isDark;
  final VoidCallback onTap;

  const _SourceRow({
    required this.icon,
    required this.label,
    this.hint,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Wallet.margin,
          vertical: 16,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Wallet.radiusTile),
                color: Wallet.tintOf(isDark),
              ),
              child: Icon(icon, size: 17, color: Wallet.accentOf(isDark)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTypography.secondary(TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Wallet.inkOf(isDark),
                )),
              ),
            ),
            if (hint != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Wallet.radiusTile),
                  border: Border.all(
                    color: Wallet.accentOf(isDark).withOpacity(.35),
                    width: Wallet.hairline,
                  ),
                ),
                child: Text(
                  hint!.toUpperCase(),
                  style: AppTypography.eyebrow(
                    color: Wallet.accentOf(isDark),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Wallet.faintOf(isDark),
              ),
          ],
        ),
      ),
    );
  }
}
