import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'src/core/fcm_service.dart';
import 'src/routing/app_router.dart';
import 'src/core/guest_mode.dart';
import 'src/core/theme/app_theme.dart';
import 'src/core/providers.dart';
import 'src/features/auth/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web automation/accessibility audits can force the semantics tree on:
  //   flutter build web --dart-define=FORCE_SEMANTICS=true
  if (const bool.fromEnvironment('FORCE_SEMANTICS')) {
    SemanticsBinding.instance.ensureSemantics();
  }

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
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (_) {
      // Firebase not configured (e.g. missing GoogleService-Info.plist on iOS)
    }
    final envKey = const String.fromEnvironment(
      'STRIPE_PUBLISHABLE_KEY',
      defaultValue: '',
    );
    if (envKey.isNotEmpty) {
      Stripe.publishableKey = envKey;
    }
  }
  final container = ProviderContainer();
  await _restoreSession(container);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TawatiApp(),
    ),
  );
}

/// Decides how the app opens, before the first frame is drawn.
///
/// The sign-in page no longer exists, so the app must always know whether it is
/// running as a member or as a visitor:
///   1. a stored member session wins,
///   2. then a stored visitor session,
///   3. otherwise a returning visitor (intro already seen) enters visitor mode,
///   4. otherwise the intro slides are shown (they end into visitor mode).
///
/// This runs here rather than in a splash route because the app uses hash
/// routing: on reload the URL (`#/home`) decides the first route, so a splash
/// screen would simply be skipped.
Future<void> _restoreSession(ProviderContainer container) async {
  final auth = container.read(authProvider.notifier);
  try {
    introSeen = await AppIntro.hasSeen();

    final api = container.read(apiClientProvider);
    final hasToken = (await api.getAccessToken()) != null;
    if (hasToken) {
      // Member session: keep the tokens even if the refresh fails, so a
      // temporary network problem does not silently drop the member to guest.
      await auth.loadUser();
      return;
    }

    if (await auth.restoreGuestSession()) return;

    if (introSeen) {
      await auth.continueAsGuest();
    }
  } catch (_) {
    // Never block startup on a storage or network failure.
  }
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
