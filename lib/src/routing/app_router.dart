import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tawati_mobile/src/features/auth/screens/onboarding_screen.dart';
import 'package:tawati_mobile/src/features/auth/screens/login_screen.dart';
import 'package:tawati_mobile/src/features/auth/screens/first_login_screen.dart';
import 'package:tawati_mobile/src/features/auth/screens/family_setup_screen.dart';
import 'package:tawati_mobile/src/features/auth/screens/register_screen.dart';
import 'package:tawati_mobile/src/features/auth/screens/pending_review_screen.dart';
import 'package:tawati_mobile/src/features/auth/screens/welcome_screen.dart';
import 'package:tawati_mobile/src/features/auth/screens/otp_verification_screen.dart';
import 'package:tawati_mobile/src/features/auth/screens/activation_phone_screen.dart';
import 'package:tawati_mobile/src/features/auth/screens/activation_otp_screen.dart';
import 'package:tawati_mobile/src/features/auth/screens/activation_password_screen.dart';
import 'package:tawati_mobile/src/features/auth/screens/activation_success_screen.dart';
import 'package:tawati_mobile/src/features/auth/screens/pending_approval_screen.dart';
import 'package:tawati_mobile/src/features/auth/screens/home_screen.dart';
import 'package:tawati_mobile/src/features/news/screens/news_tab.dart';
import 'package:tawati_mobile/src/features/news/screens/news_detail_screen.dart';
import 'package:tawati_mobile/src/features/news/screens/add_announcement_screen.dart';
import 'package:tawati_mobile/src/features/news/screens/add_obituary_screen.dart';
import 'package:tawati_mobile/src/features/donations/screens/donations_tab.dart';
import 'package:tawati_mobile/src/features/donations/screens/campaign_detail_screen.dart';
import 'package:tawati_mobile/src/features/donations/screens/my_donations_screen.dart';
import 'package:tawati_mobile/src/features/donations/screens/admin_donations_screen.dart';
import 'package:tawati_mobile/src/features/donations/screens/donation_detail_screen.dart';
import 'package:tawati_mobile/src/features/donations/screens/donation_reports_screen.dart';
import 'package:tawati_mobile/src/features/family/screens/family_tree_screen.dart';
import 'package:tawati_mobile/src/features/initiatives/screens/initiatives_tab.dart';
import 'package:tawati_mobile/src/features/initiatives/screens/initiative_detail_screen.dart';
import 'package:tawati_mobile/src/features/groups/screens/group_chat_screen.dart';
import 'package:tawati_mobile/src/features/notifications/screens/notifications_screen.dart';
import 'package:tawati_mobile/src/features/join_requests/screens/join_requests_tab.dart';
import 'package:tawati_mobile/src/features/join_requests/screens/join_request_detail_screen.dart';
import 'package:tawati_mobile/src/features/news/screens/my_announcements_tab.dart';

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
        reverseTransitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(
              opacity: curved,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 28,
                      offset: const Offset(-14, 0),
                    ),
                  ],
                ),
                child: child,
              ),
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
      path: '/pending-review',
      name: 'pendingReview',
      pageBuilder: (context, state) {
        final requestId = (state.extra as Map?)?['requestId'] as String? ?? '';
        return CustomTransitionPage(
          key: state.pageKey,
          child: PendingReviewScreen(requestId: requestId),
          transitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
                child: child,
              ),
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/activation-phone',
      name: 'activationPhone',
      builder: (c, s) => const ActivationPhoneScreen(),
    ),
    GoRoute(
      path: '/activation-otp',
      name: 'activationOtp',
      builder: (c, s) {
        final phone = s.extra as String? ?? '';
        return ActivationOtpScreen(phone: phone);
      },
    ),
    GoRoute(
      path: '/activation-password',
      name: 'activationPassword',
      builder: (c, s) {
        final data = s.extra as Map<String, dynamic>? ?? {};
        return ActivationPasswordScreen(phone: data['phone'] as String? ?? '', otp: data['otp'] as String? ?? '');
      },
    ),
    GoRoute(
      path: '/activation-success',
      name: 'activationSuccess',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const ActivationSuccessScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1).animate(curved),
                child: child,
              ),
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/pending-approval',
      name: 'pendingApproval',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const PendingApprovalScreen(),
          transitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
                child: child,
              ),
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/welcome',
      name: 'welcome',
      pageBuilder: (context, state) {
        final name = (state.extra as Map?)?['name'] as String? ?? '';
        return CustomTransitionPage(
          key: state.pageKey,
          child: WelcomeScreen(userName: name),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1).animate(curved),
                child: child,
              ),
            );
          },
        );
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
    GoRoute(
      path: '/admin/donations',
      name: 'adminDonations',
      builder: (c, s) => const AdminDonationsScreen(),
    ),
    GoRoute(
      path: '/admin/donation-detail',
      name: 'adminDonationDetail',
      builder: (c, s) => DonationDetailScreen(donation: s.extra as Map<String, dynamic>),
    ),
    GoRoute(
      path: '/admin/donation-reports',
      name: 'adminDonationReports',
      builder: (c, s) => const DonationReportsScreen(),
    ),
    GoRoute(
      path: '/notifications',
      name: 'notifications',
      builder: (c, s) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/add-announcement',
      name: 'addAnnouncement',
      builder: (c, s) => AddAnnouncementScreen(editData: s.extra as Map<String, dynamic>?),
    ),
    GoRoute(
      path: '/my-announcements',
      name: 'myAnnouncements',
      builder: (c, s) => const MyAnnouncementsTab(),
    ),
    GoRoute(
      path: '/add-obituary',
      name: 'addObituary',
      builder: (c, s) => const AddObituaryScreen(),
    ),
    GoRoute(
      path: '/join-requests',
      name: 'joinRequests',
      builder: (c, s) => const JoinRequestsTab(),
    ),
    GoRoute(
      path: '/join-request/:id',
      name: 'joinRequestDetail',
      builder: (c, s) {
        final request = s.extra as dynamic;
        return JoinRequestDetailScreen(
          requestId: s.pathParameters['id']!,
          initialRequest: request,
        );
      },
    ),
  ],
);
