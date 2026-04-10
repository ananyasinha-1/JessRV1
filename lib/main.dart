// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rover_companion/engines/state_manager.dart';
import 'package:rover_companion/models/app_config.dart';
import 'package:rover_companion/ui/screens/splash_screen.dart';
import 'package:rover_companion/ui/screens/face_screen.dart';
import 'package:rover_companion/ui/screens/control_screen.dart';
import 'package:rover_companion/ui/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force landscape + portrait, prefer portrait for face screen
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF070B12),
  ));

  final config = await AppConfig.load();

  runApp(
    ChangeNotifierProvider(
      create: (_) => RoverStateManager(config),
      child: const RoverApp(),
    ),
  );
}

class RoverApp extends StatelessWidget {
  const RoverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rover Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF070B12),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00CFFF),
          secondary: Color(0xFF00FF88),
          surface: Color(0xFF0D1420),
          error: Color(0xFFFF3355),
        ),
        fontFamily: 'monospace',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF8090B0)),
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/home': (_) => const FaceScreen(),
        '/control': (_) => const ControlScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
