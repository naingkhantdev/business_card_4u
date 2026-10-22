import 'package:flutter/material.dart';
import '../theme/app_page_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth/auth_provider.dart';
import '../responsive/auth_web_card.dart';
import '../responsive/responsive.dart';
import '../theme/app_typography.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_toast.dart';
import 'otp_page.dart';
import '../theme/wallet_tokens.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  static const _text = Wallet.ink;
  static const _muted = Wallet.muted;

  final _emailController = TextEditingController();

  void _toast(String message, {bool isError = false}) {
    if (!mounted) return;
    AppToast.show(
      context,
      message,
      type: isError ? AppToastType.error : AppToastType.success,
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();

    final result = await ref.read(authProvider.notifier).sendOtp(email);

    if (!mounted) return;

    if (result.message != null && result.message!.trim().isNotEmpty) {
      _toast(result.message!, isError: !result.success);
    }

    if (result.success) {
      Navigator.push(
        context,
        AppPageRoute(builder: (_) => OtpPage(email: email)),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider).when(
          data: (state) => state,
          loading: () => AuthState(isLoading: true),
          error: (error, stackTrace) => AuthState(),
        );

    final l10n = AppLocalizations.of(context)!;

    if (Responsive.isDesktop(context)) {
      return AuthWebCard(
        tagline: l10n.registerPageTagline,
        form: _buildFormFields(authState),
      );
    }

    // Deliberately minimal: one plain surface, a small wordmark, the title,
    // one field and one button. No hero, cards or shadows — there's only one
    // thing to do on this page, so nothing else competes with it. Follows
    // the system theme through Wallet's light/dark tokens.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = Wallet.inkOf(isDark);
    final muted = Wallet.mutedOf(isDark);
    final canGoBack = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: Wallet.surfaceOf(isDark),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top bar: just the way back.
                      SizedBox(
                        height: 48,
                        child: canGoBack
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: _BackButton(
                                  isDark: isDark,
                                  onTap: authState.isLoading
                                      ? null
                                      : () => Navigator.pop(context),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 28),

                      // The brand is the centrepiece: logo and a large
                      // wordmark, with the page's title and explanation in
                      // a supporting size underneath.
                      Center(
                        child: Image.asset(
                          'assets/images/ABW.png',
                          width: 72,
                          height: 72,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            text: 'businessCard',
                            style: AppTypography.primary(
                              TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                                height: 1.1,
                                color: ink,
                              ),
                            ),
                            children: [
                              TextSpan(
                                text: '4U',
                                style: TextStyle(
                                    color: Wallet.accentOf(isDark)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Center(
                        child: Text(
                          l10n.registerPageTitle,
                          textAlign: TextAlign.center,
                          style: AppTypography.primary(
                            TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              color: ink,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          l10n.registerPageSubtitle,
                          textAlign: TextAlign.center,
                          style: AppTypography.secondary(
                            TextStyle(
                                fontSize: 14, height: 1.45, color: muted),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _emailField(authState, isDark),
                      const SizedBox(height: 16),
                      AppPrimaryButton(
                        text: l10n.registerPageSendCode,
                        loading: authState.isLoading,
                        onPressed: authState.isLoading ? null : _submit,
                        height: 52,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          l10n.registerPageCodeExpiry,
                          style: AppTypography.tertiary(
                            TextStyle(fontSize: 12.5, color: muted),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (canGoBack)
                        Center(
                          child: TextButton(
                            onPressed: authState.isLoading
                                ? null
                                : () => Navigator.pop(context),
                            child: Text(l10n.registerPageHaveAccount),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A plain hairline field — no fill or shadow, accent border on focus.
  Widget _emailField(AuthState authState, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    OutlineInputBorder outline(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(Wallet.radiusControl),
          borderSide: BorderSide(color: color, width: width),
        );

    return TextField(
      controller: _emailController,
      enabled: !authState.isLoading,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.email],
      onSubmitted: (_) => authState.isLoading ? null : _submit(),
      style: AppTypography.secondary(
        TextStyle(color: Wallet.inkOf(isDark), fontSize: 15),
      ),
      decoration: InputDecoration(
        hintText: l10n.registerPageEmailLabel,
        hintStyle: AppTypography.secondary(
          TextStyle(color: Wallet.faintOf(isDark), fontSize: 15),
        ),
        prefixIcon: Icon(Icons.email_outlined,
            size: 20, color: Wallet.mutedOf(isDark)),
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: outline(Wallet.lineOf(isDark), 1),
        enabledBorder: outline(Wallet.lineOf(isDark), 1),
        disabledBorder: outline(Wallet.lineOf(isDark), 1),
        focusedBorder: outline(Wallet.accentOf(isDark), 1.5),
      ),
    );
  }

  Widget _buildFormFields(AuthState authState) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (Navigator.canPop(context)) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed:
                  authState.isLoading ? null : () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: _muted,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(MaterialLocalizations.of(context).backButtonTooltip),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          l10n.registerPageTitle,
          style: const TextStyle(
            color: _text,
            fontWeight: FontWeight.w600,
            fontSize: 28,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.registerPageSubtitle,
          style: const TextStyle(color: _muted, fontSize: 14, height: 1.45),
        ),
        const SizedBox(height: 22),
        NeumorphicField(
          controller: _emailController,
          label: l10n.registerPageEmailLabel,
          icon: Icons.alternate_email_rounded,
          enabled: !authState.isLoading,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => authState.isLoading ? null : _submit(),
        ),
        const SizedBox(height: 16),
        NeumorphicButton(
          text: l10n.registerPageSendCode,
          loading: authState.isLoading,
          onPressed: authState.isLoading ? null : _submit,
        ),
        const SizedBox(height: 10),
        Text(
          l10n.registerPageCodeExpiry,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
      ],
    );
  }
}

/// "← Back" as a plain accent-coloured link: says what it does, carries no
/// background or frame, and starts flush with the page's left edge.
class _BackButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onTap;

  const _BackButton({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = Wallet.accentOf(isDark);
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: accent,
        // Only a little padding on the left, so the arrow lines up with the
        // text below while the ripple still has room.
        padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
        minimumSize: const Size(0, 40),
        tapTargetSize: MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Wallet.radiusTile)),
      ),
      icon: const Icon(Icons.arrow_back_rounded, size: 18),
      label: Text(
        MaterialLocalizations.of(context).backButtonTooltip,
        style: AppTypography.primary(
          const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
