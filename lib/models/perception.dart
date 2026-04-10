// lib/models/perception.dart

class BoundingBox {
  final double x, y, w, h;

  const BoundingBox({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  double get centerX => x + w / 2;
  double get centerY => y + h / 2;
  double get area => w * h;

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'w': w, 'h': h};
}

enum EstimatedDistance { near, medium, far, unknown }

class PerceptionResult {
  final bool personDetected;
  final bool faceDetected;
  final bool faceKnown;
  final String? faceLabel;
  final String label;
  final double confidence;
  final BoundingBox? bbox;
  final double xOffset;
  final bool centered;
  final EstimatedDistance estimatedDistance;
  final DateTime timestamp;

  PerceptionResult({
    this.personDetected = false,
    this.faceDetected = false,
    this.faceKnown = false,
    this.faceLabel,
    this.label = 'none',
    this.confidence = 0,
    this.bbox,
    this.xOffset = 0,
    this.centered = false,
    this.estimatedDistance = EstimatedDistance.unknown,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory PerceptionResult.empty() => PerceptionResult();

  Map<String, dynamic> toJson() => {
        'personDetected': personDetected,
        'faceDetected': faceDetected,
        'faceKnown': faceKnown,
        'label': label,
        'confidence': confidence,
        'bbox': bbox?.toJson(),
        'xOffset': xOffset,
        'centered': centered,
        'estimatedDistance': estimatedDistance.name,
      };
}
