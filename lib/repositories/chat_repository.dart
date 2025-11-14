import '../models/chat_message.dart';

abstract class ChatRepository {
  Future<List<ChatMessage>> getAll();

  Future<List<ChatMessage>> getRecent({required int limit});

  Future<void> save(ChatMessage message);

  Future<void> clear();
}
