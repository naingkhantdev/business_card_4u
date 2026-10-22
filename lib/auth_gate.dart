import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/generated/app_localizations.dart';
import 'providers/auth/auth_provider.dart';
import 'ui/widgets/app_splash_view.dart';
import 'ui/pages/login_page.dart';
import 'ui/pages/card_page.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  /// The splash's own entrance animation runs about 1.5s. Reading the saved
  /// token is often faster than that (especially when there isn't one), so
  /// without this floor the splash would swap out mid-reveal — the "not
  /// fully show" this replaced. Real auth work is untouched: this only
  /// holds the splash a little longer, never speeds up or blocks it.
  bool _minSplashElapsed = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (mounted) setState(() => _minSplashElapsed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authProvider);

    if (!_minSplashElapsed || authAsync.isLoading) {
      return const AppSplashView();
    }

    return authAsync.when(
      loading: () => const AppSplashView(),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text(AppLocalizations.of(context)!.authGateSomethingWrong),
        ),
      ),
      data: (authState) {
        if (authState.isLoggedIn) {
          return const CardPage();
        }
        return const LoginPage();
      },
    );
  }
}
