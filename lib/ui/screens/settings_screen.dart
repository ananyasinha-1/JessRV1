// lib/ui/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rover_companion/engines/state_manager.dart';
import 'package:rover_companion/models/app_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _roverCtrl;
  late TextEditingController _camCtrl;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final sm = context.read<RoverStateManager>();
    _roverCtrl = TextEditingController(text: sm.config.roverHost);
    _camCtrl = TextEditingController(text: sm.config.camHost);
  }

  @override
  void dispose() {
    _roverCtrl.dispose();
    _camCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final sm = context.read<RoverStateManager>();
    final newConfig = AppConfig(
      roverHost: _roverCtrl.text.trim(),
      camHost: _camCtrl.text.trim(),
    );
    sm.updateConfig(newConfig);
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2),
        () => setState(() => _saved = false));
  }

  @override
  Widget build(BuildContext context) {
    final sm = context.watch<RoverStateManager>();

    return Scaffold(
      backgroundColor: const Color(0xFF070B12),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: const Color(0xFF111825),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.1)),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF8090B0),
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'CONFIGURATION',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFF8090B0),
                      fontSize: 14,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Connection status card
                  _StatusCard(sm: sm),
                  const SizedBox(height: 24),

                  // Network section
                  _SectionHeader(label: 'NETWORK'),
                  const SizedBox(height: 12),
                  _ConfigField(
                    label: 'Rover Host',
                    hint: 'http://rover.local',
                    controller: _roverCtrl,
                    icon: Icons.router_rounded,
                  ),
                  const SizedBox(height: 12),
                  _ConfigField(
                    label: 'Camera Host',
                    hint: 'http://cam.local',
                    controller: _camCtrl,
                    icon: Icons.videocam_rounded,
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  GestureDetector(
                    onTap: _save,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: _saved
                            ? const Color(0xFF00FF88).withOpacity(0.15)
                            : const Color(0xFF00CFFF).withOpacity(0.15),
                        border: Border.all(
                          color: _saved
                              ? const Color(0xFF00FF88)
                              : const Color(0xFF00CFFF),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _saved ? '✓  SAVED' : 'SAVE & RECONNECT',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: _saved
                                ? const Color(0xFF00FF88)
                                : const Color(0xFF00CFFF),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  _SectionHeader(label: 'MEMORY'),
                  const SizedBox(height: 12),
                  _InfoTile(
                    label: 'Known Faces',
                    value: '${sm.memory.knownFaces.length}',
                  ),
                  _InfoTile(
                    label: 'Total Interactions',
                    value: '${sm.memory.totalInteractions}',
                  ),
                  _InfoTile(
                    label: 'Last Command',
                    value: sm.memory.lastCommandSent?.name.toUpperCase() ??
                        '—',
                  ),

                  const SizedBox(height: 32),
                  _SectionHeader(label: 'ABOUT'),
                  const SizedBox(height: 12),
                  const _InfoTile(
                      label: 'App Version', value: '1.0.0'),
                  const _InfoTile(
                      label: 'Protocol', value: 'HTTP/REST'),
                  const _InfoTile(
                      label: 'Stream', value: 'MJPEG'),
                  const _InfoTile(
                      label: 'AI', value: 'Google ML Kit'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final RoverStateManager sm;
  const _StatusCard({required this.sm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF0D1420),
        border: Border.all(
          color: sm.isConnected
              ? const Color(0xFF00FF88).withOpacity(0.3)
              : const Color(0xFFFF3355).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: sm.isConnected
                  ? const Color(0xFF00FF88)
                  : const Color(0xFFFF3355),
              boxShadow: [
                BoxShadow(
                  color: sm.isConnected
                      ? const Color(0xFF00FF88)
                      : const Color(0xFFFF3355),
                  blurRadius: 8,
                )
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sm.isConnected ? 'ROVER ONLINE' : 'ROVER OFFLINE',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: sm.isConnected
                      ? const Color(0xFF00FF88)
                      : const Color(0xFFFF3355),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sm.config.roverHost,
                style: const TextStyle(
                  color: Color(0xFF5060A0),
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'monospace',
        color: Color(0xFF3A4060),
        fontSize: 11,
        letterSpacing: 3,
      ),
    );
  }
}

class _ConfigField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;

  const _ConfigField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF5060A0),
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(
            fontFamily: 'monospace',
            color: Color(0xFFB0C0E0),
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF2A3040),
              fontFamily: 'monospace',
              fontSize: 12,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF3A4060), size: 18),
            filled: true,
            fillColor: const Color(0xFF0D1420),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFF1A2030), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFF00CFFF), width: 1.5),
            ),
          ),
          keyboardType: TextInputType.url,
          autocorrect: false,
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4050A0),
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF8090B0),
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
