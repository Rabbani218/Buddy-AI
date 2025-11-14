import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message.dart';
import '../repositories/chat_repository.dart';
import '../services/gemini_service.dart';
import '../services/tts_service.dart';

final chatListProvider = StateProvider<List<ChatMessage>>(
  (ref) => <ChatMessage>[],
);

final animationProvider = StateProvider<String>(
  (ref) => 'Idle',
);

final isAiThinkingProvider = StateProvider<bool>(
  (ref) => false,
);

final geminiServiceProvider = Provider<GeminiService>(
  (ref) => GeminiService(),
);

final ttsServiceProvider = Provider<TtsService>(
  (ref) {
    final service = TtsService();
    ref.onDispose(service.dispose);
    final locale = ref.watch(localeProvider);
    service.updateLocale(locale);
    ref.listen<Locale?>(localeProvider, (previous, next) {
      service.updateLocale(next);
    });
    return service;
  },
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => throw UnimplementedError('Chat repository not initialized'),
);

final localeProvider = StateProvider<Locale?>(
  (ref) => null,
);
