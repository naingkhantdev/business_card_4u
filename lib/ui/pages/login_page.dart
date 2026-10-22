import 'dart:ui';
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
import '../widgets/loading_view.dart';
import '../widgets/premium_hero_painter.dart';
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
    final l10n = AppLocalizations.of(context)!;
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

    if (Responsive.isDesktop(context)) {
      return _buildDesktop(authState);
    }

    // Forced light on purpose: the hero illustration (login.png) is drawn
    // for a light background and isn't ready for a dark one, so unlike the
    // rest of the app this page doesn't follow the system theme. isDark
    // stays false so every Wallet.*Of(isDark) call below still resolves to
    // its light value; wrapping in Theme keeps default-styled descendants
    // (TextButton, the password-visibility IconButton) light too, not just
    // the colors set explicitly here.
    const isDark = false;

    return Theme(
      data: Theme.of(context).copyWith(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Wallet.groundOf(isDark),
        colorScheme: Theme.of(context).colorScheme.copyWith(
              brightness: Brightness.light,
              surface: Wallet.surfaceOf(isDark),
              onSurface: Wallet.inkOf(isDark),
            ),
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Wallet.inkOf(isDark),
              displayColor: Wallet.inkOf(isDark),
            ),
      ),
      child: Scaffold(
        backgroundColor: Wallet.groundOf(isDark),
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
                      painter: PremiumHeroPainter(color: Wallet.surfaceOf(isDark)),
                      child: Column(
                        // Centered, not top-anchored — anchoring to the top
                        // left a large dead gap above the wave at taller
                        // hero heights, since the wave itself is now a
                        // shallow shape confined near the bottom edge
                        // (peaking no higher than 85% down). Centered text
                        // lands well clear of that without hugging the top.
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: heroHeight >= 160 ? 12 : 6),
                          if (!isKeyboardOpen)
                            RichText(
                              text: TextSpan(
                                text: 'businessCard',
                                style: AppTypography.primary(
                                  TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    color: Wallet.inkOf(isDark),
                                  ),
                                ),
                                children: [
                                  TextSpan(
                                    text: '4U',
                                    style: TextStyle(
                                      color: Wallet.accentOf(isDark),
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
                    // Fades the scroll content at the top and bottom edges
                    // instead of cutting it off abruptly — the usual cue
                    // that there's more to scroll to in that direction.
                    child: ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black,
                          Colors.black,
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.04, 0.94, 1.0],
                      ).createShader(rect),
                      blendMode: BlendMode.dstIn,
                      child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _inputField(
                            controller: _emailController,
                            label: l10n.loginPageEmailLabel,
                            icon: Icons.email_outlined,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 18),
                          _inputField(
                            controller: _passwordController,
                            label: l10n.loginPagePasswordLabel,
                            icon: Icons.lock_outline,
                            obscure: _obscurePassword,
                            focusNode: _passwordFocusNode,
                            isDark: isDark,
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
                            text: l10n.loginPageLogIn,
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

                                    if (!result.isSuccess &&
                                        !result.cancelled &&
                                        context.mounted) {
                                      final updatedAuthState =
                                          ref.read(authProvider).valueOrNull;
                                      AppToast.show(
                                        context,
                                        updatedAuthState?.lastErrorMessage ??
                                            l10n.loginPageInvalidCredentials,
                                        type: AppToastType.error,
                                      );
                                    }
                                  },
                            height: 52,
                            borderRadius:
                                BorderRadius.circular(Wallet.radiusControl),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                AppPageRoute(
                                  builder: (_) => const RegisterPage(),
                                ),
                              );
                            },
                            child: Text(l10n.loginPageNoAccountRegister),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.loginPageDevelopedBy,
                            style: AppTypography.tertiary(
                              TextStyle(
                                color: Wallet.mutedOf(isDark),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    ),
                  ),
                ],
              );
            }),

            /// ================= LOADING OVERLAY =================
            if (authState.isLoading)
              _SigningInOverlay(
                onCancel: () =>
                    ref.read(authProvider.notifier).cancelLoading(),
              ),
          ],
        ),
      ),
    );
  }

  /// Desktop-web layout: a brand panel plus this same form, each with real
  /// room, instead of the mobile hero-and-scroll column full-bleed on a
  /// browser window. The mobile branch above is untouched.
  Widget _buildDesktop(AuthState authState) {
    return Stack(
      children: [
        AuthWebCard(form: _buildFormFields(authState)),
        if (authState.isLoading)
          _SigningInOverlay(
            onCancel: () => ref.read(authProvider.notifier).cancelLoading(),
          ),
      ],
    );
  }

  Widget _buildFormFields(AuthState authState) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.loginPageWelcomeBack,
          style: AppTypography.primary(
            const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Wallet.ink,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.loginPageSubtitle,
          style: AppTypography.secondary(
            const TextStyle(color: Wallet.muted),
          ),
        ),
        const SizedBox(height: 32),
        NeumorphicField(
          controller: _emailController,
          label: l10n.loginPageEmailLabel,
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 18),
        NeumorphicField(
          controller: _passwordController,
          label: l10n.loginPagePasswordLabel,
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          focusNode: _passwordFocusNode,
          suffix: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
        const SizedBox(height: 28),
        NeumorphicButton(
          text: l10n.loginPageLogIn,
          loading: authState.isLoading,
          onPressed: authState.isLoading
              ? null
              : () async {
                  final result = await ref.read(authProvider.notifier).login(
                        _emailController.text.trim(),
                        _passwordController.text.trim(),
                      );

                  if (!result.isSuccess &&
                      !result.cancelled &&
                      context.mounted) {
                    final updatedAuthState =
                        ref.read(authProvider).valueOrNull;
                    AppToast.show(
                      context,
                      updatedAuthState?.lastErrorMessage ??
                          l10n.loginPageInvalidCredentials,
                      type: AppToastType.error,
                    );
                  }
                },
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                AppPageRoute(builder: (_) => const RegisterPage()),
              );
            },
            child: Text(l10n.loginPageNoAccountRegister),
          ),
        ),
      ],
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool obscure = false,
    FocusNode? focusNode,
    Widget? suffix,
  }) {
    OutlineInputBorder outline(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(Wallet.radiusControl),
          borderSide: BorderSide(color: color, width: width),
        );

    // The field's fill used to be flat white, almost indistinguishable from
    // the page background in light mode and always wrong in dark mode since
    // this whole page used to force light regardless of system theme. A
    // hairline border plus a soft shadow give it a boundary at rest, using
    // the same light/dark tokens as the rest of the app.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Wallet.radiusControl),
        boxShadow: Wallet.shadowOf(isDark),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscure,
        style: AppTypography.secondary(
          TextStyle(
            color: Wallet.inkOf(isDark),
            fontWeight: FontWeight.w400,
          ),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTypography.tertiary(
            TextStyle(color: Wallet.mutedOf(isDark)),
          ),
          prefixIcon: Icon(icon, color: Wallet.mutedOf(isDark)),
          suffixIcon: suffix,
          filled: true,
          fillColor: Wallet.surfaceOf(isDark),
          border: outline(Wallet.lineOf(isDark), 1),
          enabledBorder: outline(Wallet.lineOf(isDark), 1),
          focusedBorder: outline(Wallet.accentOf(isDark), 1.6),
        ),
      ),
    );
  }
}

/// Shown over the login form while signing in: the fading ABW loader on a
/// blur, with Cancel underneath.
///
/// Taps on the form behind are stopped by a barrier *underneath* the loader.
/// The old version wrapped the whole overlay in an AbsorbPointer, which
/// swallowed the Cancel button's own taps along with the form's.
class _SigningInOverlay extends StatelessWidget {
  final VoidCallback onCancel;

  const _SigningInOverlay({required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      fit: StackFit.expand,
      children: [
        const ModalBarrier(dismissible: false),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LoadingView(size: 120),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: onCancel,
                  child: Text(l10n.loginPageCancel),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
