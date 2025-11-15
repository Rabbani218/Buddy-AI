import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../services/isar_service.dart';
import 'chat_repository.dart';

class IsarChatRepository implements ChatRepository {
	IsarChatRepository(this._ref);

	final Ref _ref;

	Isar get _isar => _ref.read(isarProvider);

	@override
	Future<void> save(ChatMessage message, {required Id sessionId}) async {
		await _isar.writeTxn(() async {
			final session = await _isar.chatSessions.get(sessionId);
			if (session == null) {
				throw IsarError('Session $sessionId not found');
			}
			message.session.value = session;
			await _isar.chatMessages.put(message);
			await message.session.save();
		});
	}

	@override
	Future<List<ChatMessage>> getAll({required Id sessionId}) async {
		return _isar.chatMessages
				.filter()
				.session((q) => q.idEqualTo(sessionId))
				.sortByTimestamp()
				.findAll();
	}

	@override
	Future<List<ChatMessage>> getRecent({required int limit, required Id sessionId}) async {
		final results = await _isar.chatMessages
				.filter()
				.session((q) => q.idEqualTo(sessionId))
				.sortByTimestampDesc()
				.limit(limit)
				.findAll();
		return results.reversed.toList();
	}

	@override
	Future<void> clear({required Id sessionId}) async {
		await _isar.writeTxn(() async {
			final messages = await _isar.chatMessages
					.filter()
					.session((q) => q.idEqualTo(sessionId))
					.findAll();
			final ids = messages.map((m) => m.id).toList();
			await _isar.chatMessages.deleteAll(ids);
		});
	}

	@override
	Future<ChatSession> createSession(String title) async {
		final session = ChatSession(title: title);
		await _isar.writeTxn(() async {
			session.id = await _isar.chatSessions.put(session);
		});
		return session;
	}

	@override
	Future<List<ChatSession>> getSessions() {
		return _isar.chatSessions.where().sortByCreatedAt().findAll();
	}

	@override
	Future<ChatSession?> getSession(Id id) {
		return _isar.chatSessions.get(id);
	}
}
