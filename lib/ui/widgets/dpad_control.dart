// lib/ui/widgets/dpad_control.dart

import 'package:flutter/material.dart';
import 'package:rover_companion/models/rover_state.dart';

class DPadControl extends StatefulWidget {
  final ValueChanged<MoveDirection> onCommand;
  final bool enabled;

  const DPadControl({
    super.key,
    required this.onCommand,
    this.enabled = true,
  });

  @override
  State<DPadControl> createState() => _DPadControlState();
}

class _DPadControlState extends State<DPadControl> {
  MoveDirection? _pressed;

  void _press(MoveDirection dir) {
    setState(() => _pressed = dir);
    widget.onCommand(dir);
  }

  void _release() {
    setState(() => _pressed = null);
    widget.onCommand(MoveDirection.stop);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.3),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          // Forward
          Positioned(
            top: 10,
            child: _DirButton(
              icon: Icons.keyboard_arrow_up_rounded,
              direction: MoveDirection.forward,
              isPressed: _pressed == MoveDirection.forward,
              onPress: _press,
              onRelease: _release,
              enabled: widget.enabled,
            ),
          ),
          // Backward
          Positioned(
            bottom: 10,
            child: _DirButton(
              icon: Icons.keyboard_arrow_down_rounded,
              direction: MoveDirection.backward,
              isPressed: _pressed == MoveDirection.backward,
              onPress: _press,
              onRelease: _release,
              enabled: widget.enabled,
            ),
          ),
          // Left
          Positioned(
            left: 10,
            child: _DirButton(
              icon: Icons.keyboard_arrow_left_rounded,
              direction: MoveDirection.left,
              isPressed: _pressed == MoveDirection.left,
              onPress: _press,
              onRelease: _release,
              enabled: widget.enabled,
            ),
          ),
          // Right
          Positioned(
            right: 10,
            child: _DirButton(
              icon: Icons.keyboard_arrow_right_rounded,
              direction: MoveDirection.right,
              isPressed: _pressed == MoveDirection.right,
              onPress: _press,
              onRelease: _release,
              enabled: widget.enabled,
            ),
          ),
          // Center stop button
          GestureDetector(
            onTap: () => widget.onCommand(MoveDirection.stop),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A1F2E),
                border: Border.all(
                  color: const Color(0xFFFF3355).withOpacity(0.6),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.stop_rounded,
                color: Color(0xFFFF3355),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirButton extends StatelessWidget {
  final IconData icon;
  final MoveDirection direction;
  final bool isPressed;
  final ValueChanged<MoveDirection> onPress;
  final VoidCallback onRelease;
  final bool enabled;

  const _DirButton({
    required this.icon,
    required this.direction,
    required this.isPressed,
    required this.onPress,
    required this.onRelease,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF00CFFF);
    return GestureDetector(
      onTapDown: enabled ? (_) => onPress(direction) : null,
      onTapUp: enabled ? (_) => onRelease() : null,
      onTapCancel: enabled ? () => onRelease() : null,
      onLongPressStart: enabled ? (_) => onPress(direction) : null,
      onLongPressEnd: enabled ? (_) => onRelease() : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isPressed
              ? accent.withOpacity(0.25)
              : const Color(0xFF1A1F2E),
          border: Border.all(
            color: isPressed ? accent : accent.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: isPressed
              ? [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 12)]
              : [],
        ),
        child: Icon(
          icon,
          color: isPressed ? accent : accent.withOpacity(0.6),
          size: 28,
        ),
      ),
    );
  }
}
