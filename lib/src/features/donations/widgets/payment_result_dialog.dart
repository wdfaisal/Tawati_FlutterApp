import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum PaymentResultType { success, underReview }

Future<void> showPaymentResultDialog(
  BuildContext context, {
  required PaymentResultType type,
  String? title,
  String? subtitle,
  String? amountText,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => PaymentResultDialog(
      type: type,
      title: title,
      subtitle: subtitle,
      amountText: amountText,
    ),
  );
}

class PaymentResultDialog extends StatefulWidget {
  final PaymentResultType type;
  final String? title;
  final String? subtitle;
  final String? amountText;

  const PaymentResultDialog({
    super.key,
    required this.type,
    this.title,
    this.subtitle,
    this.amountText,
  });

  @override
  State<PaymentResultDialog> createState() => _PaymentResultDialogState();
}

class _PaymentResultDialogState extends State<PaymentResultDialog>
    with TickerProviderStateMixin {
  late final AnimationController _loop;
  late final AnimationController _draw;
  bool get _isSuccess => widget.type == PaymentResultType.success;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _draw = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _loop.dispose();
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ??
        (_isSuccess ? 'تم تأكيد تبرعك بنجاح' : 'عملية التبرع قيد المراجعة');
    final subtitle = widget.subtitle ??
        (_isSuccess
            ? 'شكراً لك على مساهمتك، سيظهر اسمك في سجل المساهمات.'
            : 'تم استلام طلبك بنجاح، وسيقوم فريق الإدارة بمراجعته وتأكيده خلال وقت قصير. ستصلك إشعارات فور تأكيد التبرع.');

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 190,
              child: _isSuccess
                  ? _buildSuccessGraphic()
                  : _buildReviewGraphic(),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            if (widget.amountText != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.amountText!,
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _isSuccess ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'حسناً',
                  style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessGraphic() {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _loop,
          builder: (context, child) => CustomPaint(
            size: const Size(double.infinity, double.infinity),
            painter: _BalloonBurstPainter(_loop.value, _balloonColors),
          ),
        ),
        AnimatedBuilder(
          animation: _loop,
          builder: (context, child) => Transform.scale(
            scale: 1 + math.sin(_loop.value * math.pi) * 0.06,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.12),
              ),
            ),
          ),
        ),
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2FBF71), AppColors.success],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x3322C55E),
                blurRadius: 22,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _draw,
            builder: (context, child) => CustomPaint(
              painter: _CheckmarkPainter(_draw.value),
              child: const SizedBox(width: 96, height: 96),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewGraphic() {
    return Center(
      child: AnimatedBuilder(
        animation: _loop,
        builder: (context, child) {
          final pulse = 1 + math.sin(_loop.value * math.pi * 2) * 0.05;
          return Transform.scale(
            scale: pulse,
            child: SizedBox(
              width: 148,
              height: 148,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 148,
                    height: 148,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      strokeCap: StrokeCap.round,
                      backgroundColor: AppColors.warning.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation(AppColors.warning),
                    ),
                  ),
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.warning.withValues(alpha: 0.12),
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      size: 44,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static const _balloonColors = [
    AppColors.primary,
    AppColors.success,
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;

  _CheckmarkPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(size.width * 0.24, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.70)
      ..lineTo(size.width * 0.78, size.height * 0.32);
    final metrics = path.computeMetrics().toList();
    for (final metric in metrics) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _BalloonBurstPainter extends CustomPainter {
  final double t;
  final List<Color> colors;

  _BalloonBurstPainter(this.t, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    const count = 12;
    for (var i = 0; i < count; i++) {
      final seed = i * 0.37;
      final phase = seed * 6.2831853;
      final speed = 0.22 + (seed % 1.0) * 0.45;
      final localT = (t * speed + (i % 5) * 0.11) % 1.0;
      final xBase = width * (0.10 + 0.80 * ((seed * 7.13) % 1.0));
      final sway = width * 0.06 * math.sin(phase + localT * 4.5);
      final x = xBase + sway;
      final y = height + 30 - localT * (height + 60);
      final radius = 7.0 + (seed % 1.0) * 5.0;
      final opacity = localT < 0.82 ? 1.0 : (1.0 - (localT - 0.82) / 0.18);
      final color = colors[i % colors.length];

      final bodyPaint = Paint()..color = color.withValues(alpha: opacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCircle(center: Offset(x, y), radius: radius),
          Radius.circular(radius * 0.55),
        ),
        bodyPaint,
      );
      final tail = Path()
        ..moveTo(x - radius * 0.45, y + radius * 0.75)
        ..lineTo(x + radius * 0.45, y + radius * 0.75)
        ..lineTo(x, y + radius * 1.35)
        ..close();
      canvas.drawPath(tail, bodyPaint);

      final stringPath = Path()
        ..moveTo(x, y + radius * 1.35)
        ..cubicTo(
          x + 2,
          y + radius * 2.0,
          x - 2,
          y + radius * 2.6,
          x + 1,
          y + radius * 3.2,
        );
      canvas.drawPath(
        stringPath,
        Paint()
          ..color = color.withValues(alpha: opacity * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      canvas.drawCircle(
        Offset(x - radius * 0.35, y - radius * 0.3),
        radius * 0.18,
        Paint()..color = Colors.white.withValues(alpha: opacity * 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BalloonBurstPainter oldDelegate) =>
      oldDelegate.t != t;
}
