import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'ble_manager.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'olhos_na_estrada_channel',
      initialNotificationTitle: 'Olhos na Estrada',
      initialNotificationContent: 'Navegação ativa em segundo plano',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: [AndroidForegroundType.location],
      autoStartOnBoot: false,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  print('>>> [BG] onStart() chamado!');

  if (service is AndroidServiceInstance) {
    // Escuta o evento para promover a Foreground
    service.on('setAsForeground').listen((event) {
      print('>>> [BG] setAsForeground recebido! Promovendo...');
      service.setAsForegroundService();
      print('>>> [BG] Foreground ativado!');
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    print('>>> [BG] stopService recebido!');
    service.stopSelf();
  });

  // Loop infinito para manter o serviço rodando
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        print('>>> [BG] Serviço ainda está em Foreground.');
      }
    }
  });
}