import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth_gate.dart';
import '../../providers/auth/auth_provider.dart';
import '../../services/navigation/app_navigator.dart';
import '../theme/app_colors.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_toast.dart';

class DeactivateAccountPage extends ConsumerStatefulWidget {
  const DeactivateAccountPage({super.key});

  @override
  ConsumerState<DeactivateAccountPage> createState() =>
      _DeactivateAccountPageState();
}

class _DeactivateAccountPageState extends ConsumerState<DeactivateAccountPage> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      AppToast.show(
        context,
        'Please enter your password',
        type: AppToastType.error,
      );
      return;
    }

    setState(() => _submitting = true);
    final authNotifier = ref.read(authProvider.notifier);
    final result = await authNotifier.deactivateAccount(password);

    if (!mounted) return;

    if (!result.success) {
      setState(() => _submitting = false);
      AppToast.show(
        context,
        result.message ?? 'Failed to deactivate account',
        type: AppToastType.error,
      );
      return;
    }

    final message = result.message ??
        'Your account has been deactivated. Log in again within 7 days to restore it.';

    await authNotifier.completeDeactivatedLogout(message);

    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const AuthGate(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF060B16) : const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: Text(
          'Deactivate Account',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0B1220),
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF060B16) : Colors.white,
        surfaceTintColor: isDark ? const Color(0xFF060B16) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D1426) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF1F2A44) : const Color(0xFFE7ECF5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A1620) : const Color(0xFFFFE9EC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.person_off_outlined,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Your account will be turned off now.',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFEAF1FF) : const Color(0xFF0B1220),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'You can get it back by logging in again within 7 days.',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF98A7C2) : const Color(0xFF5B6473),
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enabled: !_submitting,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFEAF1FF) : const Color(0xFF0B1220),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(
                        color: isDark ? const Color(0xFF98A7C2) : const Color(0xFF5B6473),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF10182B) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: isDark ? const Color(0xFF98A7C2) : const Color(0xFF5B6473),
                      ),
                      suffixIcon: IconButton(
                        onPressed: _submitting
                            ? null
                            : () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: isDark ? const Color(0xFF98A7C2) : const Color(0xFF5B6473),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  AppPrimaryButton(
                    text: 'Deactivate Account',
                    loading: _submitting,
                    onPressed: _submitting ? null : _submit,
                    height: 52,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF98A7C2) : AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
