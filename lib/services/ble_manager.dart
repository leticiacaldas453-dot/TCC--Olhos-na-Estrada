import 'dart:async';
import 'dart:convert';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class BleManager {
  static const String _kLastDeviceKey = 'last_connected_device';
  BleManager._internal();
  static final BleManager instance = BleManager._internal();
  final ValueNotifier<bool> connectionNotifier = ValueNotifier<bool>(false);
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<ConnectionStateUpdate>? _connSub;

  bool isScanning = false;
  bool isConnected = false;
  String? connectedDeviceId;
  String? connectedDeviceName;

  Stream<BleStatus> get statusStream => _ble.statusStream;

  late SharedPreferences _prefs;

  static const String _kServiceKey = 'esp_service_uuid';
  static const String _kCharKey = 'esp_char_uuid';

  // Defaults (HM-10 style) - adjust if your firmware uses other UUIDs
  static const String defaultServiceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const String defaultCharUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get serviceUuid => _prefs.getString(_kServiceKey) ?? defaultServiceUuid;
  String get charUuid => _prefs.getString(_kCharKey) ?? defaultCharUuid;

  Future<void> setServiceUuid(String uuid) async {
    await _prefs.setString(_kServiceKey, uuid);
  }

  Future<void> setCharUuid(String uuid) async {
    await _prefs.setString(_kCharKey, uuid);
  }

  Stream<DiscoveredDevice> scanForDevices() {
    return _ble.scanForDevices(withServices: const []);
  }

  Future<void> connectToDevice(String deviceId, {Duration timeout = const Duration(seconds: 10)}) async {
    _connSub?.cancel();
    _connSub = _ble.connectToDevice(id: deviceId, connectionTimeout: timeout).listen((update) {
      if (update.connectionState == DeviceConnectionState.connected) {
        isConnected = true;
        connectedDeviceId = deviceId;
        connectionNotifier.value = true;
        _saveLastDevice(deviceId); // <-- SALVA O deviceId
      } else if (update.connectionState == DeviceConnectionState.disconnected) {
        isConnected = false;
        connectedDeviceId = null;
        connectedDeviceName = null;
        connectionNotifier.value = false;
      }
    });
  }

  Future<void> disconnect() async {
    await _connSub?.cancel();
    isConnected = false;
    connectedDeviceId = null;
    connectedDeviceName = null;
    connectionNotifier.value = false;
  }

  Future<void> writeInstruction(String text) async {
    if (!isConnected || connectedDeviceId == null) {
      throw Exception('No device connected');
    }

    final qc = QualifiedCharacteristic(
      serviceId: Uuid.parse(serviceUuid),
      characteristicId: Uuid.parse(charUuid),
      deviceId: connectedDeviceId!,
    );

    final data = utf8.encode(text);

    await _ble.writeCharacteristicWithResponse(qc, value: data);
  }

  Future<void> _saveLastDevice(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastDeviceKey, deviceId);
  }

  Future<String?> getLastDevice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLastDeviceKey);
  }

  Future<bool> tryReconnect() async {
    final lastDevice = await getLastDevice();
    if (lastDevice == null) return false;

    try {
      await connectToDevice(lastDevice);
      // Aguarda a conexão
      await Future.delayed(const Duration(seconds: 3));
      return isConnected;
    } catch (e) {
      print('>>> [BLE] Falha ao reconectar: $e');
      return false;
    }
  }
}
