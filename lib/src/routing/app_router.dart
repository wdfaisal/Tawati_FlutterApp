import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tawati_mobile/src/features/auth/screens/onboarding_screen.dart';
import 'package:tawati_mobile/src/features/auth/screens/login_screen.dart';
import 'package:tawati_mobile/src/features/auth/screens/first_login_screen.dart';
import 'package:tawati_mobile/src/features/auth/screens/family_setup_screen.dart';
import 'package:tawati_mobile/src/features/auth/screens/register_screen.dart';
import 'package:tawati_mobile/src/features/auth/screens/otp_verification_screen.dart';
import 'package:tawati_mobile/src/features/auth/screens/home_screen.dart';
import 'package:tawati_mobile/src/features/news/screens/news_tab.dart';
import 'package:tawati_mobile/src/features/news/screens/news_detail_screen.dart';
import 'package:tawati_mobile/src/features/donations/screens/donations_tab.dart';
import 'package:tawati_mobile/src/features/donations/screens/campaign_detail_screen.dart';
import 'package:tawati_mobile/src/features/donations/screens/my_donations_screen.dart';
import 'package:tawati_mobile/src/features/family/screens/family_tree_screen.dart';
import 'package:tawati_mobile/src/features/initiatives/screens/initiatives_tab.dart';
import 'package:tawati_mobile/src/features/initiatives/screens/initiative_detail_screen.dart';
import 'package:tawati_mobile/src/features/groups/screens/group_chat_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'onboarding',
      builder: (c, s) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.25, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (c, s) => RegisterScreen(showJoinOnly: s.extra is Map && (s.extra as Map)['join'] == true),
    ),
    GoRoute(
      path: '/otp-verification',
      name: 'otpVerification',
      builder: (c, s) {
        final phone = s.extra as String? ?? '';
        return OtpVerificationScreen(phone: phone);
      },
    ),
    GoRoute(
      path: '/first-login',
      name: 'firstLogin',
      builder: (c, s) => const FirstLoginScreen(),
    ),
    GoRoute(
      path: '/family-setup',
      name: 'familySetup',
      builder: (c, s) {
        final extra = s.extra as Map?;
        return FamilySetupScreen(userId: extra?['userId'] as String? ?? '');
      },
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (c, s) => const HomeScreen(),
    ),
    GoRoute(
      path: '/news',
      name: 'news',
      builder: (c, s) => const NewsTab(),
    ),
    GoRoute(
      path: '/news/detail',
      name: 'newsDetail',
      builder: (c, s) => NewsDetailScreen(newsItem: s.extra as Map<String, dynamic>?),
    ),
    GoRoute(
      path: '/campaign/:id',
      name: 'campaignDetail',
      builder: (c, s) => CampaignDetailScreen(campaignId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/donations',
      name: 'donations',
      builder: (c, s) => const DonationsTab(),
    ),
    GoRoute(
      path: '/family-tree',
      name: 'familyTree',
      builder: (c, s) => const FamilyTreeScreen(),
    ),
    GoRoute(
      path: '/initiatives',
      name: 'initiatives',
      builder: (c, s) => const InitiativesTab(),
    ),
    GoRoute(
      path: '/groups/chat',
      name: 'groupChat',
      builder: (c, s) {
        final extra = s.extra as Map<String, dynamic>?;
        return GroupChatScreen(
          groupId: extra?['groupId'] as String? ?? '',
          groupName: extra?['groupName'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: '/initiative-detail/:id',
      name: 'initiativeDetail',
      builder: (c, s) => InitiativeDetailScreen(campaignId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/my-donations',
      name: 'myDonations',
      builder: (c, s) => const MyDonationsScreen(),
    ),
  ],
);
