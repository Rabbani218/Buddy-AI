import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:healthbuddy_ai/l10n/app_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_assets.dart';
import '../models/chat_message.dart';
import '../providers/app_providers.dart';

class ChatMessageBubble extends ConsumerWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
  });

  final ChatMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUser = message.isFromUser;
    final l10n = AppLocalizations.of(context)!;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final baseColor = isUser
        ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB))
        : (isDark ? Colors.white : Colors.black87);
    final bubbleColor = isUser
        ? baseColor.withOpacity(isDark ? 0.35 : 0.25)
        : baseColor.withOpacity(isDark ? 0.16 : 0.08);
    final borderColor = isUser
        ? (isDark
            ? Colors.white.withOpacity(0.45)
            : baseColor.withOpacity(0.35))
        : (isDark ? Colors.white24 : Colors.black26);
    final textColor =
        isUser ? Colors.white : (isDark ? Colors.white : Colors.black87);

    final markdownStyle = _buildMarkdownStyle(context, textColor, isDark);

    final messageBody = MarkdownBody(
      data: message.text,
      styleSheet: markdownStyle,
      selectable: true,
    );

    final actionRow = (!isUser && message.text.trim().isNotEmpty)
        ? _ActionRow(
            message: message,
            textColor: textColor,
            tooltipCopy: l10n.copyLabel,
            tooltipShare: l10n.shareLabel,
            tooltipReplay: l10n.replayLabel,
            copyConfirmation: l10n.copyConfirmation,
            ttsFailedMessage: l10n.ttsFailed,
          )
        : null;

    final contentWidgets = <Widget>[messageBody];
    if (actionRow != null) {
      contentWidgets
        ..add(const SizedBox(height: 12))
        ..add(actionRow);
    }

    final bubbleChild = Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: contentWidgets,
    );

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1.1),
                ),
                child: bubbleChild,
              ),
            ),
          ),
        ),
      ),
    );
  }

  MarkdownStyleSheet _buildMarkdownStyle(
    BuildContext context,
    Color textColor,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final codeBackground = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.08);
    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: theme.textTheme.bodyMedium?.copyWith(
        color: textColor,
        height: 1.5,
      ),
      code: TextStyle(
        color: textColor.withOpacity(0.95),
        fontFamily: 'FiraCode',
        fontSize: 13,
      ),
      codeblockDecoration: BoxDecoration(
        color: codeBackground,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: codeBackground.withOpacity(isDark ? 0.6 : 0.4)),
      ),
      blockquoteDecoration: BoxDecoration(
        color: codeBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border(
            left: BorderSide(color: textColor.withOpacity(0.3), width: 4)),
      ),
      listBullet: TextStyle(color: textColor, fontSize: 16),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: textColor.withOpacity(0.2))),
      ),
    );
  }
}

class _ActionRow extends ConsumerWidget {
  const _ActionRow({
    required this.message,
    required this.textColor,
    required this.tooltipCopy,
    required this.tooltipShare,
    required this.tooltipReplay,
    required this.copyConfirmation,
    required this.ttsFailedMessage,
  });

  final ChatMessage message;
  final Color textColor;
  final String tooltipCopy;
  final String tooltipShare;
  final String tooltipReplay;
  final String copyConfirmation;
  final String ttsFailedMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disabled = message.text.trim().isEmpty;
    final iconOpacity = disabled ? 0.3 : 0.85;
    final iconColor = textColor.withOpacity(iconOpacity);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          iconSize: 18,
          tooltip: tooltipCopy,
          onPressed: disabled
              ? null
              : () {
                  Clipboard.setData(ClipboardData(text: message.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(copyConfirmation)),
                  );
                },
          icon: SvgPicture.asset(
            AppAssets.iconCopy,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          iconSize: 18,
          tooltip: tooltipReplay,
          onPressed: disabled
              ? null
              : () async {
                  try {
                    await ref.read(ttsServiceProvider).speak(message.text);
                  } catch (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ttsFailedMessage)),
                    );
                  }
                },
          icon: SvgPicture.asset(
            AppAssets.iconReplay,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          iconSize: 18,
          tooltip: tooltipShare,
          onPressed: disabled
              ? null
              : () {
                  Share.share(message.text);
                },
          icon: SvgPicture.asset(
            AppAssets.iconShare,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
        ),
      ],
    );
  }
}
