import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:healthbuddy_ai/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/storage_keys.dart';
import '../models/chat_message.dart';
import '../providers/app_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
    Locale('ja'),
  ];
  static const double _minSpeechRate = 0.1;
  static const double _maxSpeechRate = 1.0;
  static const double _defaultSpeechRate = 0.5;
  static const String _githubUrl = 'https://github.com/Rabbani218';
  static const String _githubIconUrl =
      'https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png';
  static const String _avatarCreditUrl =
      'https://sketchfab.com/3d-models/free-annie-anime-gerl-490a8417cac946899eac86fba72cc210';
  static const String _backgroundCreditUrl =
      'https://unsplash.com/id/foto/gambar-buram-dari-latar-belakang-biru-dan-merah-muda-bUtAqPi-wz4';

  Locale? _selectedLocale;
  ThemeMode _selectedThemeMode = ThemeMode.system;
  double _speechRate = _defaultSpeechRate;
  bool _isSaving = false;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _selectedLocale = ref.read(localeProvider);
    _selectedThemeMode = ref.read(themeProvider);
    Future.microtask(_initializePreferences);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            _buildLanguageSection(l10n, theme),
            const SizedBox(height: 24),
            _buildThemeSection(theme),
            const SizedBox(height: 24),
            _buildVoiceSection(theme),
            const SizedBox(height: 24),
            _buildDataPrivacySection(theme),
            const SizedBox(height: 24),
            _buildAboutSection(theme),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _savePreference,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.saveButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initializePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final storedRate = prefs.getDouble(ttsRateStorageKey);
    final storedTheme = prefs.getString(themeModeStorageKey);
    if (!mounted) {
      return;
    }
    setState(() {
      _prefs = prefs;
      if (storedRate != null) {
        _speechRate = storedRate.clamp(_minSpeechRate, _maxSpeechRate).toDouble();
      }
      if (storedTheme != null) {
        _selectedThemeMode = _themeModeFromString(storedTheme);
        ref.read(themeProvider.notifier).state = _selectedThemeMode;
      }
    });
  }

  Widget _buildLanguageSection(AppLocalizations l10n, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.languageLabel,
          style:
              theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Locale?>(
                value: _selectedLocale,
                isExpanded: true,
                onChanged: (value) => setState(() => _selectedLocale = value),
                items: [
                  _buildLocaleItem(null, '${l10n.languageEnglish} (System)'),
                  ..._supportedLocales.map(
                    (locale) =>
                        _buildLocaleItem(locale, _labelForLocale(locale, l10n)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tema',
          style:
              theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.system, label: Text('Sistem')),
            ButtonSegment(value: ThemeMode.light, label: Text('Terang')),
            ButtonSegment(value: ThemeMode.dark, label: Text('Gelap')),
          ],
          selected: <ThemeMode>{_selectedThemeMode},
          onSelectionChanged: (selection) {
            if (selection.isEmpty) {
              return;
            }
            _onThemeChanged(selection.first);
          },
        ),
      ],
    );
  }

  Widget _buildVoiceSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suara',
          style:
              theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Text(
          'Kecepatan Bicara: ${_speechRate.toStringAsFixed(2)}',
          style: theme.textTheme.bodyMedium,
        ),
        Slider(
          min: _minSpeechRate,
          max: _maxSpeechRate,
          divisions: 18,
          value: _speechRate.clamp(_minSpeechRate, _maxSpeechRate).toDouble(),
          label: _speechRate.toStringAsFixed(2),
          onChanged: _onSpeechRateChanged,
        ),
      ],
    );
  }

  Widget _buildDataPrivacySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data & Privasi',
          style:
              theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Card(
          color: theme.colorScheme.errorContainer
              .withOpacity(theme.brightness == Brightness.dark ? 0.2 : 0.35),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            title: const Text('Hapus Riwayat Obrolan'),
            subtitle: const Text('Menghapus seluruh riwayat percakapan Anda.'),
            trailing: const Icon(Icons.delete_outline),
            onTap: _confirmClearHistory,
          ),
        ),
      ],
    );
  }

  void _onThemeChanged(ThemeMode mode) async {
    setState(() => _selectedThemeMode = mode);
    ref.read(themeProvider.notifier).state = mode;
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(themeModeStorageKey, _themeModeToString(mode));
  }

  void _onSpeechRateChanged(double value) async {
    final clamped = value.clamp(_minSpeechRate, _maxSpeechRate).toDouble();
    setState(() => _speechRate = clamped);
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setDouble(ttsRateStorageKey, clamped);
  }

  Future<void> _confirmClearHistory() async {
    final shouldClear = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Riwayat?'),
            content: const Text(
              'Tindakan ini akan menghapus semua riwayat obrolan yang tersimpan.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldClear) {
      return;
    }

    final repository = ref.read(chatRepositoryProvider);
    final sessionState = ref.read(activeSessionProvider);
    final session = sessionState.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    if (session == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.sessionNotReady)),
      );
      return;
    }

    final chatNotifier = ref.read(chatListProvider.notifier);
    final previousMessages = List<ChatMessage>.from(chatNotifier.state);
    chatNotifier.state = <ChatMessage>[];
    try {
      await repository.clear(sessionId: session.id);
      await ref.read(activeSessionProvider.notifier).selectSession(session.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Riwayat dihapus')),
      );
    } catch (error) {
      chatNotifier.state = previousMessages;
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear history: $error')),
      );
    }
  }

  ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }

  DropdownMenuItem<Locale?> _buildLocaleItem(Locale? locale, String label) {
    return DropdownMenuItem<Locale?>(
      value: locale,
      child: Text(label),
    );
  }

  Widget _buildAboutSection(ThemeData theme) {
    final baseStyle = theme.textTheme.bodyMedium ?? const TextStyle();
    final linkStyle = baseStyle.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
    );
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'Buddy AI is your wellness companion that blends conversational coaching with a responsive 3D avatar to keep your motivation high.',
              style: baseStyle,
            ),
            const SizedBox(height: 8),
            Text(
              'Buddy AIは、会話によるコーチングと反応の良い3Dアバターを組み合わせて、あなたのモチベーションを高め続けるウェルネスパートナーです。',
              style: baseStyle,
            ),
            const SizedBox(height: 16),
            Text(
              'Credits',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _openExternalUrl(_avatarCreditUrl),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '3D avatar: "FREE Annie anime gerl" by FibonacciFox on Sketchfab',
                  style: linkStyle,
                ),
              ),
            ),
            InkWell(
              onTap: () => _openExternalUrl(_backgroundCreditUrl),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Background gradient: Photo by Plufow Le Studio on Unsplash',
                  style: linkStyle,
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _openExternalUrl(_githubUrl),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        _githubIconUrl,
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.link,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'github.com/Rabbani218',
                      style: linkStyle,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelForLocale(Locale locale, AppLocalizations l10n) {
    switch (locale.languageCode) {
      case 'id':
        return l10n.languageIndonesian;
      case 'ja':
        return l10n.languageJapanese;
      default:
        return l10n.languageEnglish;
    }
  }

  Future<void> _savePreference() async {
    setState(() => _isSaving = true);
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final locale = _selectedLocale;
    if (locale == null) {
      await prefs.remove(localeStorageKey);
    } else {
      final code = _serializeLocale(locale);
      await prefs.setString(localeStorageKey, code);
    }
    ref.read(localeProvider.notifier).state = locale;
    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
    }
  }

  String _serializeLocale(Locale locale) {
    final buffer = StringBuffer(locale.languageCode);
    if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
      buffer.write('_');
      buffer.write(locale.countryCode);
    }
    return buffer.toString();
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the link.')),
      );
    }
  }
}
