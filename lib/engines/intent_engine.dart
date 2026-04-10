// lib/engines/intent_engine.dart

import 'package:rover_companion/models/perception.dart';
import 'package:rover_companion/models/memory_model.dart';
import 'package:rover_companion/models/rover_state.dart';

class IntentEngine {
  RoverIntent decide({
    required PerceptionResult perception,
    required RoverMemory memory,
    required MainState currentState,
  }) {
    // Priority 1: Manual mode always wins
    if (currentState == MainState.manual) {
      return RoverIntent.manualDrive;
    }

    // Priority 2: Error state
    if (currentState == MainState.error) {
      return RoverIntent.stop;
    }

    // Priority 3: Known face interaction
    if (perception.faceDetected && perception.faceKnown) {
      return RoverIntent.greet;
    }

    // Priority 4: Unknown face or person -> track
    if (perception.personDetected && currentState != MainState.idle) {
      if (perception.faceDetected) {
        return RoverIntent.lookAtTarget;
      }
      return RoverIntent.follow;
    }

    // Priority 5: Target recently seen but lost -> search
    if (memory.targetRecentlySeen && !perception.personDetected) {
      if (!memory.targetTimedOut) {
        return RoverIntent.search;
      }
    }

    // Priority 6: Idle
    return RoverIntent.idle;
  }
}
