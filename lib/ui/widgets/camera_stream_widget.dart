// lib/ui/widgets/camera_stream_widget.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:rover_companion/services/camera_service.dart';

class CameraStreamWidget extends StatelessWidget {
  final CameraService cameraService;

  const CameraStreamWidget({super.key, required this.cameraService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Uint8List>(
      stream: cameraService.frameStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              width: double.infinity,
            ),
          );
        }

        if (!cameraService.isAvailable) {
          return _NoStreamWidget();
        }

        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00CFFF),
            strokeWidth: 2,
          ),
        );
      },
    );
  }
}

class _NoStreamWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2A3040),
          width: 1,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_off_rounded,
              color: Color(0xFF3A4060),
              size: 48,
            ),
            SizedBox(height: 12),
            Text(
              'CAM OFFLINE',
              style: TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFF3A4060),
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'cam.local not reachable',
              style: TextStyle(
                color: Color(0xFF2A3040),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
