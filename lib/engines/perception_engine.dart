// lib/engines/perception_engine.dart

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:rover_companion/models/perception.dart';

class PerceptionEngine {
  late final FaceDetector _faceDetector;
  late final ObjectDetector _objectDetector;
  bool _initialized = false;
  bool _processing = false;

  // Frame size (set when first frame is processed)
  double _frameWidth = 640;
  double _frameHeight = 480;

  static const double _centerThreshold = 60.0; // pixels from center

  Future<void> initialize() async {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: false,
        enableTracking: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    _objectDetector = ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.stream,
        classifyObjects: true,
        multipleObjects: false,
      ),
    );

    _initialized = true;
  }

  Future<PerceptionResult> analyzeFrame(CameraImage frame) async {
    if (!_initialized || _processing) return PerceptionResult.empty();
    _processing = true;

    try {
      _frameWidth = frame.width.toDouble();
      _frameHeight = frame.height.toDouble();

      final inputImage = _cameraImageToInputImage(frame);
      if (inputImage == null) return PerceptionResult.empty();

      // Run face detection
      final faces = await _faceDetector.processImage(inputImage);
      
      // Run object detection
      final objects = await _objectDetector.processImage(inputImage);

      return _buildPerception(faces, objects, inputImage);
    } catch (e) {
      debugPrint('PerceptionEngine error: $e');
      return PerceptionResult.empty();
    } finally {
      _processing = false;
    }
  }

  PerceptionResult _buildPerception(
    List<Face> faces,
    List<DetectedObject> objects,
    InputImage image,
  ) {
    final frameCenterX = _frameWidth / 2;

    // Prioritize faces
    if (faces.isNotEmpty) {
      final face = faces.first;
      final rect = face.boundingBox;
      final bbox = BoundingBox(
        x: rect.left,
        y: rect.top,
        w: rect.width,
        h: rect.height,
      );
      final xOffset = bbox.centerX - frameCenterX;
      final dist = _estimateDistance(rect.width * rect.height);

      return PerceptionResult(
        personDetected: true,
        faceDetected: true,
        faceKnown: false, // Recognition requires enrolled faces
        label: 'face',
        confidence: 0.9,
        bbox: bbox,
        xOffset: xOffset,
        centered: xOffset.abs() <= _centerThreshold,
        estimatedDistance: dist,
      );
    }

    // Fall back to object detection (person class)
    for (final obj in objects) {
      final isPerson = obj.labels.any(
        (l) => l.text.toLowerCase().contains('person') && l.confidence > 0.5,
      );
      if (isPerson) {
        final rect = obj.boundingBox;
        final bbox = BoundingBox(
          x: rect.left.toDouble(),
          y: rect.top.toDouble(),
          w: rect.width.toDouble(),
          h: rect.height.toDouble(),
        );
        final xOffset = bbox.centerX - frameCenterX;
        final dist = _estimateDistance(rect.width * rect.height.toDouble());
        final confidence = obj.labels
            .where((l) => l.text.toLowerCase().contains('person'))
            .fold(0.0, (a, b) => a + b.confidence);

        return PerceptionResult(
          personDetected: true,
          faceDetected: false,
          label: 'person',
          confidence: confidence.clamp(0.0, 1.0),
          bbox: bbox,
          xOffset: xOffset,
          centered: xOffset.abs() <= _centerThreshold,
          estimatedDistance: dist,
        );
      }
    }

    return PerceptionResult.empty();
  }

  EstimatedDistance _estimateDistance(double area) {
    final frameArea = _frameWidth * _frameHeight;
    final ratio = area / frameArea;
    if (ratio > 0.25) return EstimatedDistance.near;
    if (ratio > 0.08) return EstimatedDistance.medium;
    return EstimatedDistance.far;
  }

  InputImage? _cameraImageToInputImage(CameraImage image) {
    try {
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      final plane = image.planes.first;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: ui.Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('InputImage conversion error: $e');
      return null;
    }
  }

  Future<void> dispose() async {
    await _faceDetector.close();
    await _objectDetector.close();
  }
}
