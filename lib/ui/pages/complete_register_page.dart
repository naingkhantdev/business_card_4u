import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth/auth_provider.dart';
import '../theme/app_typography.dart';
import '../theme/wallet_tokens.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_toast.dart';
import '../widgets/onboarding_chrome.dart';
import '../widgets/onboarding_step_scaffold.dart';
import 'setup_profile_page.dart';

class CompleteRegisterPage extends ConsumerStatefulWidget {
  final String email;
  const CompleteRegisterPage({super.key, required this.email});

  @override
  ConsumerState<CompleteRegisterPage> createState() =>
      _CompleteRegisterPageState();
}

class _CompleteRegisterPageState extends ConsumerState<CompleteRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _nameFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    // The strength meter reads the field on every keystroke, so the field has
    // to drive a rebuild. Without this it only updated when focus moved.
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _nameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nameFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    AppToast.show(
      context,
      message,
      type: isError ? AppToastType.error : AppToastType.success,
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final result = await ref.read(authProvider.notifier).completeRegister(
          widget.email,
          _nameController.text.trim(),
          _passwordController.text.trim(),
          _confirmController.text.trim(),
        );

    if (!mounted) return;

    if (result.isSuccess) {
      // Registration also created a bare card server-side. Hand straight over
      // to finishing it while the user is still in setup mode — dropping them
      // on an empty card list would leave that card as the placeholder it is.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SetupProfilePage(email: widget.email),
        ),
      );
    } else {
      _showMessage(result.message ?? 'Registration failed', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider).when(
          data: (state) => state,
          loading: () => AuthState(isLoading: true),
          error: (error, stackTrace) => AuthState(),
        );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final busy = authState.isLoading;

    return OnboardingStepScaffold(
      step: 1,
      totalSteps: 2,
      label: 'Account details',
      completed: 'Email verified',
      headline: 'Finish your account',
      subhead: 'Two fields and a password. Your card comes next.',
      onExit: busy ? null : () => Navigator.pop(context),
      busy: busy,
      action: AppPrimaryButton(
        text: 'Create My Account',
        loading: busy,
        onPressed: busy ? null : _submit,
      ),
      secondaryAction: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          'By continuing you agree to our Terms & Privacy.',
          textAlign: TextAlign.center,
          style: AppTypography.secondary(TextStyle(
            fontSize: 11.5,
            color: Wallet.faintOf(isDark),
          )),
        ),
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The verified address, stated as a fact rather than as another
              // field. It is the one thing on this screen already settled, so
              // it reads as progress instead of more work.
              _VerifiedEmail(email: widget.email, isDark: isDark),
              const SizedBox(height: 16),

              OnboardingSection(
                title: 'Who you are',
                children: [
                  OnboardingTextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    enabled: !busy,
                    hintText: 'Full name',
                    prefixIcon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _passFocus.requestFocus(),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Full Name လိုအပ်ပါတယ်';
                      }
                      if (v.trim().length < 2) {
                        return 'နာမည်ကို အနည်းဆုံး 2 လုံးထည့်ပါ';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              OnboardingSection(
                title: 'Set a password',
                caption: 'At least 6 characters. Longer is better.',
                children: [
                  OnboardingTextField(
                    controller: _passwordController,
                    focusNode: _passFocus,
                    enabled: !busy,
                    hintText: 'Password',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
                    suffix: _RevealButton(
                      obscured: _obscurePassword,
                      isDark: isDark,
                      onTap: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Password လိုအပ်ပါတယ်';
                      }
                      if (v.length < 6) {
                        return 'Password ကို အနည်းဆုံး 6 လုံးထည့်ပါ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  // Feedback while typing, not a rule list up front. A wall of
                  // requirements before the first keystroke is read as work;
                  // a meter that fills is read as progress.
                  _StrengthMeter(
                    password: _passwordController.text,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  OnboardingTextField(
                    controller: _confirmController,
                    focusNode: _confirmFocus,
                    enabled: !busy,
                    hintText: 'Confirm password',
                    prefixIcon: Icons.lock_reset_rounded,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    suffix: _RevealButton(
                      obscured: _obscureConfirm,
                      isDark: isDark,
                      onTap: () => setState(
                        () => _obscureConfirm = !_obscureConfirm,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Confirm Password လိုအပ်ပါတယ်';
                      }
                      if (v != _passwordController.text) {
                        return 'Password မတူပါ';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VerifiedEmail extends StatelessWidget {
  final String email;
  final bool isDark;

  const _VerifiedEmail({required this.email, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Wallet.radiusControl),
        color: Wallet.success.withOpacity(isDark ? .12 : .08),
        border: Border.all(
          color: Wallet.success.withOpacity(.35),
          width: Wallet.hairline,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_rounded, size: 17, color: Wallet.success),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VERIFIED',
                  style: AppTypography.eyebrow(
                    color: Wallet.success,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.secondary(TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: Wallet.inkOf(isDark),
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RevealButton extends StatelessWidget {
  final bool obscured;
  final bool isDark;
  final VoidCallback onTap;

  const _RevealButton({
    required this.obscured,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: obscured ? 'Show password' : 'Hide password',
      icon: Icon(
        obscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        size: 19,
        color: Wallet.faintOf(isDark),
      ),
    );
  }
}

/// Three segments that fill as the password gets harder to guess.
///
/// Scored on length first because length is what actually matters, with a
/// smaller credit for mixing character classes. It is guidance, not a gate —
/// the validator still owns whether the form can be submitted.
class _StrengthMeter extends StatelessWidget {
  final String password;
  final bool isDark;

  const _StrengthMeter({required this.password, required this.isDark});

  static const _labels = ['Too short', 'Weak', 'Good', 'Strong'];

  int get _score {
    if (password.isEmpty) return 0;
    if (password.length < 6) return 0;

    var classes = 0;
    if (RegExp(r'[a-z]').hasMatch(password)) classes++;
    if (RegExp(r'[A-Z]').hasMatch(password)) classes++;
    if (RegExp(r'[0-9]').hasMatch(password)) classes++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) classes++;

    if (password.length >= 12 && classes >= 3) return 3;
    if (password.length >= 8 && classes >= 2) return 2;
    return 1;
  }

  Color get _tone {
    switch (_score) {
      case 3:
        return Wallet.success;
      case 2:
        return Wallet.accentOf(isDark);
      case 1:
        return Wallet.pending;
      default:
        return Wallet.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nothing typed yet: an empty meter beside an empty field is just noise.
    if (password.isEmpty) return const SizedBox.shrink();

    final score = _score;
    final tone = _tone;

    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 3,
              decoration: BoxDecoration(
                color: i < score ? tone : Wallet.lineOf(isDark),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
        const SizedBox(width: 10),
        Text(
          _labels[score].toUpperCase(),
          style: AppTypography.eyebrow(
            color: tone,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
