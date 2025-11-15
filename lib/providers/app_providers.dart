import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../repositories/chat_repository.dart';
import '../repositories/isar_chat_repository.dart';
import '../repositories/memory_chat_repository.dart';
import '../services/gemini_service.dart';
import '../services/isar_service.dart';
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
  (ref) {
    final repository = ref.watch(chatRepositoryProvider);
    return GeminiService(repository: repository);
  },
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

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  if (kIsWeb) {
    return InMemoryChatRepository();
  }
  return IsarChatRepository(ref);
});

final sessionListProvider = FutureProvider<List<ChatSession>>(
  (ref) async {
    final repository = ref.watch(chatRepositoryProvider);
    return repository.getSessions();
  },
);

final activeSessionProvider =
    StateNotifierProvider<ActiveSessionNotifier, AsyncValue<ChatSession>>(
  (ref) {
    final notifier = ActiveSessionNotifier(ref);
    notifier.initialize();
    return notifier;
  },
);

final localeProvider = StateProvider<Locale?>(
  (ref) => null,
);

final themeProvider = StateProvider<ThemeMode>(
  (ref) => ThemeMode.system,
);

class ActiveSessionNotifier extends StateNotifier<AsyncValue<ChatSession>> {
  ActiveSessionNotifier(this._ref)
      : super(const AsyncValue.loading());

  final Ref _ref;

  ChatRepository get _repository => _ref.read(chatRepositoryProvider);

  Future<void> initialize() async {
    state = const AsyncValue.loading();
    try {
      final sessions = await _repository.getSessions();
      final session = sessions.isEmpty
          ? await _repository.createSession(_defaultTitle())
          : sessions.last;
      state = AsyncValue.data(session);
      _ref.invalidate(sessionListProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> selectSession(Id id) async {
    state = const AsyncValue.loading();
    try {
      final session = await _repository.getSession(id);
      if (session == null) {
        throw StateError('Sesi dengan id $id tidak ditemukan');
      }
      state = AsyncValue.data(session);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<ChatSession> startNewSession({String? title}) async {
    state = const AsyncValue.loading();
    try {
      final session = await _repository.createSession(title ?? _defaultTitle());
      state = AsyncValue.data(session);
      _ref.invalidate(sessionListProvider);
      return session;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> refreshSessions() async {
    _ref.invalidate(sessionListProvider);
  }

  String _defaultTitle() {
    final now = DateTime.now();
    final twoDigits = (int value) => value.toString().padLeft(2, '0');
    final datePart =
        '${now.year}-${twoDigits(now.month)}-${twoDigits(now.day)} ${twoDigits(now.hour)}:${twoDigits(now.minute)}';
    return 'Percakapan $datePart';
  }
}
