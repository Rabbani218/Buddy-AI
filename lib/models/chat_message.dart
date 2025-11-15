import 'package:isar/isar.dart';

import 'chat_session.dart';

part 'chat_message.g.dart';

@collection
class ChatMessage {
  ChatMessage({
    required this.text,
    required this.isFromUser,
    DateTime? createdAt,
    List<int>? imageBytes,
  }) {
    timestamp = createdAt ?? DateTime.now();
    this.imageBytes = imageBytes;
  }

  Id id = Isar.autoIncrement;
  String text;
  bool isFromUser;
  DateTime timestamp = DateTime.now();
  List<int>? imageBytes;
  final session = IsarLink<ChatSession>();

  ChatMessage copyWith({
    Id? id,
    String? text,
    bool? isFromUser,
    DateTime? timestamp,
    List<int>? imageBytes,
  }) {
    final updated = ChatMessage(
      text: text ?? this.text,
      isFromUser: isFromUser ?? this.isFromUser,
      imageBytes: imageBytes ?? this.imageBytes,
    );
    updated.id = id ?? this.id;
    updated.timestamp = timestamp ?? this.timestamp;
    return updated;
  }
}
