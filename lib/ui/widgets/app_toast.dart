import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum AppToastType {
  info,
  success,
  warning,
  error,
  destructiveSoft,
}

class AppToast {
  static void show(
    BuildContext context,
    String message, {
    AppToastType type = AppToastType.info,
    Duration? duration,
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final style = _ToastStyle.fromType(type);
    final effectiveDuration = duration ?? _defaultDurationForType(type);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: GestureDetector(
              onTap: () {
                if (entry.mounted) entry.remove();
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: style.backgroundColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: style.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTheme.withFontStack(TextStyle(
                      color: style.textColor,
                      fontWeight: FontWeight.w800,
                    )),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    Future.delayed(effectiveDuration).then((_) {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  static Duration _defaultDurationForType(AppToastType type) {
    switch (type) {
      case AppToastType.error:
      case AppToastType.warning:
        return const Duration(seconds: 4);
      case AppToastType.destructiveSoft:
        return const Duration(seconds: 3);
      case AppToastType.success:
      case AppToastType.info:
      default:
        return const Duration(seconds: 2);
    }
  }
}

class _ToastStyle {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _ToastStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  factory _ToastStyle.fromType(AppToastType type) {
    switch (type) {
      case AppToastType.success:
      case AppToastType.info:
        return const _ToastStyle(
          backgroundColor: AppColors.successBg,
          borderColor: AppColors.successBorder,
          textColor: AppColors.successText,
        );
      case AppToastType.warning:
        return const _ToastStyle(
          backgroundColor: AppColors.warningBg,
          borderColor: AppColors.warningBorder,
          textColor: AppColors.warningText,
        );
      case AppToastType.destructiveSoft:
        return const _ToastStyle(
          backgroundColor: AppColors.errorBgSoft,
          borderColor: AppColors.errorBorderSoft,
          textColor: AppColors.errorTextSoft,
        );
      case AppToastType.error:
        return const _ToastStyle(
          backgroundColor: AppColors.errorBg,
          borderColor: AppColors.errorBorder,
          textColor: AppColors.errorText,
        );
    }
  }
}
