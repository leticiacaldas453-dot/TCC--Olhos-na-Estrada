import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'Olhos na Estrada'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settings;

  /// No description provided for @searchDevices.
  ///
  /// In pt, this message translates to:
  /// **'Buscar Dispositivos'**
  String get searchDevices;

  /// No description provided for @languageInstructions.
  ///
  /// In pt, this message translates to:
  /// **'Idioma das Instruções'**
  String get languageInstructions;

  /// No description provided for @destinationHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Destinos'**
  String get destinationHistory;

  /// No description provided for @appSettings.
  ///
  /// In pt, this message translates to:
  /// **'Ajustes do App'**
  String get appSettings;

  /// No description provided for @soundAlerts.
  ///
  /// In pt, this message translates to:
  /// **'Alertas Sonoros'**
  String get soundAlerts;

  /// No description provided for @highAccuracyGps.
  ///
  /// In pt, this message translates to:
  /// **'GPS Alta Precisão'**
  String get highAccuracyGps;

  /// No description provided for @whereTo.
  ///
  /// In pt, this message translates to:
  /// **'Para onde vamos?'**
  String get whereTo;

  /// No description provided for @typeDestination.
  ///
  /// In pt, this message translates to:
  /// **'Digite o destino...'**
  String get typeDestination;

  /// No description provided for @yourLocation.
  ///
  /// In pt, this message translates to:
  /// **'Sua localização'**
  String get yourLocation;

  /// No description provided for @favorites.
  ///
  /// In pt, this message translates to:
  /// **'Locais Favoritos'**
  String get favorites;

  /// No description provided for @add.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get add;

  /// No description provided for @noFavorites.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum favorito cadastrado.'**
  String get noFavorites;

  /// No description provided for @clickToAdd.
  ///
  /// In pt, this message translates to:
  /// **'Clique em \"Adicionar\" para criar.'**
  String get clickToAdd;

  /// No description provided for @editFavorite.
  ///
  /// In pt, this message translates to:
  /// **'Editar Favorito'**
  String get editFavorite;

  /// No description provided for @newFavorite.
  ///
  /// In pt, this message translates to:
  /// **'Novo Favorito'**
  String get newFavorite;

  /// No description provided for @favoriteName.
  ///
  /// In pt, this message translates to:
  /// **'Nome (ex: Casa)'**
  String get favoriteName;

  /// No description provided for @favoriteAddress.
  ///
  /// In pt, this message translates to:
  /// **'Endereço completo'**
  String get favoriteAddress;

  /// No description provided for @cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get save;

  /// No description provided for @confirmRoute.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Rota'**
  String get confirmRoute;

  /// No description provided for @destination.
  ///
  /// In pt, this message translates to:
  /// **'Destino'**
  String get destination;

  /// No description provided for @distance.
  ///
  /// In pt, this message translates to:
  /// **'Distância'**
  String get distance;

  /// No description provided for @estimatedTime.
  ///
  /// In pt, this message translates to:
  /// **'Tempo estimado'**
  String get estimatedTime;

  /// No description provided for @startRoute.
  ///
  /// In pt, this message translates to:
  /// **'INICIAR TRAJETO'**
  String get startRoute;

  /// No description provided for @end.
  ///
  /// In pt, this message translates to:
  /// **'ENCERRAR'**
  String get end;

  /// No description provided for @synchronizing.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizando com ESP32...'**
  String get synchronizing;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
