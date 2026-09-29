import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ble_manager.dart';

// Canal e ID da notificação
const String notificationChannelId = 'olhos_na_estrada_channel';
const int notificationId = 888;

// Plugin de notificações (referência global — já inicializado no main.dart)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// Variáveis globais com os textos traduzidos
String _notificationTitle = 'Olhos na Estrada';
String _notificationContent = 'Navegação ativa em segundo plano';
String _notificationEnd = 'ENCERRAR';

Future<void> initializeService() async {
  // Lê o idioma salvo
  final prefs = await SharedPreferences.getInstance();
  final lang = prefs.getString('app_language') ?? 'pt-BR';

  // Define os textos traduzidos
  switch (lang) {
    case 'en':
      _notificationTitle = 'Eyes on the Road';
      _notificationContent = 'Navigation active in background';
      _notificationEnd = 'END';
      break;
    case 'es':
      _notificationTitle = 'Ojos en la Carretera';
      _notificationContent = 'Navegación activa en segundo plano';
      _notificationEnd = 'TERMINAR';
      break;
    case 'zh':
      _notificationTitle = '路上的眼睛';
      _notificationContent = '后台导航已激活';
      _notificationEnd = '结束';
      break;
    case 'pt-BR':
    default:
      _notificationTitle = 'Olhos na Estrada';
      _notificationContent = 'Navegação ativa em segundo plano';
      _notificationEnd = 'ENCERRAR';
      break;
  }

  print('>>> [BG] Idioma lido do SharedPreferences: $lang');
  print('>>> [BG] Título: $_notificationTitle');
  print('>>> [BG] Botão: $_notificationEnd');

  // Cria o canal de notificação no Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    'Olhos na Estrada',
    description: 'Navegação ativa em segundo plano',
    importance: Importance.low,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: _notificationTitle,
      initialNotificationContent: _notificationContent,
      foregroundServiceNotificationId: notificationId,
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
    service.on('setAsForeground').listen((event) {
      print('>>> [BG] setAsForeground recebido!');
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  // Escuta o comando para encerrar o serviço
  service.on('stopService').listen((event) async {
    print('>>> [BG] stopService recebido!');

    // Avisa o ESP32 que a navegação parou
    try {
      await BleManager.instance.writeInstruction('DIR|Fim da navegacao|0|arrive|0,0');
      print('>>> [BG] ESP32 notificado do fim da navegação');
    } catch (e) {
      print('>>> [BG] Erro ao notificar ESP32: $e');
    }

    // Para o serviço
    service.stopSelf();
  });

  // Escuta o comando para atualizar o idioma da notificação
  service.on('updateLanguage').listen((event) async {
    print('>>> [BG] updateLanguage recebido!');
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('app_language') ?? 'pt-BR';

    switch (lang) {
      case 'en':
        _notificationTitle = 'Eyes on the Road';
        _notificationContent = 'Navigation active in background';
        _notificationEnd = 'END';
        break;
      case 'es':
        _notificationTitle = 'Ojos en la Carretera';
        _notificationContent = 'Navegación activa en segundo plano';
        _notificationEnd = 'TERMINAR';
        break;
      case 'zh':
        _notificationTitle = '路上的眼睛';
        _notificationContent = '后台导航已激活';
        _notificationEnd = '结束';
        break;
      default:
        _notificationTitle = 'Olhos na Estrada';
        _notificationContent = 'Navegação ativa em segundo plano';
        _notificationEnd = 'ENCERRAR';
        break;
    }

    print('>>> [BG] Idioma atualizado para: $lang - $_notificationTitle / $_notificationEnd');

    // CRUCIAL: Força a atualização da notificação IMEDIATAMENTE
    if (service is AndroidServiceInstance) {
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        notificationChannelId,
        'Olhos na Estrada',
        channelDescription: 'Navegação ativa em segundo plano',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'encerrar',
            _notificationEnd,  // ← Agora com o texto novo!
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      );

      await flutterLocalNotificationsPlugin.show(
        notificationId,
        _notificationTitle,   // ← Texto novo
        _notificationContent, // ← Texto novo
        NotificationDetails(android: androidDetails),
      );
    }
  });

  // Loop para manter a notificação ativa com o botão traduzido
  // Loop para manter a notificação ativa com o botão traduzido
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        // LÊ O IDIOMA ATUAL DO SHAREDPREFERENCES A CADA CICLO
        final prefs = await SharedPreferences.getInstance();
        final lang = prefs.getString('app_language') ?? 'pt-BR';

        // Define os textos baseado no idioma
        String title;
        String content;
        String endText;

        switch (lang) {
          case 'en':
            title = 'Eyes on the Road';
            content = 'Navigation active in background';
            endText = 'END';
            break;
          case 'es':
            title = 'Ojos en la Carretera';
            content = 'Navegación activa en segundo plano';
            endText = 'TERMINAR';
            break;
          case 'zh':
            title = '路上的眼睛';
            content = '后台导航已激活';
            endText = '结束';
            break;
          default:
            title = 'Olhos na Estrada';
            content = 'Navegação ativa em segundo plano';
            endText = 'ENCERRAR';
            break;
        }

        final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          notificationChannelId,
          'Olhos na Estrada',
          channelDescription: 'Navegação ativa em segundo plano',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'encerrar',
              endText,
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        );

        await flutterLocalNotificationsPlugin.show(
          notificationId,
          title,
          content,
          NotificationDetails(android: androidDetails),
        );

        print('>>> [BG] Notificação atualizada: $title / $endText');
      }
    }
  });
}