// lib/models/app_config.dart

import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String _roverHostKey = 'rover_host';
  static const String _camHostKey = 'cam_host';
  static const String _autoModeKey = 'auto_mode';

  static const String defaultRoverHost = 'http://rover.local';
  static const String defaultCamHost = 'http://cam.local';

  String roverHost;
  String camHost;
  bool autoModeEnabled;

  AppConfig({
    this.roverHost = defaultRoverHost,
    this.camHost = defaultCamHost,
    this.autoModeEnabled = false,
  });

  String get camStreamUrl => '$camHost/stream';
  String get roverBaseUrl => roverHost;

  static Future<AppConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppConfig(
      roverHost: prefs.getString(_roverHostKey) ?? defaultRoverHost,
      camHost: prefs.getString(_camHostKey) ?? defaultCamHost,
      autoModeEnabled: prefs.getBool(_autoModeKey) ?? false,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roverHostKey, roverHost);
    await prefs.setString(_camHostKey, camHost);
    await prefs.setBool(_autoModeKey, autoModeEnabled);
  }
}
