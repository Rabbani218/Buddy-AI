import 'package:isar/isar.dart';

import '../models/chat_message.dart';
import '../models/chat_session.dart';

abstract class ChatRepository {
  Future<List<ChatMessage>> getAll({required Id sessionId});

  Future<List<ChatMessage>> getRecent({required int limit, required Id sessionId});

  Future<void> save(ChatMessage message, {required Id sessionId});

  Future<void> clear({required Id sessionId});

  Future<ChatSession> createSession(String title);

  Future<List<ChatSession>> getSessions();

  Future<ChatSession?> getSession(Id id);
}
