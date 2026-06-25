import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_toast.dart';
import '../widgets/loading_view.dart';

class CompleteRegisterPage extends ConsumerStatefulWidget {
  final String email;
  const CompleteRegisterPage({super.key, required this.email});

  @override
  ConsumerState<CompleteRegisterPage> createState() => _CompleteRegisterPageState();
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
  void dispose() {
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
      _showMessage("Registration Successful");
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      _showMessage("Registration Failed", isError: true);
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
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar
                    Row(
                      children: [
                        _CircleIconButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0B1220),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),

                    const Text(
                      "Finish setup",
                      style: TextStyle(
                        fontSize: 32,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0B1220),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Create your profile and secure your account.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(.55),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Email pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.75),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(.6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.email_outlined, size: 18, color: Colors.black.withOpacity(.55)),
                          const SizedBox(width: 8),
                          Text(
                            widget.email,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0B1220),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Glass Card Form
                    _GlassCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 6),

                            const Text(
                              "Profile details",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0B1220),
                              ),
                            ),

                            const SizedBox(height: 14),

                            _PremiumTextField(
                              controller: _nameController,
                              focusNode: _nameFocus,
                              enabled: !authState.isLoading,
                              hintText: "Full Name",
                              prefixIcon: Icons.person_outline_rounded,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => _passFocus.requestFocus(),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return "Full Name လိုအပ်ပါတယ်";
                                if (v.trim().length < 2) return "နာမည်ကို အနည်းဆုံး 2 လုံးထည့်ပါ";
                                return null;
                              },
                            ),

                            const SizedBox(height: 14),

                            _PremiumTextField(
                              controller: _passwordController,
                              focusNode: _passFocus,
                              enabled: !authState.isLoading,
                              hintText: "Password",
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
                              suffix: IconButton(
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: Colors.black.withOpacity(.55),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return "Password လိုအပ်ပါတယ်";
                                if (v.length < 6) return "Password ကို အနည်းဆုံး 6 လုံးထည့်ပါ";
                                return null;
                              },
                            ),

                            const SizedBox(height: 14),

                            _PremiumTextField(
                              controller: _confirmController,
                              focusNode: _confirmFocus,
                              enabled: !authState.isLoading,
                              hintText: "Confirm Password",
                              prefixIcon: Icons.lock_reset_rounded,
                              obscureText: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              suffix: IconButton(
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                icon: Icon(
                                  _obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: Colors.black.withOpacity(.55),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return "Confirm Password လိုအပ်ပါတယ်";
                                if (v != _passwordController.text) return "Password မတူပါ";
                                return null;
                              },
                            ),

                            const SizedBox(height: 18),

                            // Password hint row
                            Row(
                              children: [
                                Icon(Icons.shield_outlined, size: 18, color: Colors.black.withOpacity(.45)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Use at least 6 characters. Avoid sharing your password.",
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      height: 1.3,
                                      color: Colors.black.withOpacity(.50),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            AppPrimaryButton(
                              text: "Create Account",
                              loading: authState.isLoading,
                              onPressed: authState.isLoading ? null : _submit,
                              height: 54,
                              borderRadius: BorderRadius.circular(18),
                              fontSize: 15.5,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Center(
                      child: Text(
                        "By continuing, you agree to our Terms & Privacy.",
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.black.withOpacity(.45),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),

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
        Container(color: const Color(0xFFE9EDF4)),
        Positioned(
          top: -120,
          left: -60,
          child: _BlurBlob(size: 260, color: AppColors.secondary.withOpacity(.22)),
        ),
        Positioned(
          bottom: -140,
          right: -80,
          child: _BlurBlob(size: 320, color: AppColors.secondaryLight.withOpacity(.18)),
        ),
        Positioned(
          top: 220,
          right: -40,
          child: _BlurBlob(size: 180, color: Colors.white.withOpacity(.35)),
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
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
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

class _PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;

  final String hintText;
  final IconData prefixIcon;

  final bool obscureText;
  final Widget? suffix;

  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  final String? Function(String?)? validator;

  const _PremiumTextField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffix,
    this.textInputAction,
    this.onFieldSubmitted,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0B1220)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.black.withOpacity(.35), fontWeight: FontWeight.w600),
        filled: true,
        fillColor: Colors.white.withOpacity(.85),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIcon: Icon(prefixIcon, color: Colors.black.withOpacity(.55)),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(fontWeight: FontWeight.w600),
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
          child: const Center(
            child: LoadingView(size: 120),
          ),
        ),
      ),
    );
  }
}
