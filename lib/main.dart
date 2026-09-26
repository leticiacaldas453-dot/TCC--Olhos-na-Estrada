import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/home_screen.dart';
import 'services/app_language.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService(); // <-- INICIALIZA O SERVIÇO
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
      _locale = Locale(lang.split('-')[0], lang.contains('-') ? lang.split('-')[1] : '');
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(217, 217, 10, 10)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}