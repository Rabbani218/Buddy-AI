import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../core/app_assets.dart';
import '../providers/app_providers.dart';
import 'avatar_web_asset_loader_stub.dart'
  if (dart.library.html) 'avatar_web_asset_loader_web.dart';

class AvatarWidget extends ConsumerStatefulWidget {
  const AvatarWidget({super.key});

  @override
  ConsumerState<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends ConsumerState<AvatarWidget> {
  static const List<_PoseOption> _poseOptions = <_PoseOption>[
    _PoseOption(
      key: 'Idle',
      label: 'Pose Tenang',
      animationName: null,
      autoPlay: false,
      cameraOrbit: '0deg 72deg 3.2m',
      cameraTarget: '0m 1.35m 0m',
      fieldOfView: '33deg',
    ),
    _PoseOption(
      key: 'Talking',
      label: 'Pose Halo',
      animationName: 'Walk',
      autoPlay: true,
      cameraOrbit: '0deg 62deg 3.6m',
      cameraTarget: '0m 1.35m 0m',
      fieldOfView: '35deg',
    ),
    _PoseOption(
      key: 'Walk',
      label: 'Pose Dinamis',
      animationName: 'Walk',
      autoPlay: true,
      cameraOrbit: '15deg 60deg 3.8m',
      cameraTarget: '0m 1.35m 0m',
      fieldOfView: '36deg',
    ),
  ];
  String? _webModelSrc;
  String? _webPosterSrc;
  bool _isLoadingWebAssets = kIsWeb;
  String? _modelObjectUrl;
  String? _posterObjectUrl;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _prepareWebAssets();
    }
  }

  Future<void> _prepareWebAssets() async {
    try {
      final resolvedModelAssetUrl =
          Uri.base.resolve(AppAssets.aiAvatarModel).toString();
      final resolvedPosterAssetUrl =
          Uri.base.resolve(AppAssets.aiAvatarPoster).toString();
      String modelUri = resolvedModelAssetUrl;
      String? posterUri = resolvedPosterAssetUrl;
      final modelData = await rootBundle.load(AppAssets.aiAvatarModel);
      final modelBytes = modelData.buffer.asUint8List();
      final objectModelUri = await _createObjectUrl(
        modelBytes,
        mimeType: 'model/gltf-binary',
      );
      modelUri = objectModelUri ?? modelUri;

      try {
        final posterData = await rootBundle.load(AppAssets.aiAvatarPoster);
        final posterBytes = posterData.buffer.asUint8List();
        const posterMime = 'image/jpeg';
        final objectPosterUri = await _createObjectUrl(
          posterBytes,
          mimeType: posterMime,
        );
        posterUri = objectPosterUri ?? posterUri;
      } catch (_) {
        posterUri = resolvedPosterAssetUrl;
      }

      if (!mounted) {
        return;
      }

      _disposeObjectUrls();
      setState(() {
        _webModelSrc = modelUri;
        _webPosterSrc = posterUri;
        _isLoadingWebAssets = false;
        _modelObjectUrl = _isObjectUrl(modelUri) ? modelUri : null;
        _posterObjectUrl = _isObjectUrl(posterUri) ? posterUri : null;
      });
    } catch (error) {
      debugPrint('Failed to prepare web avatar assets: $error');
      if (!mounted) {
        return;
      }
      _disposeObjectUrls();
      setState(() {
        _isLoadingWebAssets = false;
        _webModelSrc = null;
        _webPosterSrc = null;
        _modelObjectUrl = null;
        _posterObjectUrl = null;
      });
    }
  }

  Future<String?> _createObjectUrl(
    Uint8List bytes, {
    required String mimeType,
  }) async {
    if (!kIsWeb) {
      return null;
    }
    return createObjectUrlFromBytes(bytes, mimeType: mimeType);
  }

  @override
  Widget build(BuildContext context) {
    final animationKey = ref.watch(animationProvider);
    final pose = _poseOptions.firstWhere(
      (option) => option.key == animationKey,
      orElse: () => _poseOptions.first,
    );
    final modelSrc = kIsWeb ? _webModelSrc : AppAssets.aiAvatarModel;
    final posterSrc = kIsWeb ? _webPosterSrc : AppAssets.aiAvatarPoster;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 24,
                offset: Offset(0, 12),
                spreadRadius: -8,
              ),
            ],
            border: Border.all(color: Colors.white24, width: 1.2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    AppAssets.bgMain,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.35),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  _buildModelViewer(pose, modelSrc, posterSrc),
                ],
              ),
            ),
          ),
        ),
        if (_poseOptions.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _poseOptions
                  .map(
                    (option) => ChoiceChip(
                      label: Text(option.label),
                      selected: option.key == pose.key,
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(animationProvider.notifier).state = option.key;
                        }
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    if (kIsWeb) {
      _disposeObjectUrls();
    }
    super.dispose();
  }

  void _disposeObjectUrls() {
    if (!kIsWeb) {
      return;
    }
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

  Widget _buildModelViewer(
      _PoseOption pose, String? modelSrc, String? posterSrc) {
    if (modelSrc == null) {
      return Center(
        child: _isLoadingWebAssets
            ? const CircularProgressIndicator()
            : const Icon(Icons.error_outline, color: Colors.redAccent),
      );
    }

    return ModelViewer(
      key: ValueKey('${modelSrc}_${pose.key}'),
      src: modelSrc,
      alt: 'AI Avatar',
      autoPlay: pose.autoPlay,
      autoRotate: false,
      animationName: pose.animationName,
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
      cameraOrbit: pose.cameraOrbit,
      cameraTarget: pose.cameraTarget,
      fieldOfView: pose.fieldOfView,
      backgroundColor: Colors.transparent,
      poster: posterSrc,
    );
  }
}

class _PoseOption {
  const _PoseOption({
    required this.key,
    required this.label,
    required this.cameraOrbit,
    required this.cameraTarget,
    required this.fieldOfView,
    this.animationName,
    this.autoPlay = false,
  });

  final String key;
  final String label;
  final String? animationName;
  final bool autoPlay;
  final String cameraOrbit;
  final String cameraTarget;
  final String fieldOfView;
}
