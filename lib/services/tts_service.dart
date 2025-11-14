import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  TtsService() : _flutterTts = FlutterTts();

  final FlutterTts _flutterTts;
  bool _isConfigured = false;
  String? _activeLanguage;
  Locale? _requestedLocale;

  Future<void> _configure() async {
    if (_isConfigured) {
      return;
    }
    _isConfigured = true;

    if (!kIsWeb) {
      await _flutterTts.setSharedInstance(true);
    }
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setPitch(1.02);
    await _flutterTts.setSpeechRate(0.42);
    await _flutterTts.setVolume(0.9);
  }

  Future<void> updateLocale(Locale? locale) async {
    _requestedLocale = locale;
    await _configure();

    final languages = await _flutterTts.getLanguages;
    final available = languages is List ? languages.cast<String>() : <String>[];

    final targetTag = _preferredLanguageTag(locale, available);
    if (_activeLanguage == targetTag) {
      return;
    }
    if (available.isEmpty) {
      _activeLanguage = targetTag;
      return;
    }
    await _flutterTts.setLanguage(targetTag);
    _activeLanguage = targetTag;
  }

  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    await _configure();
    if (_activeLanguage == null) {
      await updateLocale(_requestedLocale);
    }
    await _flutterTts.stop();
    await _flutterTts.speak(trimmed);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  void dispose() {
    _flutterTts.stop();
  }

  String _preferredLanguageTag(Locale? locale, List<String> available) {
    final fallback = const Locale('en', 'US');
    final effective = locale ?? _requestedLocale ?? fallback;
    final tag = effective.toLanguageTag();
    final normalized = tag;
    if (available.contains(normalized)) {
      return normalized;
    }

    final alt = _alternateTagForLocale(effective);
    if (available.contains(alt)) {
      return alt;
    }

    if (effective.languageCode == 'id') {
      const altId = 'id-ID';
      if (available.contains(altId)) {
        return altId;
      }
    }

    if (effective.languageCode == 'ja') {
      const altJa = 'ja-JP';
      if (available.contains(altJa)) {
        return altJa;
      }
    }

    return available.contains('en-US')
        ? 'en-US'
        : (available.isNotEmpty ? available.first : normalized);
  }

  String _alternateTagForLocale(Locale locale) {
    final language = locale.languageCode;
    final country = locale.countryCode ?? '';
    if (country.isEmpty) {
      switch (language) {
        case 'en':
          return 'en-US';
        case 'id':
          return 'id-ID';
        case 'ja':
          return 'ja-JP';
        default:
          return '$language-${language.toUpperCase()}';
      }
    }
    return '$language-$country';
  }
}
