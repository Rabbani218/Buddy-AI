import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';
import '../models/chat_message.dart';
import 'chat_repository.dart';

class PreferencesChatRepository implements ChatRepository {
  PreferencesChatRepository(this._prefs);

  final SharedPreferences _prefs;

  final List<ChatMessage> _messages = <ChatMessage>[];
  int _nextId = 1;
  bool _initialized = false;

  Future<void> _ensureLoaded() async {
    if (_initialized) {
      return;
    }
    final raw = _prefs.getString(chatHistoryStorageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        for (final entry in decoded) {
          if (entry is Map<String, dynamic>) {
            _messages.add(ChatMessage.fromMap(entry));
          } else if (entry is Map) {
            _messages.add(ChatMessage.fromMap(
              entry.map((key, value) => MapEntry(key.toString(), value)),
            ));
          }
        }
      } catch (_) {
        _messages.clear();
      }
    }
    _nextId = _prefs.getInt(chatHistoryNextIdKey) ?? 1;
    if (_messages.isNotEmpty) {
      final highestId = _messages
          .map((message) => message.id ?? 0)
          .fold<int>(0, (prev, element) => element > prev ? element : prev);
      if (highestId >= _nextId) {
        _nextId = highestId + 1;
      }
    }
    _initialized = true;
  }

  Future<void> _persist() async {
    final payload = jsonEncode(_messages.map((m) => m.toMap()).toList());
    await _prefs.setString(chatHistoryStorageKey, payload);
    await _prefs.setInt(chatHistoryNextIdKey, _nextId);
  }

  @override
  Future<void> save(ChatMessage message) async {
    await _ensureLoaded();
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
    await _persist();
  }

  @override
  Future<List<ChatMessage>> getAll() async {
    await _ensureLoaded();
    final result = List<ChatMessage>.from(_messages);
    result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return result;
  }

  @override
  Future<List<ChatMessage>> getRecent({required int limit}) async {
    final all = await getAll();
    if (all.length <= limit) {
      return all;
    }
    return all.sublist(all.length - limit);
  }

  @override
  Future<void> clear() async {
    await _ensureLoaded();
    _messages.clear();
    _nextId = 1;
    await _prefs.remove(chatHistoryStorageKey);
    await _prefs.remove(chatHistoryNextIdKey);
  }
}
