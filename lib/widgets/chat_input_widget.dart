import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:healthbuddy_ai/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/app_assets.dart';
import '../models/chat_message.dart';
import '../providers/app_providers.dart';
import '../services/gemini_service.dart';

class ChatInputWidget extends ConsumerStatefulWidget {
  const ChatInputWidget({super.key});

  @override
  ConsumerState<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends ConsumerState<ChatInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isSending = false;
  bool _isListening = false;
  bool _speechInitialized = false;
  Uint8List? _pendingImageBytes;
  String _pendingImageMime = 'image/jpeg';

  @override
  void dispose() {
    _speechToText.stop();
    _speechToText.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textColor =
        theme.brightness == Brightness.dark ? Colors.white : Colors.black87;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_pendingImageBytes != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      _pendingImageBytes!,
                      height: 72,
                      width: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: _isSending
                          ? null
                          : () {
                              setState(() => _pendingImageBytes = null);
                            },
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _controller,
                  style: TextStyle(color: textColor),
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onFieldSubmitted: (_) => _handleSend(context),
                  decoration: InputDecoration(
                    hintText: l10n.chatPlaceholder,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    hintStyle: theme.inputDecorationTheme.hintStyle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: l10n.attachImageTooltip,
                onPressed: _isSending ? null : _showImagePickerSheet,
                icon: const Icon(Icons.attach_file_rounded),
                color: textColor.withOpacity(0.85),
              ),
              IconButton(
                tooltip: _isListening
                    ? l10n.voiceInputTooltipStop
                    : l10n.voiceInputTooltipStart,
                onPressed: _isSending ? null : () => _toggleListening(context),
                icon: SvgPicture.asset(
                  _isListening ? AppAssets.iconStop : AppAssets.iconMic,
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                    _isListening
                        ? theme.colorScheme.secondary
                        : textColor.withOpacity(0.85),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 52,
                width: 52,
                child: ElevatedButton(
                  onPressed: _isSending ? null : () => _handleSend(context),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                    backgroundColor: theme.colorScheme.secondary,
                  ),
                  child: _isSending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : SvgPicture.asset(
                          AppAssets.iconSend,
                          width: 22,
                          height: 22,
                          colorFilter: const ColorFilter.mode(
                              Colors.white, BlendMode.srcIn),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleSend(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final rawText = _controller.text.trim();
    final hasImage = _pendingImageBytes != null;
    if ((rawText.isEmpty && !hasImage) || _isSending) {
      return;
    }

    if (_isListening) {
      await _speechToText.stop();
      if (mounted) {
        setState(() => _isListening = false);
      }
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSending = true);

    final repository = ref.read(chatRepositoryProvider);
    final geminiService = ref.read(geminiServiceProvider);
    final ttsService = ref.read(ttsServiceProvider);
    final chatNotifier = ref.read(chatListProvider.notifier);
    final animationNotifier = ref.read(animationProvider.notifier);
    final thinkingNotifier = ref.read(isAiThinkingProvider.notifier);

    final imageBytesList = _pendingImageBytes?.toList();
    final userMessage = ChatMessage(
      text: rawText,
      isFromUser: true,
      imageBytes: imageBytesList,
    );
    chatNotifier.state = [...chatNotifier.state, userMessage];
    await repository.save(userMessage);
    chatNotifier.state = [...chatNotifier.state];

    animationNotifier.state = 'Talking';
    thinkingNotifier.state = true;

    final aiMessage = ChatMessage(text: '', isFromUser: false);
    chatNotifier.state = [...chatNotifier.state, aiMessage];

    final buffer = StringBuffer();
    var shouldSpeak = true;

    try {
      await for (final chunk in geminiService.streamChatResponse(
        rawText,
        repository: repository,
        imageBytes: imageBytesList,
        mimeType: _pendingImageMime,
      )) {
        if (chunk.trim().isEmpty) {
          continue;
        }
        buffer.write(chunk);
        aiMessage.text = buffer.toString();
        aiMessage.timestamp = DateTime.now();
        chatNotifier.state = [...chatNotifier.state];
      }
    } on GeminiSafetyException catch (error) {
      shouldSpeak = false;
      aiMessage.text = error.message;
      chatNotifier.state = [...chatNotifier.state];
    } on GeminiServiceException catch (error) {
      shouldSpeak = false;
      aiMessage.text = l10n.geminiServiceError(error.message);
      chatNotifier.state = [...chatNotifier.state];
    } catch (_) {
      shouldSpeak = false;
      aiMessage.text = l10n.geminiTechnicalIssue;
      chatNotifier.state = [...chatNotifier.state];
    } finally {
      if (aiMessage.text.trim().isEmpty) {
        final synthesized = buffer.toString().trim();
        aiMessage.text =
            synthesized.isEmpty ? l10n.geminiEmptyResponse : synthesized;
        aiMessage.timestamp = DateTime.now();
        chatNotifier.state = [...chatNotifier.state];
      }

      await repository.save(aiMessage);
      chatNotifier.state = [...chatNotifier.state];

      thinkingNotifier.state = false;
      animationNotifier.state = 'Idle';
      if (shouldSpeak) {
        final spokenText = buffer.toString().trim();
        if (spokenText.isNotEmpty) {
          try {
            await ttsService.speak(spokenText);
          } catch (_) {
            // Ignore TTS errors to keep conversation flowing.
          }
        }
      }

      if (mounted) {
        setState(() {
          _isSending = false;
          _pendingImageBytes = null;
        });
        _controller.clear();
      }
    }
  }

  Future<void> _showImagePickerSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext)!;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: Text(l10n.galleryLabel),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: Text(l10n.cameraLabel),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    final XFile? file;
    try {
      file = await _imagePicker.pickImage(
          source: source, maxWidth: 1280, imageQuality: 85);
    } catch (_) {
      return;
    }

    if (file == null) {
      return;
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      return;
    }

    final mimeType = _inferMimeType(file.path);
    setState(() {
      _pendingImageBytes = bytes;
      _pendingImageMime = mimeType;
    });
  }

  Future<void> _toggleListening(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    if (_isListening) {
      await _speechToText.stop();
      if (mounted) {
        setState(() => _isListening = false);
      }
      return;
    }

    if (!_speechInitialized) {
      final initialized = await _speechToText.initialize(
        onError: (error) {
          if (!mounted) {
            return;
          }
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.voiceInputError(error.errorMsg))),
          );
        },
        onStatus: (status) {
          if (!mounted) {
            return;
          }
          if (status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
      );

      if (!initialized) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.voiceInputPermissionDenied)),
          );
        }
        return;
      }
      _speechInitialized = true;
    }

    final selectedLocale = ref.read(localeProvider);
    final localeId = await _resolveLocale(selectedLocale);

    setState(() => _isListening = true);
    await _speechToText.listen(
      localeId: localeId,
      onResult: _onSpeechResult,
    );
  }

  Future<String> _resolveLocale(Locale? target) async {
    final locales = await _speechToText.locales();
    final desired = _localeIdFor(target);
    if (desired != null &&
        locales.any((locale) => locale.localeId == desired)) {
      return desired;
    }

    const fallbacks = ['id_ID', 'ja_JP', 'en_US'];
    for (final fallback in fallbacks) {
      if (locales.any((locale) => locale.localeId == fallback)) {
        return fallback;
      }
    }

    return locales.isNotEmpty ? locales.first.localeId : 'en_US';
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final recognizedWords = result.recognizedWords.trim();
    if (recognizedWords.isEmpty) {
      return;
    }
    setState(() {
      _controller
        ..text = recognizedWords
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      if (result.finalResult) {
        _isListening = false;
      }
    });
  }

  String? _localeIdFor(Locale? locale) {
    if (locale == null) {
      return null;
    }
    final language = locale.languageCode;
    final country = locale.countryCode ?? language.toUpperCase();
    return '${language}_$country';
  }

  String _inferMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }
}
