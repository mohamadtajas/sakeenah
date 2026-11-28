import 'package:material_ui/material_ui.dart';

import '../../data/audio/playback_controller.dart';
import '../../l10n/app_localizations.dart';
import 'player_page.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key, required this.playback});

  final PlaybackController playback;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: playback,
      builder: (context, _) {
        final track = playback.current;
        if (track == null) return const SizedBox.shrink();
        final live = track.reciterId == 'radio';
        final l10n = AppLocalizations.of(context)!;
        final scheme = Theme.of(context).colorScheme;
        final duration = playback.duration;
        final progress = duration > Duration.zero
            ? (playback.position.inMilliseconds / duration.inMilliseconds)
                  .clamp(0.0, 1.0)
            : null;
        return Material(
          key: const ValueKey('mini-player-surface'),
          color: scheme.surface,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PlayerPage(playback: playback),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                  child: Row(
                    children: [
                      Icon(
                        playback.error != null
                            ? Icons.error_outline_rounded
                            : (live
                                  ? Icons.radio_rounded
                                  : Icons.graphic_eq_rounded),
                        color: playback.error != null
                            ? scheme.error
                            : scheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                            Text(
                              '${track.subtitle} · ${track.reciterName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('mini-toggle'),
                        tooltip: playback.playing
                            ? l10n.audioPause
                            : l10n.audioPlay,
                        onPressed: playback.toggle,
                        icon: Icon(
                          playback.playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                      ),
                      if (!live)
                        IconButton(
                          tooltip: l10n.audioNext,
                          onPressed: playback.next,
                          icon: const Icon(Icons.skip_next_rounded),
                        ),
                      IconButton(
                        tooltip: l10n.audioStopPlayback,
                        onPressed: playback.stopAndClear,
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
                if (progress != null)
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
