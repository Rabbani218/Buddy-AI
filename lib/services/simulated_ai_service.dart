import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

class SimulatedAiService {
  SimulatedAiService._internal();

  static final SimulatedAiService _instance = SimulatedAiService._internal();

  factory SimulatedAiService() => _instance;

  Map<String, dynamic>? _scriptCache;
  final Random _random = Random();

  Future<void> _ensureLoaded() async {
    if (_scriptCache != null) {
      return;
    }
    final rawJson = await rootBundle.loadString('assets/data/scripts.json');
    _scriptCache = jsonDecode(rawJson) as Map<String, dynamic>;
  }

  Future<String> getInitialGreeting() async {
    await _ensureLoaded();
    final greeting = (_scriptCache?['greeting'] as String?)?.trim();
    final tips = _extractTips();
    if (greeting == null || greeting.isEmpty) {
      return 'Halo, aku HealthBuddy AI. Apa yang bisa kubantu hari ini?';
    }
    if (tips.isEmpty) {
      return greeting;
    }
    final highlightedTip = tips.first;
    return '$greeting\n\nTips cepat hari ini:\n• $highlightedTip';
  }

  Future<String> getResponse(String userInput) async {
    await _ensureLoaded();
    final normalized = userInput.toLowerCase();
    final scripts = _scriptCache?['responses'] as List<dynamic>? ?? <dynamic>[];
    for (final entry in scripts) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }
      final keywords = (entry['keywords'] as List<dynamic>? ?? <dynamic>[])
          .whereType<String>()
          .map((keyword) => keyword.toLowerCase())
          .toList();
      if (keywords.any((keyword) => normalized.contains(keyword))) {
        final response = entry['response'] as String?;
        if (response != null && response.trim().isNotEmpty) {
          return response.trim();
        }
      }
    }

    final tips = _extractTips();
    if (tips.isNotEmpty) {
      final randomTip = tips[_random.nextInt(tips.length)];
      return 'Terima kasih sudah berbagi. Ini ada saran cepat untukmu:\n• $randomTip';
    }

    final fallback = (_scriptCache?['fallback'] as String?)?.trim();
    return fallback?.isNotEmpty == true
        ? fallback!
        : 'Aku selalu siap menemanimu. Ceritakan apa yang kamu rasakan, ya.';
  }

  List<String> _extractTips() {
    final tips = _scriptCache?['tips'] as List<dynamic>? ?? <dynamic>[];
    return tips
        .whereType<String>()
        .map((tip) => tip.trim())
        .where((tip) => tip.isNotEmpty)
        .toList();
  }
}
