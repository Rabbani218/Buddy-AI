import 'dart:async';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:isar/isar.dart';

import '../constants/api_key.dart';
import '../models/chat_message.dart';
import '../repositories/chat_repository.dart';
import 'simulated_ai_service.dart';

class GeminiService {
  GeminiService({String? apiKey, ChatRepository? repository})
      : _apiKey = (apiKey ?? geminiApiKey).trim(),
        _repository = repository;

  final String _apiKey;
  final ChatRepository? _repository;
  GenerativeModel? _model;

  static const String _personaInstruction =
      'Kamu adalah HealthBuddy, seorang asisten kesehatan AI yang sangat ramah, '
      'empatik, dan suportif. Tujuanmu adalah membantu pengguna merasa lebih baik '
      'secara mental dan fisik. Gunakan bahasa yang hangat dan kasual (sedikit '
      'slang tidak apa-apa), berikan respons yang memotivasi tanpa menghakimi, '
      'sertakan saran praktis, dan selalu mulai percakapan dengan sapaan yang ramah.';

  bool get _hasValidKey =>
      _apiKey.isNotEmpty && _apiKey != 'API_KEY_KAMU_DI_SINI';

  GenerativeModel _ensureModel() {
    return _model ??= GenerativeModel(
      model: 'gemini-1.0-pro-vision',
      apiKey: _apiKey,
      systemInstruction: Content.text(_personaInstruction),
    );
  }

