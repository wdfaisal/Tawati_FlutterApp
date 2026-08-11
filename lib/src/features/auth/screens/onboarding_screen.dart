import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPageData(
      image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCq2C_f_ZeAthXLMPYt1ZW9NKFQhAcdLkK2vU3f0pibTKM9lcOYyjJr4WTsHTlgCrw_aNHggPBZJ7Hlu54yt1KQ7-oKhiSfAkxg19XHRH5F0uVxaU-ZVdyi-Bv7s1Ut1ntf0k3PAMixSG4HmSpmljJ3XYV24QIMyPX_rfvjpM0hqQs5tNHlVyQry88SjeuMwReqWg4hvqEdWJL0nL6rwZKzCZVyGgxowxHNucK9138ntjab_SLzAU5G5GXWDM1v1eP9h8voTAoQD_U',
      title: 'تواتي... امتداد لجذورك',
      subtitle: 'بطاقتك الرقمية التي تربطك بشجرة عائلتك ومجتمع توتي، أينما كنت.',
    ),
    _OnboardingPageData(
      image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCiCmN00fHIIVvUE9qbDlBQgAKu7MfK_oltoUrp3qSTMl5zgkLG0wiriYeRRtiywTbmEUhMLbrqPRkWYzMRXCXU4HgX4_pjFfLB_i86DodlvH7SGTeBh2KKU1wp0V5Ijw4VWQr7zTcc9V-Ibe8ToUta9RQiJA9lDsbhJs3MOhOBKJYY3G2c-JhpoGmtcCxUx9p_LN0L-61MTCEGslWfPyMBV4XJz-sr2RMKSB29y6gRyXxB2YQ6ihRyUz0O-jWfAPGKPru3q1luvQc',
      title: 'يدًا بيد، كما تعلّمنا النفير',
      subtitle: 'ساهم في صناديق الدعم المجتمعي، وتابع كل تبرع بشفافية كاملة حتى يصل لمستحقّه.',
    ),
    _OnboardingPageData(
      image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCiCmN00fHIIVvUE9qbDlBQgAKu7MfK_oltoUrp3qSTMl5zgkLG0wiriYeRRtiywTbmEUhMLbrqPRkWYzMRXCXU4HgX4_pjFfLB_i86DodlvH7SGTeBh2KKU1wp0V5Ijw4VWQr7zTcc9V-Ibe8ToUta9RQiJA9lDsbhJs3MOhOBKJYY3G2c-JhpoGmtcCxUx9p_LN0L-61MTCEGslWfPyMBV4XJz-sr2RMKSB29y6gRyXxB2YQ6ihRyUz0O-jWfAPGKPru3q1luvQc',
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
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: Stack(
                key: ValueKey(_currentPage),
                children: [
                  Positioned.fill(
                    child: Image.network(
                      page.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0D9488)),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.2),
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_currentPage == 0)
                    Image.asset('assets/images/Tawati-logo.png', width: 80, height: 80)
                  else
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white.withOpacity(0.85), size: 28),
                      onPressed: _onPrevious,
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.goNamed('login'),
                    child: Text(
                      'تخطي',
                      style: TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, -5))],
                ),
                padding: EdgeInsets.only(
                  left: 32,
                  right: 32,
                  top: 40,
                  bottom: MediaQuery.of(context).padding.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        final isActive = i == _currentPage;
                        return GestureDetector(
                          onTap: () => setState(() => _currentPage = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 32 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFF0D9488) : const Color(0xFFD4D4D4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.15),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        key: ValueKey('text_$_currentPage'),
                        children: [
                          Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'IBMPlexSansArabic',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF171717),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            page.subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'IBMPlexSansArabic',
                              fontSize: 15,
                              color: Color(0xFF737373),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                          shadowColor: const Color(0xFF0D9488).withOpacity(0.3),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == _pages.length - 1 ? 'ابدأ الآن' : 'التالي',
                              style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_back, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'خطوة ${_currentPage + 1} من ${_pages.length}',
                      style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: Color(0xFFA3A3A3)),
                    ),
                  ],
                ),
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
}

class _OnboardingPageData {
  final String image;
  final String title;
  final String subtitle;

  const _OnboardingPageData({
    required this.image,
    required this.title,
    required this.subtitle,
  });
}
