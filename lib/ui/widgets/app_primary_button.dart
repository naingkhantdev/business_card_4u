import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'loading_view.dart';

class AppPrimaryButton extends StatelessWidget {
  final String text;
  final bool loading;
  final VoidCallback? onPressed;
  final double height;
  final BorderRadius? borderRadius;
  final double fontSize;

  const AppPrimaryButton({
    super.key,
    required this.text,
    required this.loading,
    required this.onPressed,
    this.height = 52,
    this.borderRadius,
    this.fontSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(14);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: loading
                  ? [
                      AppColors.secondary.withOpacity(.55),
                      AppColors.primary.withOpacity(.55),
                    ]
                  : const [
                      AppColors.secondary,
                      AppColors.primary,
                    ],
            ),
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(.25),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? const LoadingView(size: 22)
                : Text(
                    text,
                    style: AppTheme.withFontStack(TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: fontSize,
                    )),
                  ),
          ),
        ),
      ),
    );
  }
}
