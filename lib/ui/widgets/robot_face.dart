// lib/ui/widgets/robot_face.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:rover_companion/models/rover_state.dart';

class RobotFace extends StatefulWidget {
  final EmotionalState emotion;
  final MainState mainState;
  final bool isConnected;

  const RobotFace({
    super.key,
    required this.emotion,
    required this.mainState,
    required this.isConnected,
  });

  @override
  State<RobotFace> createState() => _RobotFaceState();
}

class _RobotFaceState extends State<RobotFace>
    with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late AnimationController _expressionController;
  late AnimationController _idleController;
  late Animation<double> _blinkAnim;
  late Animation<double> _expressionAnim;
  late Animation<double> _idleAnim;

  EmotionalState _currentEmotion = EmotionalState.neutral;
  EmotionalState _targetEmotion = EmotionalState.neutral;

  @override
  void initState() {
    super.initState();

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _blinkAnim = Tween<double>(begin: 1.0, end: 0.05).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    _expressionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _expressionAnim = CurvedAnimation(
      parent: _expressionController,
      curve: Curves.easeInOut,
    );

    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _idleAnim = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );

    _startBlinking();
  }

  void _startBlinking() {
    Future.delayed(Duration(seconds: 2 + Random().nextInt(4)), () async {
      if (!mounted) return;
      await _blinkController.forward();
      await _blinkController.reverse();
      _startBlinking();
    });
  }

  @override
  void didUpdateWidget(RobotFace old) {
    super.didUpdateWidget(old);
    if (old.emotion != widget.emotion) {
      _currentEmotion = old.emotion;
      _targetEmotion = widget.emotion;
      _expressionController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _expressionController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _blinkAnim,
        _expressionAnim,
        _idleAnim,
      ]),
      builder: (context, _) {
        return CustomPaint(
          painter: _FacePainter(
            emotion: widget.emotion,
            blinkProgress: _blinkAnim.value,
            transitionProgress: _expressionAnim.value,
            idleWave: _idleAnim.value,
            isConnected: widget.isConnected,
            mainState: widget.mainState,
          ),
          size: const Size(double.infinity, double.infinity),
        );
      },
    );
  }
}

class _FacePainter extends CustomPainter {
  final EmotionalState emotion;
  final double blinkProgress;
  final double transitionProgress;
  final double idleWave;
  final bool isConnected;
  final MainState mainState;

  _FacePainter({
    required this.emotion,
    required this.blinkProgress,
    required this.transitionProgress,
    required this.idleWave,
    required this.isConnected,
    required this.mainState,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final faceRadius = min(size.width, size.height) * 0.38;

    // Background glow
    final glowColor = _getGlowColor();
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          glowColor.withOpacity(0.15),
          glowColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(cx, cy),
        radius: faceRadius * 1.8,
      ));
    canvas.drawCircle(Offset(cx, cy), faceRadius * 1.8, glowPaint);

