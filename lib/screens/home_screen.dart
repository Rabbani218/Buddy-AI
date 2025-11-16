import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:isar/isar.dart';
import 'package:healthbuddy_ai/l10n/app_localizations.dart';

import '../core/app_assets.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
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
  Id? _lastHandledSessionId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSessionReady(ChatSession session) {
    if (_lastHandledSessionId == session.id) {
      return;
    }
    _lastHandledSessionId = session.id;
    Future.microtask(() async {
      await _loadHistory(session.id);
      await _ensureGreeting(session);
    });
  }

  Future<void> _loadHistory(Id sessionId) async {
    final repository = ref.read(chatRepositoryProvider);
    final history = await repository.getAll(sessionId: sessionId);
    ref.read(chatListProvider.notifier).state = history;
  }

  Future<void> _ensureGreeting(ChatSession session) async {
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
                sessionId: session.id,
                repository: repository,
              );

      final greetingMessage = ChatMessage(
        text: greetingText,
        isFromUser: false,
      );

      chatNotifier.state = [...chatNotifier.state, greetingMessage];
      await repository.save(greetingMessage, sessionId: session.id);
      chatNotifier.state = [...chatNotifier.state];
    } catch (_) {
      final fallback = ChatMessage(
        text: l10n.greetingFallback,
        isFromUser: false,
      );
      chatNotifier.state = [...chatNotifier.state, fallback];
      await repository.save(fallback, sessionId: session.id);
      chatNotifier.state = [...chatNotifier.state];
    } finally {
      ref.read(isAiThinkingProvider.notifier).state = false;
      ref.read(animationProvider.notifier).state = 'Idle';
    }
  }

  Future<void> _startNewSession() async {
    await ref.read(ttsServiceProvider).stop();
    ref.read(chatListProvider.notifier).state = <ChatMessage>[];
    ref.read(isAiThinkingProvider.notifier).state = false;
    ref.read(animationProvider.notifier).state = 'Idle';
    final notifier = ref.read(activeSessionProvider.notifier);
    await notifier.startNewSession();
    ref.read(chatListProvider.notifier).state = <ChatMessage>[];
  }

  Future<void> _selectSession(ChatSession session) async {
    ref.read(chatListProvider.notifier).state = <ChatMessage>[];
    await ref.read(activeSessionProvider.notifier).selectSession(session.id);
  }

  Future<void> _showSessionHistory() async {
    if (!mounted) {
      return;
    }
    ref.invalidate(sessionListProvider);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return _SessionHistorySheet(
          onSelectSession: (session) async {
            Navigator.of(modalContext).pop();
            await _selectSession(session);
          },
          onCreateSession: () async {
            Navigator.of(modalContext).pop();
            await _startNewSession();
          },
        );
      },
    );
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
    ref.listen<AsyncValue<ChatSession>>(
      activeSessionProvider,
      (previous, next) {
        next.whenData(_handleSessionReady);
      },
    );
    final messages = ref.watch(chatListProvider);
    final isThinking = ref.watch(isAiThinkingProvider);
    final sessionState = ref.watch(activeSessionProvider);
    final activeSession = sessionState.maybeWhen(
      data: (session) => session,
      orElse: () => null,
    );
    final sessionError = sessionState.maybeWhen<Object?>(
      error: (error, _) => error,
      orElse: () => null,
    );
    final isSessionLoading = sessionState.isLoading;
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.appTitle),
            Text(
              'あなたの健康仲間',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: iconColor.withOpacity(0.8),
                  ),
            ),
            if (activeSession != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  activeSession.title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: iconColor.withOpacity(0.75),
                        overflow: TextOverflow.ellipsis,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.chatHistoryTooltip,
            onPressed: _showSessionHistory,
            icon: Icon(Icons.history, color: iconColor.withOpacity(0.9)),
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
          const SizedBox(width: 4),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.favorite, color: Colors.pinkAccent),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final backgroundLayers = <Widget>[
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
          ];

          if (constraints.maxWidth < 600) {
            return Stack(
              children: [
                ...backgroundLayers,
                SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 550),
                              curve: Curves.easeOutCubic,
                              width: math.min(constraints.maxWidth * 0.98, 520.0),
                              height: math.min(
                                constraints.maxHeight * 0.58,
                                520.0,
                              ),
                              child: _BackgroundAvatar(isThinking: isThinking),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _buildChatInterface(
                            isThinking: isThinking,
                            isSessionLoading: isSessionLoading,
                            sessionError: sessionError,
                            onRetrySession: () =>
                              ref.read(activeSessionProvider.notifier).initialize(),
                            l10n: l10n,
                            messages: messages,
                            chatPanelColor: chatPanelColor,
                            chatBorderColor: chatBorderColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return Stack(
            children: [
              ...backgroundLayers,
              Align(
                alignment: Alignment.center,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 550),
                  curve: Curves.easeOutCubic,
                  width: math.min(constraints.maxWidth * 0.55, 680.0),
                  height: math.min(constraints.maxHeight * 0.85, 720.0),
                  child: _BackgroundAvatar(isThinking: isThinking),
                ),
              ),
              Positioned.fill(
                child: SafeArea(
                  child: _buildChatInterface(
                    isThinking: isThinking,
                    isSessionLoading: isSessionLoading,
                    sessionError: sessionError,
                    onRetrySession: () =>
                      ref.read(activeSessionProvider.notifier).initialize(),
                    l10n: l10n,
                    messages: messages,
                    chatPanelColor: chatPanelColor,
                    chatBorderColor: chatBorderColor,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChatInterface({
    required bool isThinking,
    required bool isSessionLoading,
    required Object? sessionError,
    required VoidCallback onRetrySession,
    required AppLocalizations l10n,
    required List<ChatMessage> messages,
    required Color chatPanelColor,
    required Color chatBorderColor,
  }) {
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: chatPanelColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: chatBorderColor, width: 1),
            ),
            child: sessionError != null
              ? _SessionErrorView(
                error: sessionError,
                l10n: l10n,
                onRetry: onRetrySession,
                )
                : isSessionLoading
                    ? const _SessionLoadingView()
                    : messages.isEmpty
                        ? const _EmptyChatView()
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
                              final effectiveIndex = isThinking ? index - 1 : index;
                              final message =
                                  messages[messages.length - 1 - effectiveIndex];
                              return ChatMessageBubble(message: message);
                            },
                          ),
          ),
        ),
        const SizedBox(height: 12),
        const ChatInputWidget(),
      ],
    );
  }
}

