import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import '../l10n/generated/app_localizations.dart'; 
import '../services/ble_manager.dart';
import '../services/app_language.dart';


class SettingsScreen extends StatefulWidget {
  final List<String> history;
  const SettingsScreen({super.key, required this.history});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isScanning = false;
  final List<DiscoveredDevice> _foundDevices = [];
  StreamSubscription<DiscoveredDevice>? _scanSub;

  String _currentLanguage = AppLanguage.defaultLanguage;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final lang = await AppLanguage.getLanguage();
    setState(() => _currentLanguage = lang);
  }

  Future<void> _changeLanguage(String languageCode) async {
    await AppLanguage.setLanguage(languageCode);
    setState(() => _currentLanguage = languageCode);
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }

  Future<void> _toggleScan() async {
    if (_isScanning) {
      await _scanSub?.cancel();
      setState(() => _isScanning = false);
      return;
    }

    await [Permission.bluetoothScan, Permission.bluetoothConnect, Permission.location].request();

    setState(() {
      _foundDevices.clear();
      _isScanning = true;
    });

    _scanSub = BleManager.instance.scanForDevices().listen((device) {
      if (!mounted || _foundDevices.any((d) => d.id == device.id)) return;
      setState(() => _foundDevices.add(device));
    }, onDone: () => setState(() => _isScanning = false));
  }

  void _connect(DiscoveredDevice device) async {
    try {
      await BleManager.instance.connectToDevice(device.id);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!; // <-- ADICIONE

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settings), // <-- Traduzido
        backgroundColor: const Color.fromARGB(217, 217, 10, 10),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(t.searchDevices), // <-- Traduzido
          ListTile(
            title: Text(t.searchDevices), // <-- Traduzido
            trailing: _isScanning ? const CircularProgressIndicator() : const Icon(Icons.search),
            onTap: _toggleScan,
          ),
          ..._foundDevices.map((device) => ListTile(
            leading: const Icon(Icons.bluetooth),
            title: Text(device.name.isEmpty ? 'Sem Nome' : device.name),
            subtitle: Text(device.id),
            trailing: BleManager.instance.connectedDeviceId == device.id
                ? const Icon(Icons.check, color: Color(0xFF0D47A1))
                : ElevatedButton(onPressed: () => _connect(device), child: const Text('Conectar')),
          )),
          const Divider(),

          // Seção de idioma
          _buildSectionHeader(t.languageInstructions), // <-- Traduzido
          ...AppLanguage.supportedLanguages.entries.map((entry) {
            return RadioListTile<String>(
              title: Text(entry.value),
              value: entry.key,
              groupValue: _currentLanguage,
              onChanged: (value) {
                if (value != null) _changeLanguage(value);
              },
              activeColor: const Color.fromARGB(217, 217, 10, 10),
            );
          }),
          const Divider(),

          // Histórico
          _buildSectionHeader(t.destinationHistory), // <-- Traduzido
          ...widget.history.map((h) => ListTile(leading: const Icon(Icons.history), title: Text(h))),
          const Divider(),
          _buildSectionHeader(t.appSettings), // <-- Traduzido
          SwitchListTile(title: Text(t.soundAlerts), value: true, onChanged: (v) {}), // <-- Traduzido
          SwitchListTile(title: Text(t.highAccuracyGps), value: false, onChanged: (v) {}), // <-- Traduzido
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }
}