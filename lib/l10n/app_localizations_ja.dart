import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get chatPlaceholder => 'メッセージを入力...';

  @override
  String get appTitle => 'HealthBuddy AI';

  @override
  String get newSessionTooltip => '新しいセッションを開始';

  @override
  String get greetingPrompt => 'HealthBuddy として新規ユーザーに温かい挨拶をし、今日実践できる簡単なウェルネスのヒントをひとつ含めてください。';

  @override
  String get greetingFallback => 'こんにちは、HealthBuddy AIです。お会いできて嬉しいです！今日はどんな気分か教えてください。';

  @override
  String get resetChat => 'チャットをリセット';

  @override
  String get settingsTitle => '設定';

  @override
  String get languageLabel => '言語';

  @override
  String get languageEnglish => '英語';

  @override
  String get languageIndonesian => 'インドネシア語';

  @override
  String get languageJapanese => '日本語';

  @override
  String get saveButton => '保存';

  @override
  String get voiceInputPermissionDenied => '音声入力を使うにはマイクの権限を許可してください。';

  @override
  String geminiServiceError(Object error) {
    return '申し訳ありません。Gemini サービスで問題が発生しました: $error。少ししてから再試行してください。';
  }

  @override
  String get geminiTechnicalIssue => '申し訳ありません。技術的な問題が発生しています。メッセージをもう一度送ってください。';

  @override
  String get geminiEmptyResponse => '申し訳ありません。今はお答えできません。別の質問を試してください。';

  @override
  String voiceInputError(Object details) {
    return '音声入力エラー: $details';
  }

  @override
  String get attachImageTooltip => '画像を添付';

  @override
  String get voiceInputTooltipStart => '音声入力';

  @override
  String get voiceInputTooltipStop => '聞き取りを停止';

  @override
  String get galleryLabel => 'ギャラリー';

  @override
  String get cameraLabel => 'カメラ';

  @override
  String get copyConfirmation => 'メッセージをコピーしました。';

  @override
  String get ttsFailed => '音声を再生できませんでした。';

  @override
  String get shareLabel => '共有';

  @override
  String get copyLabel => 'コピー';

  @override
  String get replayLabel => '再生';
}