    // Face circle
    final facePaint = Paint()
      ..color = const Color(0xFF0D1117)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), faceRadius, facePaint);

    final borderPaint = Paint()
      ..color = glowColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(cx, cy), faceRadius, borderPaint);

    // Eyes
    _drawEyes(canvas, cx, cy, faceRadius);

    // Mouth
    _drawMouth(canvas, cx, cy, faceRadius);

    // Status indicator
    _drawStatusDot(canvas, cx, cy, faceRadius);
  }

  Color _getGlowColor() {
    switch (emotion) {
      case EmotionalState.happy:
        return const Color(0xFF00FF88);
      case EmotionalState.curious:
        return const Color(0xFF00CFFF);
      case EmotionalState.focused:
        return const Color(0xFF4080FF);
      case EmotionalState.alert:
        return const Color(0xFFFFAA00);
      case EmotionalState.confused:
        return const Color(0xFFFF6080);
      case EmotionalState.sleepy:
        return const Color(0xFF6040A0);
      case EmotionalState.neutral:
        return const Color(0xFF40A0FF);
    }
  }

  void _drawEyes(Canvas canvas, double cx, double cy, double r) {
    final eyeY = cy - r * 0.18;
    final eyeSpacing = r * 0.35;
    final eyeW = r * 0.28;
    final eyeH = r * 0.22 * blinkProgress;

    final eyePaint = Paint()
      ..color = _getGlowColor()
      ..style = PaintingStyle.fill;

    final eyeGlow = Paint()
      ..color = _getGlowColor().withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    for (final sign in [-1.0, 1.0]) {
      final ex = cx + sign * eyeSpacing;

      // Glow
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(ex, eyeY),
          width: eyeW * 1.4,
          height: eyeH * 1.4 + 4,
        ),
        eyeGlow,
      );

      // Eye shape based on emotion
      switch (emotion) {
        case EmotionalState.focused:
          // Sharp angular eyes
          final path = Path();
          path.moveTo(ex - eyeW / 2, eyeY + eyeH / 2);
          path.lineTo(ex, eyeY - eyeH / 2);
          path.lineTo(ex + eyeW / 2, eyeY + eyeH / 2);
          path.close();
          canvas.drawPath(path, eyePaint);
          break;
        case EmotionalState.happy:
          // Arc / happy eyes
          final rect = Rect.fromCenter(
            center: Offset(ex, eyeY + eyeH * 0.2),
            width: eyeW,
            height: eyeH,
          );
          canvas.drawArc(rect, pi, pi, true, eyePaint);
          break;
        case EmotionalState.sleepy:
          // Half-closed eyes
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(ex, eyeY + eyeH * 0.3),
              width: eyeW,
              height: eyeH * 0.5,
            ),
            eyePaint,
          );
          break;
        case EmotionalState.confused:
          // Slightly askew
          canvas.save();
          canvas.translate(ex, eyeY);
          canvas.rotate(sign * 0.2);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: eyeW,
              height: eyeH,
            ),
            eyePaint,
          );
          canvas.restore();
          break;
        default:
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(ex, eyeY),
              width: eyeW,
              height: eyeH,
            ),
            eyePaint,
          );
      }
    }
  }

  void _drawMouth(Canvas canvas, double cx, double cy, double r) {
    final mouthY = cy + r * 0.28;
    final mouthW = r * 0.5;

    final mouthPaint = Paint()
      ..color = _getGlowColor()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final path = Path();

    switch (emotion) {
      case EmotionalState.happy:
        path.moveTo(cx - mouthW / 2, mouthY - r * 0.04);
        path.quadraticBezierTo(
          cx, mouthY + r * 0.12,
          cx + mouthW / 2, mouthY - r * 0.04,
        );
        break;
      case EmotionalState.confused:
        // Wavy line
        final step = mouthW / 4;
        path.moveTo(cx - mouthW / 2, mouthY);
        for (int i = 0; i < 4; i++) {
          path.relativeQuadraticBezierTo(
            step / 2, (i % 2 == 0 ? -1 : 1) * r * 0.05,
            step, 0,
          );
        }
        break;
      case EmotionalState.alert:
        // Open 'O' mouth
        canvas.drawCircle(
          Offset(cx, mouthY),
          r * 0.08,
          mouthPaint..style = PaintingStyle.stroke,
        );
        return;
      case EmotionalState.sleepy:
        // Flat line
        path.moveTo(cx - mouthW / 3, mouthY);
        path.lineTo(cx + mouthW / 3, mouthY);
        break;
      case EmotionalState.focused:
        // Tight line
        path.moveTo(cx - mouthW * 0.3, mouthY);
        path.lineTo(cx + mouthW * 0.3, mouthY);
        break;
      default:
        // Slight smile
        path.moveTo(cx - mouthW / 2, mouthY);
        path.quadraticBezierTo(
          cx, mouthY + r * 0.05,
          cx + mouthW / 2, mouthY,
        );
    }

    canvas.drawPath(path, mouthPaint);
  }

  void _drawStatusDot(Canvas canvas, double cx, double cy, double r) {
    final dotColor = isConnected ? const Color(0xFF00FF88) : const Color(0xFFFF3355);
    final dotPaint = Paint()
      ..color = dotColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(cx + r * 0.65, cy - r * 0.65), 5, dotPaint);
    canvas.drawCircle(
      Offset(cx + r * 0.65, cy - r * 0.65),
      4,
      Paint()..color = dotColor,
    );
  }

  @override
  bool shouldRepaint(_FacePainter old) => true;
}