  Future<String> getChatResponse(
    String prompt, {
    required Id sessionId,
    ChatRepository? repository,
    List<int>? imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    final effectiveRepository = repository ?? _repository;
    if (effectiveRepository == null) {
      throw const GeminiServiceException(
        'Chat repository is required to build conversation context.',
      );
    }
    if (!_hasValidKey) {
      return SimulatedAiService().getResponse(prompt);
    }
    final buffer = StringBuffer();
    try {
      await for (final chunk in streamChatResponse(
        prompt,
        sessionId: sessionId,
        repository: effectiveRepository,
        imageBytes: imageBytes,
        mimeType: mimeType,
      )) {
        buffer.write(chunk);
      }
    } on GeminiSafetyException catch (error) {
      return error.message;
    } on GeminiServiceException catch (error) {
      if (_isNotFoundError(error.message)) {
        return SimulatedAiService().getResponse(prompt);
      }
      return 'Terjadi kendala pada layanan Gemini: ${error.message}';
    }

    final output = buffer.toString().trim();
    if (output.isEmpty) {
      return SimulatedAiService().getResponse(prompt);
    }
    return output;
  }

  Stream<String> streamChatResponse(
    String prompt, {
    required Id sessionId,
    ChatRepository? repository,
    List<int>? imageBytes,
    String mimeType = 'image/jpeg',
  }) {
    if (!_hasValidKey) {
      return _simulateStreamDirect(prompt);
    }

    final effectiveRepository = repository ?? _repository;
    if (effectiveRepository == null) {
      return Stream.error(
        const GeminiServiceException(
          'Chat repository is required to build conversation context.',
        ),
      );
    }

    final controller = StreamController<String>();

    () async {
      try {
        final historyContent =
            await _buildHistoryContent(effectiveRepository, sessionId);

        final requestContent = _contentFromUser(
          prompt,
          imageBytes: imageBytes,
          mimeType: mimeType,
        );

        final chat = _ensureModel().startChat(history: historyContent);
        final stream = chat.sendMessageStream(requestContent);
        var accumulated = '';
        var blocked = false;

        await for (final event in stream) {
          if (event.promptFeedback?.blockReason != null) {
            blocked = true;
            continue;
          }

          final candidates = event.candidates;
          if (candidates == null || candidates.isEmpty) {
            continue;
          }

          final candidate = candidates.first;

          final text = _extractText(candidate);
          if (text == null || text.isEmpty) {
            continue;
          }

          if (text.length <= accumulated.length) {
            continue;
          }

          final newSegment = text.substring(accumulated.length);
          accumulated = text;
          if (newSegment.isNotEmpty) {
            controller.add(newSegment);
          }
        }

        if (blocked) {
          controller.addError(
            const GeminiSafetyException(
              'Maaf, respons AI diblokir oleh sistem keamanan Gemini. Coba modifikasi pertanyaannya.',
            ),
          );
        }
        await controller.close();
      } on GeminiServiceException catch (error) {
        if (_isNotFoundError(error.message)) {
          await _emitSimulatedResponse(controller, prompt);
          return;
        }
        controller.addError(error);
        await controller.close();
      } on GenerativeAIException catch (error) {
        if (_isNotFoundError(error.message)) {
          await _emitSimulatedResponse(controller, prompt);
          return;
        }
        controller.addError(GeminiServiceException(error.message));
        await controller.close();
      } catch (error) {
        final message = error.toString();
        if (_isNotFoundError(message)) {
          await _emitSimulatedResponse(controller, prompt);
          return;
        }
        controller.addError(GeminiServiceException(message));
        await controller.close();
      }
    }();

    return controller.stream;
  }

  Stream<String> _simulateStreamDirect(String prompt) async* {
    final response = await SimulatedAiService().getResponse(prompt);
    const chunkLength = 64;
    for (var i = 0; i < response.length; i += chunkLength) {
      yield response.substring(
        i,
        i + chunkLength > response.length ? response.length : i + chunkLength,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
  }

  Future<void> _emitSimulatedResponse(
    StreamController<String> controller,
    String prompt,
  ) async {
    final response = await SimulatedAiService().getResponse(prompt);
    const chunkLength = 64;
    for (var i = 0; i < response.length; i += chunkLength) {
      controller.add(response.substring(
        i,
        i + chunkLength > response.length ? response.length : i + chunkLength,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    await controller.close();
  }

  bool _isNotFoundError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('not found') ||
        normalized.contains('unsupported') ||
        normalized.contains('404');
  }

  String? _extractText(Candidate candidate) {
    final parts = candidate.content?.parts;
    if (parts == null || parts.isEmpty) {
      return null;
    }
    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is TextPart) {
        if (buffer.isNotEmpty) {
          buffer.writeln();
        }
        buffer.write(part.text.trim());
      }
    }
    final text = buffer.toString().trim();
    return text.isEmpty ? null : text;
  }

  Future<List<Content>> _buildHistoryContent(
    ChatRepository repository,
    Id sessionId,
  ) async {
    final historyMessages =
        await repository.getAll(sessionId: sessionId);

    if (historyMessages.isEmpty) {
      return const [];
    }

    historyMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final history = <Content>[];
    for (final message in historyMessages) {
      final text = message.text.trim();
      final hasImage =
          message.imageBytes != null && message.imageBytes!.isNotEmpty;
      final parts = <Part>[];

      if (text.isNotEmpty) {
        parts.add(TextPart(text));
      }
      if (hasImage) {
        parts.add(_imagePart(message.imageBytes!, mimeType: 'image/jpeg'));
      }

      if (parts.isEmpty) {
        continue;
      }

      if (message.isFromUser) {
        if (!hasImage && parts.length == 1 && parts.first is TextPart) {
          history.add(Content.text(text));
        } else {
          history.add(Content('user', parts));
        }
      } else {
        history.add(Content('model', parts));
      }
    }

    return history;
  }

  Content _contentFromUser(
    String prompt, {
    List<int>? imageBytes,
    String mimeType = 'image/jpeg',
  }) {
    final trimmedPrompt = prompt.trim();
    final hasImage = imageBytes != null && imageBytes.isNotEmpty;

    if (!hasImage) {
      return Content.text(trimmedPrompt);
    }

    final parts = <Part>[];
    if (trimmedPrompt.isNotEmpty) {
      parts.add(TextPart(trimmedPrompt));
    }
    parts.add(_imagePart(imageBytes!, mimeType: mimeType));
    return Content('user', parts);
  }

  Part _imagePart(List<int> bytes, {required String mimeType}) {
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    return DataPart(mimeType, data);
  }

  Future<String> sendMessage({
    required String prompt,
    required Id sessionId,
    Uint8List? imageBytes,
  }) async {
    if (!_hasValidKey) {
      return SimulatedAiService().getResponse(prompt);
    }

    final effectiveRepository = _repository;
    final history = effectiveRepository != null
        ? await _buildHistoryContent(effectiveRepository, sessionId)
        : const <Content>[];

    final trimmedPrompt = prompt.trim();
    final content = _contentFromUser(
      trimmedPrompt,
      imageBytes: imageBytes?.toList(growable: false),
      mimeType: 'image/jpeg',
    );

    try {
      final chat = _ensureModel().startChat(history: history);
      final response = await chat.sendMessage(content);
      final feedback = response.promptFeedback;
      if (feedback?.blockReason != null) {
        throw const GeminiSafetyException(
          'Maaf, respons AI diblokir oleh sistem keamanan Gemini. Coba modifikasi pertanyaannya.',
        );
      }

      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        return SimulatedAiService().getResponse(prompt);
      }
      return text;
    } on GeminiSafetyException {
      rethrow;
    } on GenerativeAIException catch (error) {
      if (_isNotFoundError(error.message)) {
        return SimulatedAiService().getResponse(prompt);
      }
      throw GeminiServiceException(error.message);
    } catch (error) {
      final message = error.toString();
      if (_isNotFoundError(message)) {
        return SimulatedAiService().getResponse(prompt);
      }
      throw GeminiServiceException(message);
    }
  }

}

class GeminiServiceException implements Exception {
  const GeminiServiceException(this.message);
  final String message;
}

class GeminiSafetyException extends GeminiServiceException {
  const GeminiSafetyException(String message) : super(message);
}
