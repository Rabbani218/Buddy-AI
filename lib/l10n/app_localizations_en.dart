import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get chatPlaceholder => 'Type a message...';

  @override
  String get appTitle => 'HealthBuddy AI';

  @override
  String get newSessionTooltip => 'Start new session';

  @override
  String get greetingPrompt => 'Provide a warm greeting as HealthBuddy for a new user and include one easy wellness tip to try today.';

  @override
  String get greetingFallback => 'Hi, I\'m HealthBuddy AI. Great to meet you! Tell me how you\'re feeling today.';

  @override
  String get resetChat => 'Reset Chat';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageIndonesian => 'Indonesian';

  @override
  String get languageJapanese => 'Japanese';

  @override
  String get saveButton => 'Save';

  @override
  String get voiceInputPermissionDenied => 'Microphone permission denied. Enable it to use voice input.';

  @override
  String geminiServiceError(Object error) {
    return 'Sorry, Gemini service issue: $error. Please try again shortly.';
  }

  @override
  String get geminiTechnicalIssue => 'Sorry, I\'m having a technical issue. Please resend your message.';

  @override
  String get geminiEmptyResponse => 'Sorry, I can\'t respond right now. Please try another question.';

  @override
  String voiceInputError(Object details) {
    return 'Voice input error: $details';
  }

  @override
  String get attachImageTooltip => 'Attach image';

  @override
  String get voiceInputTooltipStart => 'Voice input';

  @override
  String get voiceInputTooltipStop => 'Stop listening';

  @override
  String get galleryLabel => 'Gallery';

  @override
  String get cameraLabel => 'Camera';

  @override
  String get copyConfirmation => 'Message copied to clipboard.';

  @override
  String get ttsFailed => 'Unable to play voice.';

  @override
  String get shareLabel => 'Share';

  @override
  String get copyLabel => 'Copy';

  @override
  String get replayLabel => 'Replay voice';

  @override
  String get chatHistoryTooltip => 'Session history';

  @override
  String get chatHistoryEmpty => 'No sessions yet. Start a new conversation to see it here.';

  @override
  String get sessionLoadError => 'We couldn\'t load your chat session. Please try again.';

  @override
  String get retryLabel => 'Retry';

  @override
  String get sessionNotReady => 'Session is still loading. Please wait a moment.';
}
