// lib/services/camera_service.dart

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:rover_companion/models/app_config.dart';

class CameraService {
  final AppConfig config;
  bool _isStreaming = false;
  bool _isAvailable = false;

  bool get isStreaming => _isStreaming;
  bool get isAvailable => _isAvailable;

  final StreamController<Uint8List> _frameController =
      StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get frameStream => _frameController.stream;

  CameraService(this.config);


  Future<bool> autoDiscoverCam() async {
    try {
      final res = await http.get(Uri.parse(config.camHost)).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200 && res.body.contains("ESP32-CAM")) {
        return true;
      }
    } catch (_) {}

    try {
      final Set<String> subnets = {};
      
      // 1. ALWAYS prioritize the subnet that the Rover is already using!
      final String roverIp = config.roverHost;
      final RegExp ipRegExp = RegExp(r'(\d{1,3}\.\d{1,3}\.\d{1,3})\.\d{1,3}');
      final match = ipRegExp.firstMatch(roverIp);
      if (match != null) {
        subnets.add(match.group(1)!);
      }

      // 2. Add local interfaces as fallback
      final interfaces = await NetworkInterface.list();
      for (var iface in interfaces) {
        for (var addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4) {
             final m = ipRegExp.firstMatch(addr.address);
             if (m != null) subnets.add(m.group(1)!);
          }
        }
      }
      
      subnets.addAll(['192.168.43', '192.168.212', '192.168.106']);

      for (var subnet in subnets) {
        final tasks = <Future<String?>>[];
        for (int i = 1; i <= 254; i++) {
          final target = 'http://$subnet.$i';
          tasks.add((() async {
            try {
              // Increase timeout heavily because ESP32-CAM is slow and handles HTTP poorly
              final res = await http.get(Uri.parse(target)).timeout(const Duration(milliseconds: 2500));
              if (res.statusCode == 200 && res.body.contains("ESP32-CAM")) {
                return target;
              }
            } catch (_) {}
            return null;
          })());
        }
        
        final results = await Future.wait(tasks);
        final found = results.firstWhere((ip) => ip != null, orElse: () => null);
        
        if (found != null) {
          config.camHost = found;
          await config.save();
          return true;
        }
      }
    } catch (_) {}
    
    return false;
  }

  Future<void> startStream() async {
    if (_isStreaming) return;
    _isStreaming = true;

    try {
      final uri = Uri.parse(config.camStreamUrl);
      final request = http.Request('GET', uri);
      final client = http.Client();

      final streamedResponse = await client
          .send(request)
          .timeout(const Duration(seconds: 5));

      if (streamedResponse.statusCode == 200) {
        _isAvailable = true;
        _parseMjpeg(streamedResponse.stream);
      } else {
        _isAvailable = false;
        _isStreaming = false;
      }
    } catch (e) {
      _isAvailable = false;
      _isStreaming = false;
      debugPrint('CameraService stream error: $e');
    }
  }

  void _parseMjpeg(Stream<List<int>> byteStream) {
    final List<int> buffer = [];
    const jpegStart = [0xFF, 0xD8];
    const jpegEnd = [0xFF, 0xD9];

    byteStream.listen(
      (chunk) {
        buffer.addAll(chunk);

        while (true) {
          final startIdx = _findSequence(buffer, jpegStart);
          if (startIdx == -1) break;

          final endIdx = _findSequence(buffer, jpegEnd, startIdx + 2);
          if (endIdx == -1) break;

          final jpegBytes = Uint8List.fromList(
            buffer.sublist(startIdx, endIdx + 2),
          );

          if (!_frameController.isClosed) {
            _frameController.add(jpegBytes);
          }

          buffer.removeRange(0, endIdx + 2);
        }
      },
      onError: (e) {
        _isAvailable = false;
        _isStreaming = false;
        debugPrint('MJPEG stream error: $e');
      },
      onDone: () {
        _isStreaming = false;
        _isAvailable = false;
      },
    );
  }

  int _findSequence(List<int> data, List<int> seq, [int from = 0]) {
    for (int i = from; i <= data.length - seq.length; i++) {
      bool found = true;
      for (int j = 0; j < seq.length; j++) {
        if (data[i + j] != seq[j]) {
          found = false;
          break;
        }
      }
      if (found) return i;
    }
    return -1;
  }

  Future<void> stopStream() async {
    _isStreaming = false;
  }

  void dispose() {
    stopStream();
    _frameController.close();
  }
}
