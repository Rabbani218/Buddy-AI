import 'package:shared_preferences/shared_preferences.dart';

import 'package:isar/isar.dart';

import '../models/chat_message.dart';
import '../models/chat_session.dart';
import 'chat_repository.dart';

/// Legacy repository retained only for backward compatibility. The
/// application now relies on [IsarChatRepository]; this implementation simply
/// throws to prevent accidental usage.
class PreferencesChatRepository implements ChatRepository {
  PreferencesChatRepository(SharedPreferences prefs)
      : _error = UnsupportedError(
          'PreferencesChatRepository has been retired. Use IsarChatRepository instead.',
        );

  final UnsupportedError _error;

  @override
    Future<void> save(ChatMessage message, {required Id sessionId}) =>
      Future.error(_error);

  @override
    Future<List<ChatMessage>> getAll({required Id sessionId}) =>
      Future.error(_error);

  @override
    Future<List<ChatMessage>> getRecent({required int limit, required Id sessionId}) =>
      Future.error(_error);

  @override
    Future<void> clear({required Id sessionId}) => Future.error(_error);

    @override
    Future<ChatSession> createSession(String title) => Future.error(_error);

    @override
    Future<List<ChatSession>> getSessions() => Future.error(_error);

    @override
    Future<ChatSession?> getSession(Id id) => Future.error(_error);
}
