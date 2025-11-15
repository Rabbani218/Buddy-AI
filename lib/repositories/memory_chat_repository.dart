import 'package:isar/isar.dart';

import '../models/chat_message.dart';
import '../models/chat_session.dart';
import 'chat_repository.dart';

class InMemoryChatRepository implements ChatRepository {
  final Map<Id, List<ChatMessage>> _messagesBySession = <Id, List<ChatMessage>>{};
  final Map<Id, ChatSession> _sessions = <Id, ChatSession>{};
  int _nextMessageId = 1;
  int _nextSessionId = 1;

  @override
  Future<void> save(ChatMessage message, {required Id sessionId}) async {
    final sessionMessages =
        _messagesBySession.putIfAbsent(sessionId, () => <ChatMessage>[]);
    if (!_sessions.containsKey(sessionId)) {
      throw StateError('Session $sessionId not found');
    }
    if (message.id == Isar.autoIncrement) {
      message.id = _nextMessageId++;
      sessionMessages.add(message);
    } else {
      final index = sessionMessages.indexWhere((item) => item.id == message.id);
      if (index >= 0) {
        sessionMessages[index] = message;
      } else {
        sessionMessages.add(message);
      }
    }
  }

  @override
  Future<List<ChatMessage>> getAll({required Id sessionId}) async {
    final sessionMessages = _messagesBySession[sessionId] ?? <ChatMessage>[];
    final result = List<ChatMessage>.from(sessionMessages);
    result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return result;
  }

  @override
  Future<List<ChatMessage>> getRecent({required int limit, required Id sessionId}) async {
    final result = await getAll(sessionId: sessionId);
    if (result.length <= limit) {
      return result;
    }
    return result.sublist(result.length - limit);
  }

  @override
  Future<void> clear({required Id sessionId}) async {
    _messagesBySession[sessionId]?.clear();
  }

  @override
  Future<ChatSession> createSession(String title) async {
    final session = ChatSession(title: title)..id = _nextSessionId++;
    _sessions[session.id] = session;
    _messagesBySession.putIfAbsent(session.id, () => <ChatMessage>[]);
    return session;
  }

  @override
  Future<List<ChatSession>> getSessions() async {
    final sessions = _sessions.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sessions;
  }

  @override
  Future<ChatSession?> getSession(Id id) async {
    return _sessions[id];
  }
}
