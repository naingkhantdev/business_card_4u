import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_toast.dart';
import '../widgets/loading_view.dart';
import 'register_page.dart';
import '../theme/wallet_tokens.dart';

class LoginPage extends ConsumerStatefulWidget {
  final String? initialMessage;

  const LoginPage({super.key, this.initialMessage});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  String? _lastShownMessage;

  void _showInfoMessage(String message) {
    AppToast.show(context, message, type: AppToastType.info);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          setState(() {});
        });
      }
    });
    if (widget.initialMessage != null &&
        widget.initialMessage!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _lastShownMessage = widget.initialMessage;
        _showInfoMessage(widget.initialMessage!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider).when(
          data: (state) => state,
          loading: () => AuthState(isCheckingSession: true),
          error: (error, stackTrace) => AuthState(),
        );
    final pendingMessage = authState.pendingMessage;

    if (pendingMessage != null && pendingMessage != _lastShownMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _lastShownMessage = pendingMessage;
        _showInfoMessage(pendingMessage);
        ref.read(authProvider.notifier).clearPendingMessage();
      });
    } else if (pendingMessage == null) {
      _lastShownMessage = null;
    }

    return Theme(
      data: Theme.of(context).copyWith(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.surfaceSoft,
        colorScheme: Theme.of(context).colorScheme.copyWith(
              brightness: Brightness.light,
              surface: Colors.white,
              onSurface: Wallet.ink,
            ),
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Wallet.ink,
              displayColor: Wallet.ink,
            ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.surfaceSoft,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            /// ================= MAIN CONTENT =================
            LayoutBuilder(builder: (context, constraints) {
              final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
              final isKeyboardOpen = keyboardHeight > 100;

              // Everything above the form is sized from the height actually
              // available, not from portrait constants. Landscape leaves about
              // 360dp in total, and a fixed 200 + 200 hero stack overflowed it
              // before the form got a single pixel.
              final available = constraints.maxHeight;
              final heroHeight =
                  isKeyboardOpen ? 80.0 : (available * .27).clamp(96.0, 200.0);
              // The illustration is the first thing to go: it is decoration,
              // and the fields below it are not. It only appears once the form
              // has kept the room it needs.
              const formRoom = 300.0;
              final artHeight =
                  (available - heroHeight - formRoom).clamp(0.0, 200.0);
              final showArt = !isKeyboardOpen && artHeight >= 96;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  /// ================= HERO SECTION =================
                  SizedBox(
                    height: heroHeight,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: PremiumHeroPainter(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: heroHeight >= 160 ? 40 : 12),
                          if (!isKeyboardOpen)
                            RichText(
                              text: TextSpan(
                                text: 'businessCard',
                                style: AppTypography.primary(
                                  const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    color: Wallet.ink,
                                  ),
                                ),
                                children: const [
                                  TextSpan(
                                    text: '4U',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  /// ================= FULL WIDTH IMAGE =================
                  if (showArt)
                    Image.asset(
                      'assets/images/login.png',
                      height: artHeight,
                      fit: BoxFit.contain,
                    ),

                  /// ================= LOGIN FORM (scrollable) =================
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _inputField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 18),
                          _inputField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_outline,
                            obscure: _obscurePassword,
                            focusNode: _passwordFocusNode,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 28),
                          AppPrimaryButton(
                            text: 'Log In',
                            loading: authState.isLoading,
                            onPressed: authState.isLoading
                                ? null
                                : () async {
                                    final result = await ref
                                        .read(authProvider.notifier)
                                        .login(
                                          _emailController.text.trim(),
                                          _passwordController.text.trim(),
                                        );

                                    if (!result.isSuccess && context.mounted) {
                                      final updatedAuthState =
                                          ref.read(authProvider).valueOrNull;
                                      AppToast.show(
                                        context,
                                        updatedAuthState?.lastErrorMessage ??
                                            'Invalid email or password',
                                        type: AppToastType.error,
                                      );
                                    }
                                  },
                            height: 52,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterPage(),
                                ),
                              );
                            },
                            child:
                                const Text("Don't have an account? Register"),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Developed by Asia Brightway',
                            style: AppTypography.tertiary(
                              const TextStyle(
                                color: Color(0xFF5B6473),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),

            /// ================= LOADING OVERLAY =================
            if (authState.isLoading)
              AbsorbPointer(
                absorbing: true,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LoadingView(size: 120),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            ref.read(authProvider.notifier).cancelLoading();
                          },
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    FocusNode? focusNode,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      style: AppTypography.secondary(
        const TextStyle(
          color: Wallet.ink,
          fontWeight: FontWeight.w400,
        ),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.tertiary(
          const TextStyle(color: Color(0xFF5B6473)),
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF5B6473)),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

/// ================= HERO WAVE PAINTER =================
class PremiumHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.lineTo(0, size.height * 0.75);

    path.quadraticBezierTo(
      size.width * 0.6,
      size.height * 1.05,
      size.width,
      size.height * 0.85,
    );

    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
