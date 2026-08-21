import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'src/core/fcm_service.dart';
import 'src/routing/app_router.dart';
import 'src/core/theme/app_theme.dart';
import 'src/core/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  if (!kIsWeb) {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    final envKey = const String.fromEnvironment(
      'STRIPE_PUBLISHABLE_KEY',
      defaultValue: '',
    );
    if (envKey.isNotEmpty) {
      Stripe.publishableKey = envKey;
    }
  }
  runApp(const ProviderScope(child: TawatiApp()));
}

class TawatiApp extends ConsumerStatefulWidget {
  const TawatiApp({super.key});

  @override
  ConsumerState<TawatiApp> createState() => _TawatiAppState();
}

class _TawatiAppState extends ConsumerState<TawatiApp> {
  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    Map<String, dynamic> config;
    try {
      config = await ref.read(appConfigServiceProvider).fetchConfig();
    } catch (_) {
      config = {};
    }
    if (!mounted) return;
    ref.read(appConfigProvider.notifier).state = config;
    if (!kIsWeb) {
      final pk = config['stripe_publishable_key'] as String?;
      if (pk != null && pk.isNotEmpty) {
        Stripe.publishableKey = pk;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final primaryHex = config['primary_color'] as String?;
    Color? seedColor;
    if (primaryHex != null && primaryHex.isNotEmpty) {
      final value = int.tryParse('0xFF${primaryHex.replaceFirst('#', '')}');
      if (value != null) seedColor = Color(value);
    }

    return MaterialApp.router(
      title: config['app_name'] as String? ?? 'تواتي',
      debugShowCheckedModeBanner: false,
      locale: Locale(config['locale'] as String? ?? 'ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        quill.FlutterQuillLocalizations.delegate,
      ],
      routerConfig: appRouter,
      theme: seedColor != null
          ? AppTheme.fromSeed(seedColor)
          : AppTheme.light,
      darkTheme: null,
      themeMode: ThemeMode.light,
    );
  }
}
