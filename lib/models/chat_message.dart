import 'dart:convert';

class ChatMessage {
  ChatMessage({
    this.id,
    required this.text,
    required this.isFromUser,
    DateTime? timestamp,
    this.imageBytes,
  }) : timestamp = timestamp ?? DateTime.now();

  int? id;
  String text;
  bool isFromUser;
  DateTime timestamp;
  List<int>? imageBytes;

  ChatMessage copyWith({
    int? id,
    String? text,
    bool? isFromUser,
    DateTime? timestamp,
    List<int>? imageBytes,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isFromUser: isFromUser ?? this.isFromUser,
      timestamp: timestamp ?? this.timestamp,
      imageBytes: imageBytes ?? this.imageBytes,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'text': text,
      'isFromUser': isFromUser,
      'timestamp': timestamp.toIso8601String(),
      'image': imageBytes != null ? base64Encode(imageBytes!) : null,
    };
  }

  static ChatMessage fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as int?,
      text: (map['text'] as String?) ?? '',
      isFromUser: map['isFromUser'] as bool? ?? false,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      imageBytes:
          map['image'] != null ? base64Decode(map['image'] as String) : null,
    );
  }
}
