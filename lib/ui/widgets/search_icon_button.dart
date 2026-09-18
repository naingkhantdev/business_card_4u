import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/wallet_tokens.dart';

/// A square icon button sized to sit beside a search field — 48px tall to
/// match the app's search box height. `filled` is for a primary action (the
/// search button itself); `active` tints it primary once a filter it
/// triggers is applied, without the full-strength fill `filled` gets.
///
/// Shared by the Cards and Search Users pages so a search bar's trailing
/// buttons look the same wherever one appears.
class SearchIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;
  final String tooltip;
  final IconData icon;
  final bool filled;
  final bool active;

  const SearchIconButton({
    super.key,
    required this.onTap,
    required this.isDark,
    required this.tooltip,
    required this.icon,
    this.filled = false,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = filled
        ? AppColors.primary
        : active
            ? AppColors.primary.withOpacity(.12)
            : (isDark ? Wallet.darkSurface : Colors.white);
    final borderColor = filled
        ? AppColors.primary
        : active
            ? AppColors.primary
            : (isDark ? Wallet.darkLine : Colors.grey.withOpacity(.12));
    final iconColor = filled
        ? Colors.white
        : active
            ? AppColors.primary
            : (isDark ? Wallet.darkMuted : Colors.grey.shade600);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: filled
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(.28),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ),
      ),
    );
  }
}
