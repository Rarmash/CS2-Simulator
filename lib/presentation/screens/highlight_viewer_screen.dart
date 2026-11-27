import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../data/models/charm_dto.dart';

class HighlightViewerScreen extends StatefulWidget {
  const HighlightViewerScreen({
    super.key,
    required this.charm,
    required this.videoUri,
  });
  final CharmDto charm;
  final Uri videoUri;

  @override
  State<HighlightViewerScreen> createState() => _HighlightViewerScreenState();
}

class _HighlightViewerScreenState extends State<HighlightViewerScreen> {
  VideoPlayerController? controller;
  bool failed = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux)) {
      failed = true;
      return;
    }
    final player = VideoPlayerController.networkUrl(widget.videoUri);
    controller = player;
    player.addListener(_onPlayerChanged);
    player
        .initialize()
        .then((_) {
          if (mounted) setState(() {});
        })
        .catchError((Object error) {
          if (mounted) setState(() => failed = true);
        });
  }

  void _onPlayerChanged() {
    if (mounted && controller!.value.hasError && !failed) {
      setState(() => failed = true);
    }
  }

  @override
  void dispose() {
    controller?.removeListener(_onPlayerChanged);
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = controller;
    return Scaffold(
      appBar: AppBar(title: const Text('Highlight')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.charm.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (!failed && player != null && player.value.isInitialized) ...[
            AspectRatio(
              aspectRatio: player.value.aspectRatio,
              child: VideoPlayer(player),
            ),
            VideoProgressIndicator(player, allowScrubbing: true),
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: player,
              builder: (context, value, _) => IconButton(
                onPressed: () async {
                  try {
                    if (value.isPlaying) {
                      await player.pause();
                    } else {
                      await player.play();
                    }
                  } catch (_) {
                    if (mounted) setState(() => failed = true);
                  }
                },
                icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
              ),
            ),
          ] else if (!failed)
            const Center(child: CircularProgressIndicator())
          else
            const Text(
              'Embedded playback is unavailable. Open the highlight in your browser.',
            ),
          if (widget.charm.description != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(widget.charm.description!),
            ),
          if (widget.charm.map != null ||
              widget.charm.stage != null ||
              widget.charm.player != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                [
                  widget.charm.map,
                  widget.charm.stage,
                  widget.charm.player,
                ].whereType<String>().where((s) => s.isNotEmpty).join(' • '),
              ),
            ),
          TextButton.icon(
            onPressed: () async {
              var success = false;
              try {
                success = await launchUrl(
                  widget.videoUri,
                  mode: LaunchMode.externalApplication,
                );
              } catch (_) {
                success = false;
              }
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open the browser.')),
                );
              }
            },
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Open in browser'),
          ),
        ],
      ),
    );
  }
}