class _SessionLoadingView extends StatelessWidget {
  const _SessionLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        height: 48,
        width: 48,
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _EmptyChatView extends StatelessWidget {
  const _EmptyChatView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
    );
  }
}

class _SessionErrorView extends StatelessWidget {
  const _SessionErrorView({
    required this.error,
    required this.l10n,
    required this.onRetry,
  });

  final Object? error;
  final AppLocalizations l10n;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorDescription = error?.toString() ?? '';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.sessionLoadError,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (errorDescription.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                errorDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionHistorySheet extends ConsumerWidget {
  const _SessionHistorySheet({
    required this.onSelectSession,
    required this.onCreateSession,
  });

  final ValueChanged<ChatSession> onSelectSession;
  final Future<void> Function() onCreateSession;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final sessionsAsync = ref.watch(sessionListProvider);
    final activeSession = ref.watch(activeSessionProvider).maybeWhen(
          data: (session) => session,
          orElse: () => null,
        );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 16,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: sessionsAsync.when(
              data: (sessions) {
                final sortedSessions = List<ChatSession>.from(sessions)
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.chatHistoryTooltip,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (sortedSessions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Text(
                          l10n.chatHistoryEmpty,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 360),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: sortedSessions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final session = sortedSessions[index];
                            final isActive = activeSession?.id == session.id;
                            final subtitle = _formatTimestamp(session.createdAt, locale);
                            return ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              leading: Icon(
                                isActive ? Icons.chat_bubble : Icons.chat_bubble_outline,
                                color: isActive
                                    ? theme.colorScheme.primary
                                    : theme.iconTheme.color?.withOpacity(0.8),
                              ),
                              title: Text(
                                session.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(subtitle),
                              trailing: isActive
                                  ? Icon(Icons.check_circle,
                                      color: theme.colorScheme.primary)
                                  : null,
                              selected: isActive,
                              selectedTileColor:
                                  theme.colorScheme.primary.withOpacity(0.12),
                              onTap: () => onSelectSession(session),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: onCreateSession,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.newSessionTooltip),
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 42,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.sessionLoadError,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      error.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => ref
                          .read(activeSessionProvider.notifier)
                          .refreshSessions(),
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.retryLabel),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp, Locale locale) {
    final localeTag = _localeTag(locale);
    final formatter = DateFormat.yMMMd(localeTag).add_Hm();
    return formatter.format(timestamp);
  }

  String _localeTag(Locale locale) {
    final country = locale.countryCode;
    if (country == null || country.isEmpty) {
      return locale.languageCode;
    }
    return '${locale.languageCode}_$country';
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
  String? _modelSrc;
  String? _posterSrc;
  bool _isLoading = kIsWeb;
  String? _modelObjectUrl;
  String? _posterObjectUrl;
  List<String> _availableAnimations = const [];
  String? _idleAnimationName;
  String? _thinkingAnimationName;
  String? _currentAnimationName;
  bool _isAnimationInitialized = false;
  bool _isSyncScheduled = false;

  @override
  void initState() {
    super.initState();
    _resetAnimationCache();
    if (kIsWeb) {
      _prepareWebAssets();
    } else {
      _modelSrc = AppAssets.aiAvatar;
      _posterSrc = AppAssets.aiAvatarPoster;
      _isLoading = false;
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
        _resetAnimationCache();
        _modelSrc = modelUri;
        _posterSrc = posterUri;
        _isLoading = false;
        _modelObjectUrl = _isObjectUrl(modelUri) ? modelUri : null;
        _posterObjectUrl = _isObjectUrl(posterUri) ? posterUri : null;
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

    if (kIsWeb) {
      _scheduleAnimationSync();
    }

    return ModelViewer(
      key: ValueKey(modelSrc),
      src: modelSrc,
      alt: 'AI Avatar',
      autoPlay: true,
      animationName:
          _currentAnimationName ?? _idleAnimationName ?? 'BreathingIdle',
      autoRotate: false,
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
      interactionPrompt: InteractionPrompt.none,
      cameraOrbit: '5deg 63deg 1.05m',
      fieldOfView: '28deg',
      cameraTarget: '0m 1.32m 0m',
      backgroundColor: Colors.transparent,
      poster: posterSrc,
      id: _viewerElementId,
    );
  }

  void _syncAnimationState() {
    _isSyncScheduled = false;
    if (!mounted || !kIsWeb) {
      return;
    }

    if (_modelSrc == null) {
      _scheduleAnimationSync();
      return;
    }

    final animations = getAvatarAnimationNames(_viewerElementId);

    if (animations == null) {
      _scheduleAnimationSync();
      return;
    }

    if (!listEquals(_availableAnimations, animations)) {
      _availableAnimations = List<String>.from(animations);
      _ensureAnimationPreferences(_availableAnimations);
      _isAnimationInitialized = false;
      _currentAnimationName = null;
      debugPrint('Avatar animations detected: ${_availableAnimations.join(', ')}');
    }

    final targetAnimation =
        widget.isThinking ? _thinkingAnimationName : _idleAnimationName;

    if (targetAnimation == null || targetAnimation.isEmpty) {
      _scheduleAnimationSync();
      return;
    }

    if (_isAnimationInitialized && _currentAnimationName == targetAnimation) {
      return;
    }

    final played =
        playAvatarAnimation(_viewerElementId, animationName: targetAnimation);

    if (!played) {
      _scheduleAnimationSync();
      return;
    }

    if (!mounted) {
      return;
    }

    if (_currentAnimationName != targetAnimation ||
        !_isAnimationInitialized) {
      setState(() {
        _currentAnimationName = targetAnimation;
        _isAnimationInitialized = true;
      });
    }
  }

  void _scheduleAnimationSync() {
    if (_isSyncScheduled || !mounted) {
      return;
    }
    _isSyncScheduled = true;
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) {
        return;
      }
      _isSyncScheduled = false;
      _syncAnimationState();
    });
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

  void _ensureAnimationPreferences(List<String> animations) {
    _idleAnimationName = _matchAnimation(animations, 'BreathingIdle');
    if (_idleAnimationName == null) {
      debugPrint("PERINGATAN: Animasi 'BreathingIdle' tidak ditemukan!");
      _idleAnimationName = animations.isNotEmpty ? animations.first : null;
    }

    _thinkingAnimationName = _matchAnimation(animations, 'Talking');
    if (_thinkingAnimationName == null) {
      debugPrint("PERINGATAN: Animasi 'Talking' tidak ditemukan!");
      _thinkingAnimationName = _idleAnimationName;
    }
    debugPrint(
      'Animation preferences -> idle: $_idleAnimationName, thinking: $_thinkingAnimationName',
    );
  }

  String? _matchAnimation(List<String> animations, String target) {
    if (animations.isEmpty) {
      return null;
    }
    for (final animation in animations) {
      if (animation == target) {
        return animation;
      }
    }
    final lowerTarget = target.toLowerCase();
    for (final animation in animations) {
      if (animation.toLowerCase() == lowerTarget) {
        return animation;
      }
    }
    for (final animation in animations) {
      if (animation.toLowerCase().startsWith(lowerTarget)) {
        return animation;
      }
    }
    for (final animation in animations) {
      if (animation.toLowerCase().contains(lowerTarget)) {
        return animation;
      }
    }
    return null;
  }

  void _resetAnimationCache() {
    _availableAnimations = const [];
    _idleAnimationName = null;
    _thinkingAnimationName = null;
    _currentAnimationName = null;
    _isAnimationInitialized = false;
    _isSyncScheduled = false;
  }
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
