import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/app_page_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth/auth_provider.dart';
import '../../utils/app_result.dart';
import '../responsive/auth_web_card.dart';
import '../responsive/responsive.dart';
import '../theme/app_colors.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_toast.dart';
import '../widgets/loading_view.dart';
import 'complete_register_page.dart';
import '../theme/wallet_tokens.dart';

class OtpPage extends ConsumerStatefulWidget {
  final String email;
  const OtpPage({super.key, required this.email});

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  static const int _initialSeconds = 300;

  final _otpController = TextEditingController();
  final _otpFocus = FocusNode();

  int _secondsRemaining = _initialSeconds;
  Timer? _timer;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _formattedTime {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  void _showMessage(String message, {bool isError = false}) {
    AppToast.show(
      context,
      message,
      type: isError ? AppToastType.error : AppToastType.success,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    // The pin field auto-submits on the 6th digit and the button can fire
    // too; a second request would hit after the OTP is consumed server-side
    // and come back as "Invalid OTP".
    if (_isVerifying) return;

    final otp = _otpController.text.trim();
    final l10n = AppLocalizations.of(context)!;

    if (otp.length != 6) {
      _showMessage(l10n.otpPageEnterSixDigits, isError: true);
      return;
    }

    _isVerifying = true;
    final AppResult result;
    try {
      result = await ref
          .read(authProvider.notifier)
          .verifyOtpOnly(widget.email, otp);
    } finally {
      _isVerifying = false;
    }

    if (!mounted) return;
    final message = result.message ??
        (result.success ? l10n.otpPageVerifiedMessage : l10n.otpPageGenericError);
    _showMessage(message, isError: !result.success);

    if (result.success) {
      Future.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          AppPageRoute(
            builder: (_) => CompleteRegisterPage(email: widget.email),
          ),
        );
      });
    }
  }

  Future<void> _resendOtp() async {
    if (_secondsRemaining != 0) return;

    final result = await ref.read(authProvider.notifier).sendOtp(widget.email);

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    _showMessage(
      result.message ??
          (result.success ? l10n.otpPageResentMessage : l10n.otpPageResendFailed),
      isError: !result.success,
    );

    if (result.success) {
      setState(() => _secondsRemaining = _initialSeconds);
      _startTimer();
    }
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
        tagline: l10n.otpPageTagline,
        form: _buildFormFields(authState, l10n),
      );
    }

    // None of the "glass" widgets below used to take the system theme into
    // account at all — every one of them was hardcoded to a white/light
    // aesthetic, so this page looked identical (and wrong) in dark mode.
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Wallet.groundOf(isDark),
      body: Stack(
        children: [
          _PremiumBackground(isDark: isDark),

          SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // Top bar (back)
                    Row(
                      children: [
                        _CircleIconButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.pop(context),
                          isDark: isDark,
                        ),
                        const Spacer(),
                        _TimerPill(
                          timeText: _formattedTime,
                          isExpired: _secondsRemaining == 0,
                          isDark: isDark,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    Text(
                      l10n.otpPageTitle,
                      style: TextStyle(
                        fontSize: 30,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                        color: Wallet.inkOf(isDark),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      l10n.otpPageSentCodeTo,
                      style: TextStyle(
                        fontSize: 14,
                        color: Wallet.mutedOf(isDark),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      widget.email,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Wallet.inkOf(isDark),
                      ),
                    ),

                    const SizedBox(height: 26),

                    _GlassCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 4),

                          // No "Enter OTP" label: the heading above already
                          // says it, and six empty boxes need no caption.
                          _OtpPinField(
                            controller: _otpController,
                            focusNode: _otpFocus,
                            enabled: !authState.isLoading,
                            onCompleted: (_) => _verifyOtp(),
                            isDark: isDark,
                          ),

                          const SizedBox(height: 22),

                          // Verify button
                          AppPrimaryButton(
                            text: l10n.otpPageTitle,
                            loading: authState.isLoading,
                            onPressed: authState.isLoading ? null : _verifyOtp,
                            height: 54,
                            borderRadius: BorderRadius.circular(18),
                            fontSize: 15.5,
                          ),

                          const SizedBox(height: 12),

                          // Resend
                          Center(
                            child: TextButton(
                              onPressed: (_secondsRemaining == 0 &&
                                      !authState.isLoading)
                                  ? _resendOtp
                                  : null,
                              child: Text(
                                _secondsRemaining == 0
                                    ? l10n.otpPageResendNow
                                    : l10n.otpPageResendAfter(_formattedTime),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: (_secondsRemaining == 0 &&
                                          !authState.isLoading)
                                      ? Wallet.accentOf(isDark)
                                      : Wallet.faintOf(isDark),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Tip footer
                    Row(
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            size: 18, color: Wallet.faintOf(isDark)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.otpPageFooterTip,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                              color: Wallet.mutedOf(isDark),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading overlay premium
          if (authState.isLoading) _LoadingGlassOverlay(isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildFormFields(AuthState authState, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(l10n.otpPageChangeEmail),
            ),
            const Spacer(),
            _TimerPill(
              timeText: _formattedTime,
              isExpired: _secondsRemaining == 0,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          l10n.otpPageTitle,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: Wallet.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.otpPageSentCodeTo,
          style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(.55)),
        ),
        const SizedBox(height: 4),
        Text(
          widget.email,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Wallet.ink,
          ),
        ),
        const SizedBox(height: 26),
        _OtpPinField(
          controller: _otpController,
          focusNode: _otpFocus,
          enabled: !authState.isLoading,
          onCompleted: (_) => _verifyOtp(),
        ),
        const SizedBox(height: 22),
        NeumorphicButton(
          text: l10n.otpPageTitle,
          loading: authState.isLoading,
          onPressed: authState.isLoading ? null : _verifyOtp,
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: (_secondsRemaining == 0 && !authState.isLoading)
                ? _resendOtp
                : null,
            child: Text(
              _secondsRemaining == 0
                  ? l10n.otpPageResendNow
                  : l10n.otpPageResendAfter(_formattedTime),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: (_secondsRemaining == 0 && !authState.isLoading)
                    ? const Color(0xFF1E3C72)
                    : Colors.black.withOpacity(.35),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 18, color: Colors.black.withOpacity(.45)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.otpPageFooterTip,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: Colors.black.withOpacity(.50),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/* ===================== Premium UI Widgets ===================== */

class _PremiumBackground extends StatelessWidget {
  final bool isDark;
  const _PremiumBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base
        Container(color: Wallet.groundOf(isDark)),

        // Gradient blobs. The third one was a plain white glow — fine
        // floating over a light ground, a stray bright patch over a dark
        // one — so dark mode gets a second accent-tinted blob instead.
        Positioned(
          top: -120,
          left: -60,
          child: _BlurBlob(
            size: 260,
            color: AppColors.secondary.withOpacity(isDark ? .16 : .22),
          ),
        ),
        Positioned(
          bottom: -140,
          right: -80,
          child: _BlurBlob(
            size: 320,
            color: isDark
                ? Wallet.accentDark.withOpacity(.14)
                : AppColors.secondaryLight.withOpacity(.18),
          ),
        ),
        Positioned(
          top: 220,
          right: -40,
          child: _BlurBlob(
            size: 180,
            color: isDark
                ? Wallet.accentDark.withOpacity(.10)
                : Colors.white.withOpacity(.35),
          ),
        ),
      ],
    );
  }
}

class _BlurBlob extends StatelessWidget {
  final double size;
  final Color color;
  const _BlurBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _GlassCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: (isDark ? Wallet.darkSurface : Colors.white)
                .withOpacity(.75),
            // A faint white rim reads as a glass highlight in both modes —
            // just far fainter in dark, where a bright rim would look like a
            // stray outline rather than a highlight.
            border: Border.all(color: Colors.white.withOpacity(isDark ? .10 : .55)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? .28 : .08),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: (isDark ? Wallet.darkSurface : Colors.white).withOpacity(.75),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(isDark ? .10 : .6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? .3 : .06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(icon, color: Wallet.inkOf(isDark)),
      ),
    );
  }
}

class _TimerPill extends StatelessWidget {
  final String timeText;
  final bool isExpired;
  final bool isDark;
  const _TimerPill({
    required this.timeText,
    required this.isExpired,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: (isDark ? Wallet.darkSurface : Colors.white).withOpacity(.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(isDark ? .10 : .6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 18,
            color: isExpired ? AppColors.errorBg : AppColors.secondary,
          ),
          const SizedBox(width: 8),
          Text(
            timeText,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isExpired ? AppColors.errorBg : AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingGlassOverlay extends StatelessWidget {
  final bool isDark;
  const _LoadingGlassOverlay({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          color: Colors.black.withOpacity(isDark ? .35 : .08),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: (isDark ? Wallet.darkSurface : Colors.white)
                    .withOpacity(.88),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? .35 : .12),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LoadingView(size: 22),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.otpPageLoadingWait,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Wallet.inkOf(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium OTP input: 6 boxes but backed by single hidden TextField.
/// No extra package needed.
class _OtpPinField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String>? onCompleted;
  final bool isDark;

  const _OtpPinField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    this.onCompleted,
    this.isDark = false,
  });

  @override
  State<_OtpPinField> createState() => _OtpPinFieldState();
}

class _OtpPinFieldState extends State<_OtpPinField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  void _onChanged() {
    final text = widget.controller.text;
    if (text.length == 6) widget.onCompleted?.call(text);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.text;

    return GestureDetector(
      onTap: widget.enabled
          ? () => FocusScope.of(context).requestFocus(widget.focusNode)
          : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hidden real input
          Opacity(
            opacity: 0.0,
            child: SizedBox(
              height: 1,
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                decoration: const InputDecoration(
                    counterText: "", border: InputBorder.none),
              ),
            ),
          ),

          // Six fixed 46pt boxes need 276pt of width, which a narrow phone
          // does not have once the page and card padding are taken out. The
          // boxes divide what is actually there instead.
          LayoutBuilder(builder: (context, constraints) {
            const gap = 8.0;
            final boxWidth =
                ((constraints.maxWidth - gap * 5) / 6).clamp(32.0, 46.0);
            final boxHeight = (boxWidth * 54 / 46).clamp(40.0, 54.0);

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) {
                final char = i < value.length ? value[i] : '';
                final isActive =
                    widget.focusNode.hasFocus && i == value.length.clamp(0, 5);

                final isDark = widget.isDark;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: boxWidth,
                  height: boxHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: (isDark ? Wallet.darkSurface : Colors.white)
                        .withOpacity(.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive
                          ? Wallet.accentOf(isDark)
                          : Wallet.lineOf(isDark),
                      width: isActive ? 1.6 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? .3 : .06),
                        blurRadius: 14,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Text(
                    char.isEmpty ? "•" : char,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: char.isEmpty
                          ? Wallet.faintOf(isDark)
                          : Wallet.inkOf(isDark),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }
}
