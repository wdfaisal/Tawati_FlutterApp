import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _kBgDark = Color(0xFF0F172A); // slate-900
const _kOrange = Color(0xFFF97316); // orange-500
const _kSlate700 = Color(0xFF334155);
const _kSlate400 = Color(0xFF94A3B8);

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
      line1: 'منصة تواتي للخدمة',
      line2: 'المجتمعية',
      subtitle: 'ساهم في تنمية مجتمعك وكن جزءاً من مبادرات توتي الهادفة التي تجمعنا جميعاً كن جزء من "توتي عالم جميل" .',
    ),
    _OnboardingPageData(
      image: 'assets/images/onboarding_bg_2.png',
      line1: 'هوية تواتي ',
      line2: 'الرقمية',
      subtitle: ' لأننا نعتز بهويتنا التواتيه وثقناها رقميا . وثق بياناتك واحصل على هوية تواتي الرقمية .',
    ),
    _OnboardingPageData(
      image: 'assets/images/onboarding_bg_3.png',
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
        backgroundColor: _kBgDark,
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
            duration: const Duration(milliseconds: 500),
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
    );
  }

  Widget _buildPage(BuildContext context, _OnboardingPageData page) {
    return Stack(
      key: ValueKey('page_$_currentPage'),
      fit: StackFit.expand,
      children: [
        Image.asset(
          page.image,
          fit: BoxFit.cover,
          opacity: const AlwaysStoppedAnimation(0.8),
          errorBuilder: (_, _, _) => const ColoredBox(color: _kBgDark),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x000F172A),
                Color(0xE60F172A),
                _kBgDark,
              ],
              stops: [0.0, 0.7, 1.0],
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              _buildTopNav(context),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(40, 0, 40, 48),
                                child: _buildContent(context, page),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopNav(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        children: [
          Image.asset(
            'assets/images/splash_logo.png',
            height: 56,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox(width: 56, height: 56),
          ),
          const Spacer(),
          if (_isLast)
            const SizedBox(width: 40)
          else
            TextButton(
              onPressed: () => context.goNamed('login'),
              style: TextButton.styleFrom(
                foregroundColor: _kSlate400,
                padding: const EdgeInsets.symmetric(vertical: 4),
              ),
              child: const Text(
                'تخطي',
                style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, _OnboardingPageData page) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 4,
          decoration: BoxDecoration(color: _kOrange, borderRadius: BorderRadius.circular(999)),
        ),
        const SizedBox(height: 16),
        Text(
          page.line1,
          style: const TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        _UnderlinedWord(text: page.line2, fontSize: 36),
        const SizedBox(height: 16),
        Text(
          page.subtitle,
          style: const TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontSize: 18,
            fontWeight: FontWeight.w300,
            color: _kSlate400,
            height: 1.625,
          ),
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildDots(),
            _buildActionButton(),
          ],
        ),
      ],
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
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: isActive ? 40 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? _kOrange : _kSlate700,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }

  Widget _buildActionButton() {
    return Material(
      color: _isLast ? _kOrange : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: _isLast ? BorderSide.none : const BorderSide(color: Colors.white, width: 1.5),
      ),
      shadowColor: _isLast ? _kOrange.withValues(alpha: 0.25) : Colors.transparent,
      elevation: _isLast ? 10 : 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _onNext,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: _isLast ? 32 : 24, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isLast ? 'ابدأ الآن' : 'التالي',
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                _isLast ? Icons.check : Icons.arrow_back,
                size: 16,
                color: Colors.white,
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
  final String line1;
  final String line2;
  final String subtitle;

  const _OnboardingPageData({
    required this.image,
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
      color: _kOrange,
      height: 1.2,
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
    tp.paint(canvas, Offset.zero);
    final metrics = tp.computeLineMetrics();
    if (metrics.isNotEmpty) {
      final underlineY = metrics.first.baseline + 8.0;
      canvas.drawRect(
        Rect.fromLTWH(0, underlineY, tp.width, 2),
        Paint()..color = _kOrange,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _UnderlinePainter oldDelegate) =>
      oldDelegate.text != text || oldDelegate.style != style;
}
