import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/home_screen.dart';
import 'services/app_language.dart';
import 'services/background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print('>>> [NOTIF-BG] Resposta em background: ${notificationResponse.actionId}');
  if (notificationResponse.actionId == 'encerrar') {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializa as notificações no contexto principal do app
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      print('>>> [NOTIF] Resposta recebida: ${response.actionId}');
      if (response.actionId == 'encerrar') {
        // Cancela a notificação PRIMEIRO
        await flutterLocalNotificationsPlugin.cancel(888);

        // Depois envia o comando para parar o serviço
        final service = FlutterBackgroundService();
        service.invoke('stopService');
        print('>>> [NOTIF] Notificação cancelada e stopService enviado');
      }
    },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  // 2. Inicializa o serviço em segundo plano
  await initializeService();

  // 3. Roda o app
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('pt', 'BR');

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final lang = await AppLanguage.getLanguage();
    setState(() {
      _locale = Locale(
        lang.split('-')[0],
        lang.contains('-') ? lang.split('-')[1] : '',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Olhos na Estrada',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en'),
        Locale('es'),
        Locale('zh'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(217, 217, 10, 10),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}