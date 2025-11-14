import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
    Locale('ja')
  ];

  /// No description provided for @chatPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get chatPlaceholder;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'HealthBuddy AI'**
  String get appTitle;

  /// No description provided for @newSessionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Start new session'**
  String get newSessionTooltip;

  /// No description provided for @greetingPrompt.
  ///
  /// In en, this message translates to:
  /// **'Provide a warm greeting as HealthBuddy for a new user and include one easy wellness tip to try today.'**
  String get greetingPrompt;

  /// No description provided for @greetingFallback.
  ///
  /// In en, this message translates to:
  /// **'Hi, I\'m HealthBuddy AI. Great to meet you! Tell me how you\'re feeling today.'**
  String get greetingFallback;

  /// No description provided for @resetChat.
  ///
  /// In en, this message translates to:
  /// **'Reset Chat'**
  String get resetChat;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageIndonesian.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get languageIndonesian;

  /// No description provided for @languageJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get languageJapanese;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @voiceInputPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied. Enable it to use voice input.'**
  String get voiceInputPermissionDenied;

  /// No description provided for @geminiServiceError.
  ///
  /// In en, this message translates to:
  /// **'Sorry, Gemini service issue: {error}. Please try again shortly.'**
  String geminiServiceError(Object error);

  /// No description provided for @geminiTechnicalIssue.
  ///
  /// In en, this message translates to:
  /// **'Sorry, I\'m having a technical issue. Please resend your message.'**
  String get geminiTechnicalIssue;

  /// No description provided for @geminiEmptyResponse.
  ///
  /// In en, this message translates to:
  /// **'Sorry, I can\'t respond right now. Please try another question.'**
  String get geminiEmptyResponse;

  /// No description provided for @voiceInputError.
  ///
  /// In en, this message translates to:
  /// **'Voice input error: {details}'**
  String voiceInputError(Object details);

  /// No description provided for @attachImageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Attach image'**
  String get attachImageTooltip;

  /// No description provided for @voiceInputTooltipStart.
  ///
  /// In en, this message translates to:
  /// **'Voice input'**
  String get voiceInputTooltipStart;

  /// No description provided for @voiceInputTooltipStop.
  ///
  /// In en, this message translates to:
  /// **'Stop listening'**
  String get voiceInputTooltipStop;

  /// No description provided for @galleryLabel.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get galleryLabel;

  /// No description provided for @cameraLabel.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get cameraLabel;

  /// No description provided for @copyConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Message copied to clipboard.'**
  String get copyConfirmation;

  /// No description provided for @ttsFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to play voice.'**
  String get ttsFailed;

  /// No description provided for @shareLabel.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareLabel;

  /// No description provided for @copyLabel.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyLabel;

  /// No description provided for @replayLabel.
  ///
  /// In en, this message translates to:
  /// **'Replay voice'**
  String get replayLabel;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'id', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'id': return AppLocalizationsId();
    case 'ja': return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
