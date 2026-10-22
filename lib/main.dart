import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_gate.dart';
import 'fcm/push_notification_service.dart';
import 'firebase_options.dart';
import 'l10n/generated/app_localizations.dart';
import 'network/consts.dart';
import 'providers/locale/locale_provider.dart';
import 'services/navigation/app_navigator.dart';
import 'ui/theme/app_theme.dart';
import 'ui/theme/app_typography.dart';

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
    final locale = ref.watch(localeProvider);
    // The themes below bake eyebrow styles (input labels, chips, tabs), so the
    // script has to be known before they are built, not just in the builder.
    AppTypography.setLocale(locale);

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // The OS is the only control. There is no in-app override, so the app
      // follows the phone appearance setting and switches with it live.
      themeMode: ThemeMode.system,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const AuthGate(),
      builder: (context, child) {
        // The builder sits under Localizations, so this is the first place the
        // resolved locale (including "follow the system") is known. Myanmar
        // needs looser leading and no tracking; see AppTypography.
        AppTypography.setLocale(Localizations.localeOf(context));
        final theme = Theme.of(context);

        // Force font stack on all raw TextStyle across the app
        final content = DefaultTextStyle(
          style: AppTheme.withFontStack(
            theme.textTheme.bodyMedium ?? const TextStyle(),
          ),
          child: child ?? const SizedBox.shrink(),
        );

        if (!AppTypography.isMyanmar) return content;
        return Theme(
          data: theme.copyWith(
            textTheme: AppTypography.forScriptTheme(theme.textTheme),
            primaryTextTheme:
                AppTypography.forScriptTheme(theme.primaryTextTheme),
          ),
          child: content,
        );
      },
    );
  }
}
