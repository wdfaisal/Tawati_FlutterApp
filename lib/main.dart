import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'src/routing/app_router.dart';
import 'src/core/theme/app_theme.dart';
import 'src/core/providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
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
    ref.read(appConfigServiceProvider).fetchConfig().then((config) {
      if (mounted) {
        ref.read(appConfigProvider.notifier).state = config;
        if (!kIsWeb) {
          final pk = config['stripe_publishable_key'] as String?;
          if (pk != null && pk.isNotEmpty) {
            Stripe.publishableKey = pk;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final primaryHex = config['primary_color'] as String?;
    final seedColor = primaryHex != null
        ? Color(int.parse(primaryHex.replaceFirst('#', '0xFF')))
        : null;

    return MaterialApp.router(
      title: config['app_name'] as String? ?? 'تواتي',
      debugShowCheckedModeBanner: false,
      locale: Locale(config['locale'] as String? ?? 'ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
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
