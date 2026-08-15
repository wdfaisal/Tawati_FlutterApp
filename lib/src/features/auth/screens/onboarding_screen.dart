import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:tawati_mobile/src/core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPageData(
      image: 'assets/images/Splash_Screen_Image_4.png',
      icon: Icons.groups_rounded,
      line1: 'منصة تواتي للخدمة',
      line2: 'المجتمعية',
      subtitle: 'ساهم في تنمية مجتمعك وكن جزءاً من مبادرات تواتي الهادفة التي تجمعنا جميعاً كن جزء من «تواتي عالم جميل».',
    ),
    _OnboardingPageData(
      image: 'assets/images/onboarding_bg_2.png',
      icon: Icons.badge_rounded,
      line1: 'هوية تواتي',
      line2: 'الرقمية',
      subtitle: 'لأننا نعتز بهويتنا التواتية وثقناها رقمياً، ثق بياناتك واحصل على هوية تواتي الرقمية.',
    ),
    _OnboardingPageData(
      image: 'assets/images/onboarding_bg_3.png',
      icon: Icons.family_restroom_rounded,
      line1: 'تواصل أسري',
      line2: 'مترابط',
      subtitle: 'ابقَ على اتصال دائم مع عائلتك وشاركهم اللحظات والخدمات في بيئة رقمية آمنة وخاصة.',
    ),
  ];

  bool get _isLast => _currentPage == _pages.length - 1;

  void _onNext() {
    if (!_isLast) {
      setState(() => _currentPage++);
    } else {
      context.pushNamed('login');
    }
  }

  void _onPrevious() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemStatusBarContrastEnforced: false,
        ),
        child: Scaffold(
          backgroundColor: AppColors.surface,
          body: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! < 0) {
                  _onNext();
                } else if (details.primaryVelocity! > 0) {
                  _onPrevious();
                }
              }
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _buildPage(context, page),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, _OnboardingPageData page) {
    return Column(
      key: ValueKey('page_$_currentPage'),
      children: [
        SafeArea(
          bottom: false,
          child: _buildTopNav(context),
        ),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                page.image,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.primaryLight),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00F8FAFC),
                      Color(0x000F172A),
                      Color(0xFFF8FAFC),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildContent(context, page),
      ],
    );
  }

  Widget _buildTopNav(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
      child: Row(
        children: [
          Image.asset(
            'assets/images/splash_logo.png',
            height: 48,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox(width: 48, height: 48),
          ),
          const Spacer(),
          if (_isLast)
            const SizedBox(width: 40)
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => context.pushNamed('login'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  child: const Text(
                    'تخطي',
                    style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  'يُقبل طلب انضمامك بعد مراجعة الإدارة',
                  style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, _OnboardingPageData page) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(page.icon, size: 32, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              page.line1,
              style: const TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 4),
            _UnderlinedWord(text: page.line2, fontSize: 26),
            const SizedBox(height: 12),
            Text(
              page.subtitle,
              style: const TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDots(),
                _buildActionButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_pages.length, (i) {
        final isActive = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }

  Widget _buildActionButton() {
    return Material(
      color: _isLast ? AppColors.primary : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: _isLast ? BorderSide.none : const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      shadowColor: AppColors.primary.withValues(alpha: 0.28),
      elevation: _isLast ? 10 : 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: _onNext,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: _isLast ? 36 : 24, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isLast ? 'ابدأ الآن' : 'التالي',
                style: TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _isLast ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                _isLast ? Icons.check : Icons.arrow_back,
                size: 16,
                color: _isLast ? Colors.white : AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final String image;
  final IconData icon;
  final String line1;
  final String line2;
  final String subtitle;

  const _OnboardingPageData({
    required this.image,
    required this.icon,
    required this.line1,
    required this.line2,
    required this.subtitle,
  });
}

class _UnderlinedWord extends StatelessWidget {
  final String text;
  final double fontSize;

  const _UnderlinedWord({required this.text, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'IBMPlexSansArabic',
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: AppColors.primary,
      height: 1.25,
    );
    return CustomPaint(
      painter: _UnderlinePainter(text: text, style: style),
      child: Text(text, style: style),
    );
  }
}

class _UnderlinePainter extends CustomPainter {
  final String text;
  final TextStyle style;

  const _UnderlinePainter({required this.text, required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.rtl,
    )..layout(maxWidth: size.width);
    final metrics = tp.computeLineMetrics();
    if (metrics.isNotEmpty) {
      final underlineY = metrics.first.baseline + 6.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, underlineY, tp.width, 3),
          const Radius.circular(3),
        ),
        Paint()..color = AppColors.primary,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _UnderlinePainter oldDelegate) =>
      oldDelegate.text != text || oldDelegate.style != style;
}
