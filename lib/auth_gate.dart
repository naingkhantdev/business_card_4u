import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth/auth_provider.dart';
import 'ui/widgets/loading_view.dart';
import 'ui/pages/login_page.dart';
import 'ui/pages/card_page.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);

    return authAsync.when(
      loading: () => const Scaffold(
        body: Center(child: LoadingView()),
      ),
      error: (error, stack) => const Scaffold(
        body: Center(child: Text('Something went wrong')),
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
