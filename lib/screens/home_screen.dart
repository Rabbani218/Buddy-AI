import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:healthbuddy_ai/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../core/app_assets.dart';
import '../models/chat_message.dart';
import '../providers/app_providers.dart';
import '../screens/settings_screen.dart';
import '../widgets/chat_input_widget.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/avatar_animation_controller_stub.dart'
  if (dart.library.html) '../widgets/avatar_animation_controller_web.dart';
import '../widgets/avatar_web_asset_loader_stub.dart'
  if (dart.library.html) '../widgets/avatar_web_asset_loader_web.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _loadHistory();
      await _ensureGreeting();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final repository = ref.read(chatRepositoryProvider);
    final history = await repository.getAll();
    ref.read(chatListProvider.notifier).state = history;
  }

  Future<void> _ensureGreeting() async {
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final chatNotifier = ref.read(chatListProvider.notifier);
    if (chatNotifier.state.isNotEmpty) {
      return;
    }

    ref.read(isAiThinkingProvider.notifier).state = true;
    ref.read(animationProvider.notifier).state = 'Talking';

    final repository = ref.read(chatRepositoryProvider);
    try {
      final greetingText =
          await ref.read(geminiServiceProvider).getChatResponse(
                l10n.greetingPrompt,
                repository: repository,
              );

      final greetingMessage = ChatMessage(
        text: greetingText,
        isFromUser: false,
      );

      chatNotifier.state = [...chatNotifier.state, greetingMessage];
      await repository.save(greetingMessage);
      chatNotifier.state = [...chatNotifier.state];
    } catch (_) {
      final fallback = ChatMessage(
        text: l10n.greetingFallback,
        isFromUser: false,
      );
      chatNotifier.state = [...chatNotifier.state, fallback];
      await repository.save(fallback);
      chatNotifier.state = [...chatNotifier.state];
    } finally {
      ref.read(isAiThinkingProvider.notifier).state = false;
      ref.read(animationProvider.notifier).state = 'Idle';
    }
  }

  Future<void> _startNewSession() async {
    final repository = ref.read(chatRepositoryProvider);
    await ref.read(ttsServiceProvider).stop();
    await repository.clear();
    ref.read(chatListProvider.notifier).state = <ChatMessage>[];
    ref.read(isAiThinkingProvider.notifier).state = false;
    ref.read(animationProvider.notifier).state = 'Idle';
    if (mounted) {
      await _ensureGreeting();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final messages = ref.watch(chatListProvider);
    final isThinking = ref.watch(isAiThinkingProvider);
    final brightness = Theme.of(context).brightness;
    final iconColor = Theme.of(context).iconTheme.color ??
        (brightness == Brightness.dark ? Colors.white : Colors.black87);
    final overlayGradient = brightness == Brightness.dark
        ? [Colors.black.withOpacity(0.7), Colors.black.withOpacity(0.55)]
        : [Colors.white.withOpacity(0.35), Colors.white.withOpacity(0.15)];
    final chatPanelColor = brightness == Brightness.dark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.05);
    final chatBorderColor =
        brightness == Brightness.dark ? Colors.white24 : Colors.black26;

    if (messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            icon: SvgPicture.asset(
              AppAssets.iconSettings,
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
          ),
          IconButton(
            tooltip: l10n.newSessionTooltip,
            onPressed: _startNewSession,
            icon: SvgPicture.asset(
              AppAssets.iconReset,
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 4),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.favorite, color: Colors.pinkAccent),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppAssets.bgMain,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: overlayGradient,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Center(
            child: _BackgroundAvatar(isThinking: isThinking),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: chatPanelColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: chatBorderColor, width: 1),
                      ),
                      child: messages.isEmpty
                          ? Center(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 32,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SvgPicture.asset(
                                      AppAssets.illEmptyState,
                                      height: 150,
                                    ),
                                    const SizedBox(height: 20),
                                    const CircularProgressIndicator(),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              reverse: true,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              physics: const BouncingScrollPhysics(),
                              itemCount: messages.length + (isThinking ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (isThinking && index == 0) {
                                  return const _AiTypingBubble();
                                }
                                final effectiveIndex =
                                    isThinking ? index - 1 : index;
                                final message = messages[
                                    messages.length - 1 - effectiveIndex];
                                return ChatMessageBubble(message: message);
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const ChatInputWidget(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundAvatar extends StatefulWidget {
  const _BackgroundAvatar({required this.isThinking});

  final bool isThinking;

  @override
  State<_BackgroundAvatar> createState() => _BackgroundAvatarState();
}

class _BackgroundAvatarState extends State<_BackgroundAvatar> {
  static const String _viewerElementId = 'background-avatar-viewer';
  static const Duration _animationRetryDelay = Duration(milliseconds: 150);
  static const int _maxAnimationRetries = 8;
  String? _modelSrc;
  String? _posterSrc;
  bool _isLoading = kIsWeb;
  String? _modelObjectUrl;
  String? _posterObjectUrl;
  String? _idleAnimationName;
  String? _thinkingAnimationName;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _prepareWebAssets();
    } else {
      _modelSrc = AppAssets.aiAvatar;
      _posterSrc = AppAssets.aiAvatarPoster;
      _isLoading = false;
      _resetAnimationCache();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAnimationState());
  }

  @override
  void didUpdateWidget(covariant _BackgroundAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isThinking != oldWidget.isThinking) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncAnimationState());
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      _disposeObjectUrls();
    }
    super.dispose();
  }

  Future<void> _prepareWebAssets() async {
    try {
      final modelData = await rootBundle.load(AppAssets.aiAvatar);
      final modelBytes = modelData.buffer.asUint8List();
      var modelUri = await createObjectUrlFromBytes(
        modelBytes,
        mimeType: 'model/gltf-binary',
      );
      modelUri ??=
          'data:model/gltf-binary;base64,${base64Encode(modelBytes)}';

      String? posterUri;
      try {
        final posterData = await rootBundle.load(AppAssets.aiAvatarPoster);
        final posterBytes = posterData.buffer.asUint8List();
        const mimeType = 'image/jpeg';
        posterUri = await createObjectUrlFromBytes(
          posterBytes,
          mimeType: mimeType,
        );
        posterUri ??=
            'data:$mimeType;base64,${base64Encode(posterBytes)}';
      } catch (_) {
        posterUri = AppAssets.aiAvatarPoster;
      }

      if (!mounted) {
        return;
      }

      _disposeObjectUrls();
      setState(() {
        _modelSrc = modelUri;
        _posterSrc = posterUri;
        _isLoading = false;
        _modelObjectUrl = _isObjectUrl(modelUri) ? modelUri : null;
        _posterObjectUrl = _isObjectUrl(posterUri) ? posterUri : null;
        _resetAnimationCache();
      });
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _syncAnimationState());
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _modelSrc = AppAssets.aiAvatar;
        _posterSrc = AppAssets.aiAvatarPoster;
        _resetAnimationCache();
      });
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _syncAnimationState());
    }
  }

  @override
  Widget build(BuildContext context) {
    final modelSrc = _modelSrc;
    final posterSrc = _posterSrc;

    if (modelSrc == null) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: _isLoading
            ? const CircularProgressIndicator()
            : const SizedBox.shrink(),
      );
    }

    return SizedBox(
      width: 380,
      height: 580,
      child: ModelViewer(
        key: ValueKey('${modelSrc}_${widget.isThinking}'),
        src: modelSrc,
        alt: 'AI Avatar',
        autoPlay: false,
        autoRotate: false,
        animationName: _idleAnimationName,
        cameraControls: false,
        disablePan: true,
        disableTap: true,
        disableZoom: true,
        ar: false,
        loading: Loading.eager,
        reveal: Reveal.auto,
        environmentImage: 'neutral',
        exposure: 1.1,
        shadowIntensity: 0.6,
        shadowSoftness: 0.8,
        cameraOrbit: '0deg 65deg 4.4m',
        cameraTarget: '0m 1.2m 0m',
        fieldOfView: '52deg',
        backgroundColor: Colors.transparent,
        poster: posterSrc,
        id: _viewerElementId,
      ),
    );
  }

  void _syncAnimationState() {
    if (!kIsWeb) {
      return;
    }
    if (_modelSrc == null) {
      return;
    }
    void attempt(int retries) {
      if (!mounted) {
        return;
      }
      final animations = getAvatarAnimationNames(_viewerElementId);
      if (animations == null || animations.isEmpty) {
        if (retries > 0) {
          Future<void>.delayed(
            _animationRetryDelay,
            () => attempt(retries - 1),
          );
        }
        return;
      }

      _ensureAnimationPreferences(animations);

      final selectedAnimation = widget.isThinking
          ? (_thinkingAnimationName ?? _idleAnimationName)
          : _idleAnimationName;
      if (selectedAnimation == null) {
        if (retries > 0) {
          Future<void>.delayed(
            _animationRetryDelay,
            () => attempt(retries - 1),
          );
        }
        return;
      }

      final success = widget.isThinking
          ? playAvatarAnimation(
              _viewerElementId,
              animationName: selectedAnimation,
            )
          : pauseAvatarAnimation(
              _viewerElementId,
              animationName: selectedAnimation,
              currentTime: 0,
            );
      if (!success && retries > 0) {
        Future<void>.delayed(
          _animationRetryDelay,
          () => attempt(retries - 1),
        );
      }
    }

    attempt(_maxAnimationRetries);
  }

  void _ensureAnimationPreferences(List<String> animations) {
    _idleAnimationName ??=
        _pickAnimation(animations, const ['idle', 'breath', 'stand', 'pose']);
    _thinkingAnimationName ??=
        _pickAnimation(animations, const ['talk', 'speak', 'chat', 'gesture']);

    if (_idleAnimationName == null && animations.isNotEmpty) {
      _idleAnimationName = animations.firstWhere(
        (name) {
          final lower = name.toLowerCase();
          return !lower.contains('walk') &&
              !lower.contains('run') &&
              !lower.contains('dance');
        },
        orElse: () => animations.first,
      );
    }
    if (_thinkingAnimationName == null) {
      final movement = animations.firstWhere(
        (name) {
          final lower = name.toLowerCase();
          return lower.contains('talk') ||
              lower.contains('speak') ||
              lower.contains('gesture') ||
              lower.contains('wave');
        },
        orElse: () => '',
      );
      if (movement.isNotEmpty) {
        _thinkingAnimationName = movement;
      } else {
        final walkAlternative = animations.firstWhere(
          (name) => name.toLowerCase().contains('walk'),
          orElse: () => '',
        );
        if (walkAlternative.isNotEmpty && walkAlternative != _idleAnimationName) {
          _thinkingAnimationName = walkAlternative;
        } else {
          _thinkingAnimationName = _idleAnimationName;
        }
      }
    }
  }

  String? _pickAnimation(List<String> animations, List<String> keywords) {
    for (final keyword in keywords) {
      final match = animations.firstWhere(
        (name) => name.toLowerCase().contains(keyword),
        orElse: () => '',
      );
      if (match.isNotEmpty) {
        return match;
      }
    }
    return null;
  }

  void _resetAnimationCache() {
    _idleAnimationName = null;
    _thinkingAnimationName = null;
  }

  void _disposeObjectUrls() {
    if (_modelObjectUrl != null) {
      revokeObjectUrl(_modelObjectUrl!);
      _modelObjectUrl = null;
    }
    if (_posterObjectUrl != null) {
      revokeObjectUrl(_posterObjectUrl!);
      _posterObjectUrl = null;
    }
  }

  bool _isObjectUrl(String? url) => url != null && url.startsWith('blob:');
}

class _AiTypingBubble extends StatelessWidget {
  const _AiTypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: _TypingIndicator(),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F27),
        borderRadius: BorderRadius.circular(18),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final phase = _controller.value;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              final opacity = _dotOpacity(phase, index);
              return Padding(
                padding: EdgeInsets.only(right: index == 2 ? 0 : 6),
                child: Opacity(
                  opacity: opacity,
                  child: const CircleAvatar(
                    radius: 5,
                    backgroundColor: Colors.white,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  double _dotOpacity(double phase, int index) {
    final step = 1 / 3;
    final start = index * step;
    final end = start + step;
    if (phase >= start && phase < end) {
      return 1;
    }
    return 0.3;
  }
}
