// lib/services/vision_service.dart

import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class VisionService {
  CameraController? _controller;
  bool _isRunning = false;

  final StreamController<CameraImage> _frameController =
      StreamController<CameraImage>.broadcast();

  Stream<CameraImage> get frameStream => _frameController.stream;
  bool get isRunning => _isRunning;
  CameraController? get controller => _controller;

  Future<void> initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
    } catch (e) {
      debugPrint('VisionService init error: $e');
    }
  }

  Future<void> startCapturing() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isRunning) return;
    _isRunning = true;

    await _controller!.startImageStream((image) {
      if (!_frameController.isClosed) {
        _frameController.add(image);
      }
    });
  }

  Future<void> stopCapturing() async {
    _isRunning = false;
    try {
      await _controller?.stopImageStream();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stopCapturing();
    await _controller?.dispose();
    await _frameController.close();
  }
}
