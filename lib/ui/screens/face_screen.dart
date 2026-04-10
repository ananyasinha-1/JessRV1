// lib/ui/screens/face_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rover_companion/engines/state_manager.dart';
import 'package:rover_companion/models/rover_state.dart';
import 'package:rover_companion/ui/widgets/robot_face.dart';
import 'package:rover_companion/ui/widgets/status_hud.dart';

class FaceScreen extends StatelessWidget {
  const FaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sm = context.watch<RoverStateManager>();

    return Scaffold(
      backgroundColor: const Color(0xFF070B12),
      body: Stack(
        children: [
          // Ambient background grid
          const _GridBackground(),

          // Central face
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 0.8,
              child: RobotFace(
                emotion: sm.emotionalState,
                mainState: sm.mainState,
                isConnected: sm.isConnected,
              ),
            ),
          ),

          // Top status bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  StatusHUD(sm: sm),
                  const Spacer(),
                  _VoiceButton(sm: sm),
                ],
              ),
            ),
          ),

          // Bottom control bar
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mode chips
                    _ModeSelector(sm: sm),
                    const SizedBox(height: 20),

                    // Navigation to control screen
                    _BottomActions(sm: sm),
                  ],
                ),
              ),
            ),
          ),

          // Perception overlay dot
          if (sm.lastPerception.personDetected && sm.lastPerception.bbox != null)
            _PerceptionIndicator(sm: sm),
        ],
      ),
    );
  }
}

class _GridBackground extends StatelessWidget {
  const _GridBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _GridPainter(),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0D2040).withOpacity(0.4)
      ..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _VoiceButton extends StatelessWidget {
  final RoverStateManager sm;
  const _VoiceButton({required this.sm});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: sm.toggleListening,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: sm.isListening
              ? const Color(0xFFFF4488).withOpacity(0.2)
              : Colors.black.withOpacity(0.4),
          border: Border.all(
            color: sm.isListening
                ? const Color(0xFFFF4488)
                : Colors.white.withOpacity(0.15),
            width: 1.5,
          ),
        ),
        child: Icon(
          sm.isListening ? Icons.mic : Icons.mic_none,
          color: sm.isListening
              ? const Color(0xFFFF4488)
              : Colors.white.withOpacity(0.5),
          size: 22,
        ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final RoverStateManager sm;
  const _ModeSelector({required this.sm});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ModeChip(
          label: 'AUTO',
          active: sm.mainState == MainState.tracking ||
              sm.mainState == MainState.interacting ||
              sm.mainState == MainState.searching,
          color: const Color(0xFF00CFFF),
          onTap: sm.setAutoMode,
        ),
        const SizedBox(width: 12),
        _ModeChip(
          label: 'MANUAL',
          active: sm.mainState == MainState.manual,
          color: const Color(0xFFFFAA00),
          onTap: sm.setManualMode,
        ),
        const SizedBox(width: 12),
        _ModeChip(
          label: 'IDLE',
          active: sm.mainState == MainState.idle,
          color: const Color(0xFF7080A0),
          onTap: sm.setIdleMode,
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: active ? color.withOpacity(0.18) : Colors.black.withOpacity(0.3),
          border: Border.all(
            color: active ? color : color.withOpacity(0.25),
            width: 1.5,
          ),
          boxShadow: active
              ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10)]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: active ? color : color.withOpacity(0.4),
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final RoverStateManager sm;
  const _BottomActions({required this.sm});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionButton(
          icon: Icons.videocam_rounded,
          label: 'DRIVE',
          onTap: () => Navigator.pushNamed(context, '/control'),
        ),
        const SizedBox(width: 20),
        _ActionButton(
          icon: Icons.settings,
          label: 'CONFIG',
          onTap: () => Navigator.pushNamed(context, '/settings'),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFF111825),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF00CFFF), size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFF8090B0),
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerceptionIndicator extends StatelessWidget {
  final RoverStateManager sm;
  const _PerceptionIndicator({required this.sm});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.12,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF00CFFF).withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF00CFFF).withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person, color: Color(0xFF00CFFF), size: 14),
            const SizedBox(width: 6),
            Text(
              '${(sm.lastPerception.confidence * 100).toInt()}%',
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFF00CFFF),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
