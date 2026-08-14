import 'package:flutter/material.dart';
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
      image: 'assets/images/Splash_Screen_Image_1.jpg',
      icon: Icons.badge,
      title: 'تواتي... امتداد لجذورك',
      subtitle: 'بطاقتك الرقمية التي تربطك بشجرة عائلتك ومجتمع توتي، أينما كنت.',
    ),
    _OnboardingPageData(
      image: 'assets/images/Splash_Screen_Image_2.jpg',
      icon: Icons.volunteer_activism,
      title: 'ساهم في الخير',
      subtitle: 'اكتشف مبادرات التكافل وساهم بترك أثر حقيقي في حياة الآخرين.',
    ),
    _OnboardingPageData(
      image: 'assets/images/Splash_Screen_Image_3.jpg',
      icon: Icons.groups,
      title: 'كل خبر، كل مبادرة، في مكان واحد',
      subtitle: 'تابع أخبار أهلك ومناسباتهم، وشارك في المبادرات التي تصنع فرقًا في مجتمعك.',
    ),
  ];

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      setState(() => _currentPage++);
    } else {
      context.goNamed('login');
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
      child: Scaffold(
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height / 2 + 20,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.05),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Stack(
                  key: ValueKey('bg_$_currentPage'),
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: AppColors.primary),
                    Image.asset(
                      page.image,
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
                      errorBuilder: (_, __, ___) =>
                          Container(color: AppColors.primary),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.35),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _buildHeader(context),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.08),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildCard(context, page),
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < 0) {
                      _onNext();
                    } else if (details.primaryVelocity! > 0) {
                      _onPrevious();
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      key: const ValueKey('header_new'),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/splash_logo.png',
            height: 44,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.diamond, color: Colors.white, size: 44),
          ),
          const Spacer(),
          Material(
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => context.goNamed('login'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                child: Text(
                  'تخطي',
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, _OnboardingPageData page) {
    final isLast = _currentPage == _pages.length - 1;
    return FractionallySizedBox(
      heightFactor: 0.5,
      child: Container(
        key: ValueKey('card_$_currentPage'),
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(48)),
          boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, -4))],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 12, offset: Offset(0, 4))],
                  ),
                  child: Icon(page.icon, size: 40, color: AppColors.primary),
                ),
              ),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 120),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 100, height: 1, color: const Color(0xFFE5E7EB)),
                        const SizedBox(width: 14),
                        const Icon(Icons.eco, size: 20, color: AppColors.primary),
                        const SizedBox(width: 14),
                        Container(width: 100, height: 1, color: const Color(0xFFE5E7EB)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      page.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        page.subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'IBMPlexSansArabic',
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          height: 1.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        final isActive = i == _currentPage;
                        return GestureDetector(
                          onTap: () => setState(() => _currentPage = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.primary : const Color(0xFFD1D5DB),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).padding.bottom + 12,
              child: SizedBox(
                height: 104,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Positioned.fill(
                      child: const CustomPaint(painter: _CitySilhouettePainter()),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            elevation: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isLast ? 'ابدأ' : 'التالي',
                                style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_back, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final String image;
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardingPageData({
    required this.image,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _CitySilhouettePainter extends CustomPainter {
  const _CitySilhouettePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x26044465);
    final sx = size.width / 400;
    final sy = size.height / 100;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, size.height);

    void up(double x, double y) => path.lineTo(x * sx, size.height - y * sy);

    up(400, 80); up(380, 80); up(380, 60); up(360, 60); up(360, 90);
    up(340, 90); up(340, 70); up(320, 70); up(320, 85); up(280, 85);
    up(280, 50); up(250, 50); up(250, 75); up(220, 75); up(220, 40);
    up(190, 40); up(190, 80); up(160, 80); up(160, 30); up(130, 30);
    up(130, 70); up(100, 70); up(100, 60); up(70, 60); up(70, 85);
    up(40, 85); up(40, 65); up(10, 65); up(10, 90); up(0, 90);

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
