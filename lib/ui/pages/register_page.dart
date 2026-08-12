import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_toast.dart';
import 'otp_page.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
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
        MaterialPageRoute(builder: (_) => OtpPage(email: email)),
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

    const bg = AppColors.surfaceSoft;
    const text = Color(0xFF0B1220);
    const muted = Color(0xFF5B6473);
    const border = Color(0xFFE7EAF3);

    const deep = AppColors.secondary;
    const blue = AppColors.primary;

    return Theme(
      data: Theme.of(context).copyWith(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.surfaceSoft,
        colorScheme: Theme.of(context).colorScheme.copyWith(
              brightness: Brightness.light,
              surface: Colors.white,
              onSurface: text,
            ),
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: text,
              displayColor: text,
            ),
      ),
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(colors: [deep, blue]),
                      ),
                      child: const Icon(
                        Icons.badge_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'businessCard4U',
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Create your account',
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.w600,
                    fontSize: 28,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Enter your email to receive a verification code.',
                  style: TextStyle(
                    color: muted,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.06),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Email',
                        style: TextStyle(
                          color: text,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: border),
                        ),
                        child: TextField(
                          controller: _emailController,
                          enabled: !authState.isLoading,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) =>
                              authState.isLoading ? null : _submit(),
                          decoration: const InputDecoration(
                            hintText: 'example@gmail.com',
                            hintStyle: TextStyle(color: muted),
                            prefixIcon: Icon(
                              Icons.alternate_email_rounded,
                              color: blue,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                          style: const TextStyle(color: text),
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppPrimaryButton(
                        text: 'Send code',
                        loading: authState.isLoading,
                        onPressed: authState.isLoading ? null : _submit,
                        height: 50,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Code expires in 5 minutes.',
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Center(
                  child: Text(
                    'businessCard4U ${DateTime.now().year}',
                    style: const TextStyle(
                      color: muted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
