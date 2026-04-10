// lib/models/rover_state.dart

enum MainState {
  idle,
  manual,
  tracking,
  interacting,
  searching,
  error,
}

enum EmotionalState {
  neutral,
  curious,
  happy,
  focused,
  confused,
  alert,
  sleepy,
}

enum RoverIntent {
  idle,
  follow,
  greet,
  search,
  lookAtTarget,
  stop,
  manualDrive,
}

enum MoveDirection {
  forward,
  backward,
  left,
  right,
  stop,
}

extension MainStateLabel on MainState {
  String get label {
    switch (this) {
      case MainState.idle:
        return 'IDLE';
      case MainState.manual:
        return 'MANUAL';
      case MainState.tracking:
        return 'TRACKING';
      case MainState.interacting:
        return 'INTERACTING';
      case MainState.searching:
        return 'SEARCHING';
      case MainState.error:
        return 'ERROR';
    }
  }
}

extension EmotionalStateLabel on EmotionalState {
  String get emoji {
    switch (this) {
      case EmotionalState.neutral:
        return '😐';
      case EmotionalState.curious:
        return '🤔';
      case EmotionalState.happy:
        return '😄';
      case EmotionalState.focused:
        return '🎯';
      case EmotionalState.confused:
        return '😕';
      case EmotionalState.alert:
        return '⚡';
      case EmotionalState.sleepy:
        return '😴';
    }
  }
}
