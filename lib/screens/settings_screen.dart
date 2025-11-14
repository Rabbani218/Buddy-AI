import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:healthbuddy_ai/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/storage_keys.dart';
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
  static const String _githubUrl = 'https://github.com/Rabbani218';
  static const String _githubIconUrl =
      'https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png';
  static const String _avatarCreditUrl =
      'https://sketchfab.com/3d-models/free-annie-anime-gerl-490a8417cac946899eac86fba72cc210';
  static const String _backgroundCreditUrl =
      'https://unsplash.com/id/foto/gambar-buram-dari-latar-belakang-biru-dan-merah-muda-bUtAqPi-wz4';

  Locale? _selectedLocale;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedLocale = ref.read(localeProvider);
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.languageLabel,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Locale?>(
                    value: _selectedLocale,
                    isExpanded: true,
                    onChanged: (value) =>
                        setState(() => _selectedLocale = value),
                    items: [
                      _buildLocaleItem(
                          null, l10n.languageEnglish + ' (System)'),
                      ..._supportedLocales.map(
                        (locale) => _buildLocaleItem(
                            locale, _labelForLocale(locale, l10n)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildAboutSection(theme),
            const Spacer(),
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
    final prefs = await SharedPreferences.getInstance();
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
