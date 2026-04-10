// lib/ui/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rover_companion/engines/state_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  String _status = 'BOOTING...';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
        parent: _controller, curve: Curves.easeIn);
    _scaleAnim =
        Tween<double>(begin: 0.8, end: 1.0).animate(_fadeAnim);

    _controller.forward();
    _boot();
  }

  Future<void> _boot() async {
    final sm = context.read<RoverStateManager>();

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _setStatus('LOADING PERCEPTION...');
      await sm.initialize();

      _setStatus('CONNECTING TO ROVER...');
      await Future.delayed(const Duration(milliseconds: 600));

      _setStatus(sm.isConnected ? 'ROVER ONLINE ✓' : 'ROVER OFFLINE');
      await Future.delayed(const Duration(milliseconds: 600));
    } catch (e) {
      debugPrint('Boot error: $e');
      _setStatus('BOOT ERROR');
      await Future.delayed(const Duration(seconds: 2));
    } finally {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  void _setStatus(String s) {
    if (mounted) setState(() => _status = s);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B12),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo mark
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00CFFF).withOpacity(0.6),
                      width: 2,
                    ),
                    color: const Color(0xFF0D1420),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00CFFF).withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: Color(0xFF00CFFF),
                    size: 48,
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  'ROVER',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE0ECFF),
                    letterSpacing: 8,
                  ),
                ),
                const Text(
                  'COMPANION',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Color(0xFF00CFFF),
                    letterSpacing: 6,
                  ),
                ),

                const SizedBox(height: 60),

                // Boot log
                Container(
                  width: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFF0A1018),
                    border: Border.all(
                        color: const Color(0xFF1A2030), width: 1),
                  ),
                  child: Column(
                    children: [
                      const LinearProgressIndicator(
                        backgroundColor: Color(0xFF1A2030),
                        color: Color(0xFF00CFFF),
                        minHeight: 2,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _status,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFF4080B0),
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
