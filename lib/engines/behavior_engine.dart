// lib/engines/behavior_engine.dart

import 'dart:math';
import 'package:rover_companion/models/perception.dart';
import 'package:rover_companion/models/memory_model.dart';
import 'package:rover_companion/models/rover_state.dart';

class BehaviorOutput {
  final MoveDirection direction;
  final int? servoAngle;
  final double intensity; // 0.0 - 1.0
  final EmotionalState emotion;
  final MainState nextMainState;
  final String? speechText;

  const BehaviorOutput({
    required this.direction,
    required this.emotion,
    required this.nextMainState,
    this.servoAngle,
    this.intensity = 1.0,
    this.speechText,
  });
}

class BehaviorEngine {
  static const double _turnThreshold = 40.0;
  static const double _strongTurnThreshold = 120.0;
  static const double _stopDistanceRatio = 0.3;

  // Servo scanning state
  int _scanAngle = 90;
  int _scanDirection = 1;
  static const int _scanMin = 60;
  static const int _scanMax = 120;
  static const int _scanStep = 15;

  BehaviorOutput produce({
    required RoverIntent intent,
    required PerceptionResult perception,
    required RoverMemory memory,
    required MainState currentState,
  }) {
    switch (intent) {
      case RoverIntent.idle:
        return _handleIdle();
      case RoverIntent.follow:
        return _handleFollow(perception, memory);
      case RoverIntent.greet:
        return _handleGreet(perception, memory);
      case RoverIntent.search:
        return _handleSearch(memory);
      case RoverIntent.lookAtTarget:
        return _handleLookAt(perception);
      case RoverIntent.stop:
        return _handleStop();
      case RoverIntent.manualDrive:
        // Manual drive is handled externally
        return BehaviorOutput(
          direction: MoveDirection.stop,
          emotion: EmotionalState.neutral,
          nextMainState: MainState.manual,
        );
    }
  }

  BehaviorOutput _handleIdle() {
    return const BehaviorOutput(
      direction: MoveDirection.stop,
      emotion: EmotionalState.neutral,
      nextMainState: MainState.idle,
    );
  }

  BehaviorOutput _handleFollow(PerceptionResult p, RoverMemory memory) {
    if (p.bbox == null) {
      return BehaviorOutput(
        direction: memory.lastMoveDirection ?? MoveDirection.stop,
        emotion: EmotionalState.curious,
        nextMainState: MainState.searching,
      );
    }

    final xOffset = p.xOffset;
    final dist = p.estimatedDistance;

    // Too close - stop
    if (dist == EstimatedDistance.near) {
      return const BehaviorOutput(
        direction: MoveDirection.stop,
        emotion: EmotionalState.focused,
        nextMainState: MainState.tracking,
      );
    }

    // Determine turn direction and intensity
    MoveDirection dir;
    double intensity;

    if (xOffset < -_strongTurnThreshold) {
      dir = MoveDirection.left;
      intensity = 1.0;
    } else if (xOffset < -_turnThreshold) {
      dir = MoveDirection.left;
      intensity = 0.5;
    } else if (xOffset > _strongTurnThreshold) {
      dir = MoveDirection.right;
      intensity = 1.0;
    } else if (xOffset > _turnThreshold) {
      dir = MoveDirection.right;
      intensity = 0.5;
    } else {
      // Centered - move forward
      dir = dist == EstimatedDistance.medium
          ? MoveDirection.stop
          : MoveDirection.forward;
      intensity = 0.7;
    }

    return BehaviorOutput(
      direction: dir,
      emotion: EmotionalState.focused,
      nextMainState: MainState.tracking,
      intensity: intensity,
    );
  }

  BehaviorOutput _handleGreet(PerceptionResult p, RoverMemory memory) {
    final isFirstMeet = !memory.knownFaces.contains(p.faceLabel);
    return BehaviorOutput(
      direction: MoveDirection.stop,
      emotion: EmotionalState.happy,
      nextMainState: MainState.interacting,
      servoAngle: 90,
      speechText: isFirstMeet
          ? "Hello! Nice to meet you!"
          : "Welcome back, ${p.faceLabel ?? 'friend'}!",
    );
  }

  BehaviorOutput _handleSearch(RoverMemory memory) {
    // Advance scan angle
    _scanAngle += _scanStep * _scanDirection;
    if (_scanAngle >= _scanMax || _scanAngle <= _scanMin) {
      _scanDirection *= -1;
      _scanAngle = _scanAngle.clamp(_scanMin, _scanMax);
    }

    // Rotate slightly while scanning
    final dir = _scanDirection > 0
        ? MoveDirection.right
        : MoveDirection.left;

    return BehaviorOutput(
      direction: dir,
      emotion: EmotionalState.confused,
      nextMainState: MainState.searching,
      servoAngle: _scanAngle,
      intensity: 0.3,
    );
  }

  BehaviorOutput _handleLookAt(PerceptionResult p) {
    // Just center and look without moving forward aggressively
    final xOffset = p.xOffset;
    MoveDirection dir;
    if (xOffset < -_turnThreshold) {
      dir = MoveDirection.left;
    } else if (xOffset > _turnThreshold) {
      dir = MoveDirection.right;
    } else {
      dir = MoveDirection.stop;
    }
    return BehaviorOutput(
      direction: dir,
      emotion: EmotionalState.curious,
      nextMainState: MainState.interacting,
      servoAngle: 90,
      intensity: 0.4,
    );
  }

  BehaviorOutput _handleStop() {
    return const BehaviorOutput(
      direction: MoveDirection.stop,
      emotion: EmotionalState.alert,
      nextMainState: MainState.error,
    );
  }
}
