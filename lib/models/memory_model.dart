// lib/models/memory_model.dart

import 'package:rover_companion/models/perception.dart';
import 'package:rover_companion/models/rover_state.dart';

class RoverMemory {
  // Target tracking
  double? lastTargetX;
  double? lastTargetY;
  DateTime? targetLastSeenAt;
  MoveDirection? lastMoveDirection;

  // Face
  String? lastKnownFaceId;
  List<String> knownFaces = [];

  // Interaction
  List<String> interactionHistory = [];
  int totalInteractions = 0;

  // Confidence smoothing
  final List<double> _confidenceBuffer = [];
  static const int _confidenceBufferSize = 5;

  // Mode
  MainState lastMainState = MainState.idle;
  EmotionalState lastEmotionalState = EmotionalState.neutral;

  // Command tracking
  MoveDirection? lastCommandSent;
  DateTime? lastCommandAt;

  void updateFromPerception(PerceptionResult p) {
    if (p.personDetected && p.bbox != null) {
      lastTargetX = p.bbox!.centerX;
      lastTargetY = p.bbox!.centerY;
      targetLastSeenAt = DateTime.now();
    }
    if (p.faceDetected && p.faceLabel != null) {
      lastKnownFaceId = p.faceLabel;
      if (p.faceKnown && !knownFaces.contains(p.faceLabel)) {
        knownFaces.add(p.faceLabel!);
      }
    }
    _addConfidence(p.confidence);
  }

  void _addConfidence(double c) {
    _confidenceBuffer.add(c);
    if (_confidenceBuffer.length > _confidenceBufferSize) {
      _confidenceBuffer.removeAt(0);
    }
  }

  double get smoothedConfidence {
    if (_confidenceBuffer.isEmpty) return 0;
    return _confidenceBuffer.reduce((a, b) => a + b) / _confidenceBuffer.length;
  }

  bool get targetRecentlySeen {
    if (targetLastSeenAt == null) return false;
    return DateTime.now().difference(targetLastSeenAt!).inSeconds < 3;
  }

  bool get targetLost {
    if (targetLastSeenAt == null) return true;
    return DateTime.now().difference(targetLastSeenAt!).inSeconds > 3;
  }

  bool get targetTimedOut {
    if (targetLastSeenAt == null) return true;
    return DateTime.now().difference(targetLastSeenAt!).inSeconds > 10;
  }

  void recordCommand(MoveDirection dir) {
    lastCommandSent = dir;
    lastCommandAt = DateTime.now();
    lastMoveDirection = dir;
  }

  void recordInteraction(String event) {
    interactionHistory.add(event);
    totalInteractions++;
    if (interactionHistory.length > 50) {
      interactionHistory.removeAt(0);
    }
  }
}
