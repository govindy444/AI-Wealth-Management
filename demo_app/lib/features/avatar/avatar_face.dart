import 'dart:math' as math;

import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:flutter/material.dart';


class AvatarFace extends StatefulWidget {
  const AvatarFace({
    super.key,
    required this.expression,
    required this.speaking,
    required this.accent,
    this.size = 200,
  });

  final AvatarExpression expression;
  final bool speaking;
  final Color accent;
  final double size;

  @override
  State<AvatarFace> createState() => _AvatarFaceState();
}

class _AvatarFaceState extends State<AvatarFace>
    with TickerProviderStateMixin {
  late final AnimationController _blink;
  late final AnimationController _mouth;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _mouth = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    if (widget.speaking) _mouth.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(AvatarFace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.speaking && !_mouth.isAnimating) {
      _mouth.repeat(reverse: true);
    } else if (!widget.speaking && _mouth.isAnimating) {
      _mouth.stop();
      _mouth.value = 0;
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    _mouth.dispose();
    super.dispose();
  }

  double get _eyeOpen {
    final t = _blink.value;
    if (t < 0.92) return 1;
    final phase = (t - 0.92) / 0.08; // 0→1 across the blink window
    return (math.cos(phase * 2 * math.pi) + 1) / 2; // 1→0→1
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_blink, _mouth]),
      builder: (context, _) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _FacePainter(
            expression: widget.expression,
            accent: widget.accent,
            eyeOpen: _eyeOpen,
            mouthOpen: widget.speaking ? _mouth.value : 0,
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
        );
      },
    );
  }
}

class _FacePainter extends CustomPainter {
  _FacePainter({
    required this.expression,
    required this.accent,
    required this.eyeOpen,
    required this.mouthOpen,
    required this.isDark,
  });

  final AvatarExpression expression;
  final Color accent;
  final double eyeOpen;
  final double mouthOpen;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    final headPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(accent, Colors.white, isDark ? 0.05 : 0.35)!,
          accent,
        ],
        stops: const [0.2, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, headPaint);

    final featurePaint = Paint()..color = Colors.white;
    final darkFeature = Paint()..color = const Color(0xFF1A1A2E);

    // Eyes.
    final eyeY = c.dy - r * 0.12;
    final eyeDx = r * 0.42;
    final eyeW = r * 0.30;
    final eyeH = r * 0.34 * eyeOpen.clamp(0.06, 1.0);
    for (final sign in [-1, 1]) {
      final center = Offset(c.dx + sign * eyeDx, eyeY);
      canvas.drawOval(
        Rect.fromCenter(center: center, width: eyeW, height: r * 0.34),
        featurePaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: eyeW * 0.5,
          height: eyeH * 0.55,
        ),
        darkFeature,
      );
    }

    final browPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = r * 0.07
      ..strokeCap = StrokeCap.round;
    final browY = eyeY - r * 0.30;
    for (final sign in [-1, 1]) {
      final cx = c.dx + sign * eyeDx;
      late Offset a, b;
      switch (expression) {
        case AvatarExpression.concerned:
          a = Offset(cx - sign * eyeW * 0.5, browY + r * 0.06);
          b = Offset(cx + sign * eyeW * 0.5, browY - r * 0.04);
        case AvatarExpression.thinking:
          // One raised brow.
          final lift = sign < 0 ? -r * 0.06 : 0.0;
          a = Offset(cx - eyeW * 0.5, browY + lift);
          b = Offset(cx + eyeW * 0.5, browY + lift);
        case AvatarExpression.happy:
          a = Offset(cx - eyeW * 0.5, browY - r * 0.02);
          b = Offset(cx + eyeW * 0.5, browY - r * 0.05);
        case AvatarExpression.neutral:
          a = Offset(cx - eyeW * 0.5, browY);
          b = Offset(cx + eyeW * 0.5, browY);
      }
      canvas.drawLine(a, b, browPaint);
    }

    // Mouth: a curve whose shape follows the expression, opening while speaking.
    final mouthY = c.dy + r * 0.45;
    final mouthW = r * 0.7;
    final open = mouthOpen * r * 0.28;
    final curve = switch (expression) {
      AvatarExpression.happy => r * 0.22,
      AvatarExpression.concerned => -r * 0.18,
      AvatarExpression.thinking => r * 0.04,
      AvatarExpression.neutral => r * 0.06,
    };

    final mouthPaint = Paint()..color = const Color(0xFF1A1A2E);
    final path = Path()
      ..moveTo(c.dx - mouthW / 2, mouthY)
      ..quadraticBezierTo(c.dx, mouthY + curve, c.dx + mouthW / 2, mouthY)
      ..quadraticBezierTo(
        c.dx,
        mouthY + curve + open + (open > 0 ? r * 0.12 : 0),
        c.dx - mouthW / 2,
        mouthY,
      )
      ..close();
    canvas.drawPath(path, mouthPaint);
  }

  @override
  bool shouldRepaint(_FacePainter old) =>
      old.expression != expression ||
      old.eyeOpen != eyeOpen ||
      old.mouthOpen != mouthOpen ||
      old.accent != accent ||
      old.isDark != isDark;
}
