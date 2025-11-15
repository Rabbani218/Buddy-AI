import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get chatPlaceholder => 'Ketik pesan...';

  @override
  String get appTitle => 'HealthBuddy AI';

  @override
  String get newSessionTooltip => 'Mulai sesi baru';

  @override
  String get greetingPrompt => 'Berikan sapaan pembuka hangat sebagai HealthBuddy untuk pengguna baru dan sertakan satu tips kesehatan singkat yang mudah dilakukan hari ini.';

  @override
  String get greetingFallback => 'Halo, aku HealthBuddy AI. Senang bertemu denganmu! Ceritakan bagaimana perasaanmu hari ini.';

  @override
  String get resetChat => 'Reset Obrolan';

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get languageLabel => 'Bahasa';

  @override
  String get languageEnglish => 'Inggris';

  @override
  String get languageIndonesian => 'Indonesia';

  @override
  String get languageJapanese => 'Jepang';

  @override
  String get saveButton => 'Simpan';

  @override
  String get voiceInputPermissionDenied => 'Izin mikrofon ditolak. Aktifkan untuk memakai input suara.';

  @override
  String geminiServiceError(Object error) {
    return 'Maaf, terjadi kendala pada layanan Gemini: $error. Coba lagi sebentar lagi.';
  }

  @override
  String get geminiTechnicalIssue => 'Maaf, aku sedang mengalami kendala teknis. Silakan coba kirim ulang pesannya.';

  @override
  String get geminiEmptyResponse => 'Maaf, aku belum bisa merespons sekarang. Silakan coba pertanyaan lain.';

  @override
  String voiceInputError(Object details) {
    return 'Kesalahan input suara: $details';
  }

  @override
  String get attachImageTooltip => 'Lampirkan gambar';

  @override
  String get voiceInputTooltipStart => 'Input suara';

  @override
  String get voiceInputTooltipStop => 'Hentikan mendengarkan';

  @override
  String get galleryLabel => 'Galeri';

  @override
  String get cameraLabel => 'Kamera';

  @override
  String get copyConfirmation => 'Pesan disalin ke clipboard.';

  @override
  String get ttsFailed => 'Gagal memutar suara.';

  @override
  String get shareLabel => 'Bagikan';

  @override
  String get copyLabel => 'Salin';

  @override
  String get replayLabel => 'Putar ulang';

  @override
  String get chatHistoryTooltip => 'Riwayat sesi';

  @override
  String get chatHistoryEmpty => 'Belum ada sesi. Mulai percakapan baru untuk melihatnya di sini.';

  @override
  String get sessionLoadError => 'Riwayat sesi tidak dapat dimuat. Coba lagi.';

  @override
  String get retryLabel => 'Coba lagi';

  @override
  String get sessionNotReady => 'Sesi masih dimuat. Tunggu sebentar.';
}
