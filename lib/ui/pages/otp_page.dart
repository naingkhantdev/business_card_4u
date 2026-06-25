import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_toast.dart';
import '../widgets/loading_view.dart';
import 'complete_register_page.dart';

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
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      _showMessage("OTP ၆ လုံး ထည့်ပါ", isError: true);
      return;
    }

    final result =
        await ref.read(authProvider.notifier).verifyOtpOnly(widget.email, otp);

    if (!mounted) return;
    final message = result.message ??
        (result.success ? "OTP verified" : "Something went wrong");
    _showMessage(message, isError: !result.success);

    if (result.success) {
      Future.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
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
    _showMessage(
      result.message ??
          (result.success ? "OTP resent" : "Failed to resend OTP"),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _PremiumBackground(),

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
                        ),
                        const Spacer(),
                        _TimerPill(
                          timeText: _formattedTime,
                          isExpired: _secondsRemaining == 0,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      "Verify OTP",
                      style: TextStyle(
                        fontSize: 30,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0B1220),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "We sent a 6-digit code to",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(.55),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      widget.email,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0B1220),
                      ),
                    ),

                    const SizedBox(height: 26),

                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 6),

                          const Text(
                            "Enter OTP",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0B1220),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // 6-digit PIN style input
                          _OtpPinField(
                            controller: _otpController,
                            focusNode: _otpFocus,
                            enabled: !authState.isLoading,
                            onCompleted: (_) => _verifyOtp(),
                          ),

                          const SizedBox(height: 22),

                          // Verify button
                          AppPrimaryButton(
                            text: "Verify OTP",
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
                                    ? "Resend OTP"
                                    : "Resend available after $_formattedTime",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: (_secondsRemaining == 0 &&
                                          !authState.isLoading)
                                      ? const Color(0xFF1E3C72)
                                      : Colors.black.withOpacity(.35),
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
                            size: 18, color: Colors.black.withOpacity(.45)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Don’t share your OTP with anyone. This code expires in 5 minutes.",
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                              color: Colors.black.withOpacity(.50),
                              fontWeight: FontWeight.w500,
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
          if (authState.isLoading) const _LoadingGlassOverlay(),
        ],
      ),
    );
  }
}

/* ===================== Premium UI Widgets ===================== */

class _PremiumBackground extends StatelessWidget {
  const _PremiumBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base
        Container(color: const Color(0xFFE9EDF4)),

        // Gradient blobs
        Positioned(
          top: -120,
          left: -60,
          child: _BlurBlob(
            size: 260,
            color: AppColors.secondary.withOpacity(.22),
          ),
        ),
        Positioned(
          bottom: -140,
          right: -80,
          child: _BlurBlob(
            size: 320,
            color: AppColors.secondaryLight.withOpacity(.18),
          ),
        ),
        Positioned(
          top: 220,
          right: -40,
          child: _BlurBlob(
            size: 180,
            color: Colors.white.withOpacity(.35),
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
  const _GlassCard({required this.child});

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
            color: Colors.white.withOpacity(.75),
            border: Border.all(color: Colors.white.withOpacity(.55)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.08),
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
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.75),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF0B1220)),
      ),
    );
  }
}

class _TimerPill extends StatelessWidget {
  final String timeText;
  final bool isExpired;
  const _TimerPill({required this.timeText, required this.isExpired});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.6)),
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
              fontWeight: FontWeight.w800,
              color: isExpired ? AppColors.errorBg : AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingGlassOverlay extends StatelessWidget {
  const _LoadingGlassOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          color: Colors.black.withOpacity(.08),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.88),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.12),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LoadingView(size: 22),
                  SizedBox(width: 12),
                  Text(
                    "Please wait...",
                    style: TextStyle(fontWeight: FontWeight.w700),
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

  const _OtpPinField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    this.onCompleted,
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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) {
              final char = i < value.length ? value[i] : '';
              final isActive =
                  widget.focusNode.hasFocus && i == value.length.clamp(0, 5);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 46,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive
                        ? AppColors.secondary
                        : Colors.black.withOpacity(.10),
                    width: isActive ? 1.6 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.06),
                      blurRadius: 14,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Text(
                  char.isEmpty ? "•" : char,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: char.isEmpty
                        ? Colors.black.withOpacity(.18)
                        : const Color(0xFF0B1220),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
