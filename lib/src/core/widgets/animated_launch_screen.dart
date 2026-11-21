import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AnimatedLaunchScreen extends StatefulWidget {
  final bool ready;
  final VoidCallback onFinished;

  const AnimatedLaunchScreen({
    super.key,
    required this.ready,
    required this.onFinished,
  });

  @override
  State<AnimatedLaunchScreen> createState() => _AnimatedLaunchScreenState();
}

class _AnimatedLaunchScreenState extends State<AnimatedLaunchScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _exitController;
  late final Animation<double> _reveal;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _screenFade;
  bool _introDone = false;
  bool _exitStarted = false;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _reveal = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.85, curve: Curves.easeInOutCubic),
    );
    _fade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.20, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    _screenFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInOut,
      ),
    );

    _introController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _introDone = true;
        _maybeExit();
      }
    });
    _exitController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFinished();
      }
    });

    _introController.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedLaunchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ready && !oldWidget.ready) {
      _maybeExit();
    }
  }

  void _maybeExit() {
    if (!_introDone || !widget.ready || _exitStarted) return;
    _exitStarted = true;
    _exitController.forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_introController, _exitController]),
      builder: (context, child) {
        return Opacity(
          opacity: _screenFade.value,
          child: child,
        );
      },
      child: Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: AnimatedBuilder(
          animation: _introController,
          builder: (context, _) {
            return Opacity(
              opacity: _fade.value,
              child: Transform.scale(
                scale: _scale.value,
                child: SizedBox(
                  width: 220,
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      final p = _reveal.value.clamp(0.0, 1.0);
                      if (p >= 1.0) {
                        return const LinearGradient(
                          colors: [Colors.white, Colors.white],
                        ).createShader(bounds);
                      }
                      final edge = (p + 0.06).clamp(p, 1.0);
                      final stops = <double>[0.0, p, edge, 1.0];
                      for (var i = 1; i < stops.length; i++) {
                        if (stops[i] < stops[i - 1]) stops[i] = stops[i - 1];
                      }
                      return LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: const [
                          Colors.white,
                          Colors.white,
                          Colors.transparent,
                          Colors.transparent,
                        ],
                        stops: stops,
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: SvgPicture.asset(
                      'assets/logo/tawati-primary.svg',
                      width: 220,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
