import '../models/chat_message.dart';
import 'chat_repository.dart';

class InMemoryChatRepository implements ChatRepository {
  final List<ChatMessage> _messages = <ChatMessage>[];
  int _nextId = 1;

  @override
  Future<void> save(ChatMessage message) async {
    if (message.id == null) {
      message.id = _nextId++;
      _messages.add(message);
    } else {
      final index = _messages.indexWhere((item) => item.id == message.id);
      if (index >= 0) {
        _messages[index] = message;
      } else {
        _messages.add(message);
      }
    }
  }

  @override
  Future<List<ChatMessage>> getAll() async {
    final result = List<ChatMessage>.from(_messages);
    result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return result;
  }

  @override
  Future<List<ChatMessage>> getRecent({required int limit}) async {
    final result = await getAll();
    if (result.length <= limit) {
      return result;
    }
    return result.sublist(result.length - limit);
  }

  @override
  Future<void> clear() async {
    _messages.clear();
    _nextId = 1;
  }
}
