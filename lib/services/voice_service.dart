// lib/services/voice_service.dart

import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'package:rover_companion/models/rover_state.dart';

class VoiceCommandResult {
  final MoveDirection? direction;
  final MainState? targetMode;
  final String? rawCommand;
  final String? servoCommand; // 'up', 'down', 'center'

  VoiceCommandResult({
    this.direction,
    this.targetMode,
    this.rawCommand,
    this.servoCommand,
  });
}

class VoiceService {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _sttAvailable = false;
  bool _isListening = false;

  bool get isListening => _isListening;

  final StreamController<VoiceCommandResult> _commandController =
      StreamController<VoiceCommandResult>.broadcast();
  Stream<VoiceCommandResult> get commandStream => _commandController.stream;

  Future<void> initialize() async {
    _sttAvailable = await _stt.initialize(
      onError: (e) => debugPrint('STT Error: $e'),
      onStatus: (s) => debugPrint('STT Status: $s'),
    );

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> startListening() async {
    if (!_sttAvailable || _isListening) return;
    _isListening = true;

    await _stt.listen(
      onResult: (result) {
        if (result.finalResult) {
          _processCommand(result.recognizedWords.toLowerCase());
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 2),
      localeId: 'en_US',
    );
  }

  Future<void> stopListening() async {
    _isListening = false;
    await _stt.stop();
  }

  void _processCommand(String words) {
    debugPrint('Voice command: $words');
    VoiceCommandResult? result;

    if (words.contains('follow') || words.contains('track')) {
      result = VoiceCommandResult(
        targetMode: MainState.tracking,
        rawCommand: words,
      );
    } else if (words.contains('stop') || words.contains('halt')) {
      result = VoiceCommandResult(
        direction: MoveDirection.stop,
        rawCommand: words,
      );
    } else if (words.contains('forward') || words.contains('go')) {
      result = VoiceCommandResult(
        direction: MoveDirection.forward,
        rawCommand: words,
      );
    } else if (words.contains('back') || words.contains('reverse')) {
      result = VoiceCommandResult(
        direction: MoveDirection.backward,
        rawCommand: words,
      );
    } else if (words.contains('left')) {
      result = VoiceCommandResult(
        direction: MoveDirection.left,
        rawCommand: words,
      );
    } else if (words.contains('right')) {
      result = VoiceCommandResult(
        direction: MoveDirection.right,
        rawCommand: words,
      );
    } else if (words.contains('look up') || words.contains('tilt up')) {
      result = VoiceCommandResult(
        servoCommand: 'up',
        rawCommand: words,
      );
    } else if (words.contains('look down') || words.contains('tilt down')) {
      result = VoiceCommandResult(
        servoCommand: 'down',
        rawCommand: words,
      );
    } else if (words.contains('manual')) {
      result = VoiceCommandResult(
        targetMode: MainState.manual,
        rawCommand: words,
      );
    } else if (words.contains('auto') || words.contains('autonomous')) {
      result = VoiceCommandResult(
        targetMode: MainState.tracking,
        rawCommand: words,
      );
    } else if (words.contains('sleep') || words.contains('rest')) {
      result = VoiceCommandResult(
        targetMode: MainState.idle,
        rawCommand: words,
      );
    }

    if (result != null) {
      _commandController.add(result);
    }
  }

  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> dispose() async {
    await stopListening();
    await _tts.stop();
    await _commandController.close();
  }
}
