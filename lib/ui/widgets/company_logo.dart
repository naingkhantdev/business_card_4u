import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../network/image_url.dart';
import '../theme/wallet_tokens.dart';

/// A company's logo in the same circle the person avatars use, falling back
/// to the name's first letter when there is no logo (or it fails to load).
class CompanyLogo extends StatelessWidget {
  final String name;

  /// Storage path or URL from the API.
  final String? logo;

  /// A just-picked file not yet uploaded; shown in place of [logo].
  final Uint8List? bytes;
  final double size;
  final bool isDark;

  const CompanyLogo({
    super.key,
    required this.name,
    required this.isDark,
    this.logo,
    this.bytes,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final url = ImageUrl.resolve(logo);
    final hasImage = bytes != null || url != null;
    final letter = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    Widget fallback() => Container(
          alignment: Alignment.center,
          color: isDark ? Wallet.accentDark.withOpacity(.16) : Wallet.accentSoft,
          child: Text(
            letter,
            style: TextStyle(
              fontSize: size * .42,
              fontWeight: FontWeight.w700,
              color: Wallet.accentOf(isDark),
            ),
          ),
        );

    // Fills the circle like the person avatars. Fitting it inside instead
    // left a square picture floating in the circle.
    Widget image() => bytes != null
        ? Image.memory(bytes!, fit: BoxFit.cover)
        : Image.network(
            url!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback(),
          );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Wallet.accentDark.withOpacity(.16) : Wallet.accentSoft,
      ),
      // Ring drawn over the content so the fill can't smudge it.
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Wallet.accentOf(isDark).withOpacity(.25),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage ? image() : fallback(),
    );
  }
}
