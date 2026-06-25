import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_gate.dart';
import 'fcm/push_notification_service.dart';
import 'firebase_options.dart';
import 'network/consts.dart';
import 'ui/theme/app_theme.dart';
import 'ui/theme/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  debugPrint('API BASE_URL: ${dotenv.env['BASE_URL'] ?? kBaseUrl}');

  FlutterError.onError = (details) {
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    debugPrint('Stack: ${details.stack}');
  };

  await _initializeFirebase();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

Future<void> _initializeFirebase() async {
  if (!DefaultFirebaseOptions.isConfigured) {
    debugPrint(
      'Firebase is not configured. Push notifications are disabled.\n'
      'Run `flutterfire configure` and add google-services.json to enable FCM.',
    );
    return;
  }

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await PushNotificationService.initialize();
  } catch (e, stackTrace) {
    debugPrint(
      'Firebase initialization skipped. Push notifications are disabled.\n'
      'Run `flutterfire configure` and add google-services.json to enable FCM.\n'
      'Error: $e\n$stackTrace',
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider).when(
          data: (mode) => mode,
          loading: () => ThemeMode.system,
          error: (_, __) => ThemeMode.system,
        );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const AuthGate(),
      builder: (context, child) {
        // Force font stack on all raw TextStyle across the app
        return DefaultTextStyle(
          style: AppTheme.withFontStack(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
