import 'package:isar/isar.dart';

part 'chat_session.g.dart';

@collection
class ChatSession {
  ChatSession({
    required this.title,
    DateTime? createdAtOverride,
  }) : createdAt = createdAtOverride ?? DateTime.now();

  Id id = Isar.autoIncrement;
  String title;
  DateTime createdAt;
}
