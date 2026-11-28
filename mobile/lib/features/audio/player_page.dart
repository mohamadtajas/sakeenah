import 'package:material_ui/material_ui.dart';

import '../../data/app_services.dart';
import '../../data/audio/audio_durations.dart';
import '../../data/audio/playback_controller.dart';
import '../../data/models/audio.dart';
import '../../data/models/quran.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/sakeenah_theme.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key, required this.playback});

  final PlaybackController playback;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  /// While the user drags the slider we show the thumb immediately and only
  /// seek once, on release, to avoid repeated HTTP range requests.
  double? _dragSeconds;
  AudioDurationIndex? _durations;
  Ayah? _ayahText;
  String? _ayahKey;

  PlaybackController get _playback => widget.playback;

  @override
  void initState() {
    super.initState();
    _playback.addListener(_onPlayback);
    _onPlayback();
    AudioDurationIndex.load().then((index) {
      if (mounted) setState(() => _durations = index);
    });
  }

  @override
  void dispose() {
    _playback.removeListener(_onPlayback);
    super.dispose();
  }

  void _onPlayback() {
    final track = _playback.current;
    if (track == null || track.surah <= 0) {
      if (_ayahKey != null) {
        setState(() {
          _ayahKey = null;
          _ayahText = null;
        });
      }
      return;
    }
    final key = '${track.surah}:${track.ayah}';
    if (key == _ayahKey) return;
    _ayahKey = key;
    _ayahText = null;
    AppServices.current.quran.ayah(track.surah, track.ayah).then((ayah) {
      if (mounted && _ayahKey == key) setState(() => _ayahText = ayah);
    });
  }

  String _time(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.audioNowPlaying)),
      body: ListenableBuilder(
        listenable: _playback,
        builder: (context, _) {
          final track = _playback.current;
          if (track == null) {
            return Center(child: Text(l10n.audioQueueEmpty));
          }
          final queue = _playback.queue;
          final index = _playback.index.clamp(0, queue.length - 1);
          final live = track.reciterId == 'radio';
          final surahQueue =
              queue.length > 1 &&
              track.surah > 0 &&
              queue.every(
                (item) =>
                    item.surah == track.surah &&
                    item.reciterId == track.reciterId,
              );
          final durationIndex = _durations;
          List<int>? durations;
          int? totalMs;
          int? beforeMs;
          if (surahQueue && durationIndex != null) {
            final all = <int>[];
            var complete = true;
            for (final item in queue) {
              final ms = durationIndex.durationFor(
                item.reciterId,
                item.surah,
                item.ayah,
              );
              if (ms == null || ms <= 0) {
                complete = false;
                break;
              }
              all.add(ms);
            }
            if (complete) {
              durations = all;
              totalMs = all.fold<int>(0, (sum, value) => sum + value);
              beforeMs = all
                  .take(index)
                  .fold<int>(0, (sum, value) => sum + value);
            }
          }

          final duration = _playback.duration;
          final hasAyahDuration = duration > Duration.zero;
          final aggregate = totalMs != null;
          final total = aggregate ? Duration(milliseconds: totalMs) : duration;
          final position = aggregate
              ? Duration(
                  milliseconds:
                      (beforeMs ?? 0) + _playback.position.inMilliseconds,
                )
              : _playback.position;
          final maxSeconds = total > Duration.zero
              ? total.inMilliseconds / 1000.0
              : 1.0;
          final seconds = (position.inMilliseconds / 1000.0).clamp(
            0.0,
            maxSeconds,
          );
          final sliderValue = (_dragSeconds ?? seconds).clamp(0.0, maxSeconds);
          final shownPosition = _dragSeconds == null
              ? position
              : Duration(milliseconds: (_dragSeconds! * 1000).round());
          final seekable = aggregate ? totalMs > 0 : hasAyahDuration;

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            children: [
              Center(
                child: Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withValues(alpha: 0.12),
                    border: Border.all(color: scheme.outline),
                  ),
                  child: Icon(
                    live ? Icons.radio_rounded : Icons.menu_book_rounded,
                    size: 52,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                track.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${track.subtitle} · ${track.reciterName}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              if (live)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: SakeenahColors.gold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: SakeenahColors.gold,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.audioLiveBadge,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: SakeenahColors.goldInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (surahQueue)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: SakeenahColors.gold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l10n.audioAyahOf(index + 1, queue.length),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: SakeenahColors.goldInk,
                      ),
                    ),
                  ),
                ),
              if (surahQueue && _ayahText != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: scheme.outline),
                  ),
                  child: Text(
                    _ayahText!.text,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: SakeenahTheme.quran(
                      Theme.of(context).textTheme.bodyLarge!,
                      size: 22,
                    ).copyWith(color: scheme.onSurface),
                  ),
                ),
              ],
              if (_playback.error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 18,
                            color: scheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.audioPlaybackError,
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.5,
                                color: scheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          key: const ValueKey('audio-retry'),
                          onPressed: _playback.retry,
                          child: Text(l10n.retry),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (!live) ...[
                if (aggregate && durations != null)
                  _SurahTicks(
                    durations: durations,
                    currentIndex: index,
                    color: scheme.outline,
                    activeColor: SakeenahColors.gold,
                  ),
                Slider(
                  key: const ValueKey('audio-seek'),
                  value: sliderValue,
                  max: maxSeconds,
                  onChanged: seekable
                      ? (value) => setState(() => _dragSeconds = value)
                      : null,
                  onChangeEnd: seekable
                      ? (value) {
                          setState(() => _dragSeconds = null);
                          if (aggregate && durations != null) {
                            final target = _locate(durations, value);
                            if (target != null) {
                              _playback.playAt(
                                target.index,
                                position: target.offset,
                              );
                              return;
                            }
                          }
                          _playback.seek(
                            Duration(milliseconds: (value * 1000).round()),
                          );
                        }
                      : null,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _time(shownPosition),
                      style: TextStyle(
                        fontSize: 10,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      total > Duration.zero ? _time(total) : '--:--',
                      style: TextStyle(
                        fontSize: 10,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ] else
                Text(
                  l10n.audioLiveHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.6,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!live) ...[
                    IconButton(
                      tooltip: l10n.audioPrevious,
                      onPressed: index > 0 ? _playback.previous : null,
                      icon: const Icon(Icons.skip_previous_rounded, size: 34),
                    ),
                    const SizedBox(width: 14),
                  ],
                  IconButton.filled(
                    key: const ValueKey('audio-toggle'),
                    tooltip: _playback.playing
                        ? l10n.audioPause
                        : l10n.audioPlay,
                    onPressed: _playback.toggle,
                    style: IconButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      minimumSize: const Size(64, 64),
                    ),
                    iconSize: 36,
                    icon: Icon(
                      _playback.playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                  ),
                  if (!live) ...[
                    const SizedBox(width: 14),
                    IconButton(
                      tooltip: l10n.audioNext,
                      onPressed: index + 1 < queue.length
                          ? _playback.next
                          : null,
                      icon: const Icon(Icons.skip_next_rounded, size: 34),
                    ),
                  ],
                ],
              ),
              if (!live) ...[
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      key: const ValueKey('audio-speed'),
                      avatar: const Icon(Icons.speed_rounded, size: 16),
                      label: Text('${_playback.speed}x'),
                      onPressed: _playback.cycleSpeed,
                    ),
                    ActionChip(
                      key: const ValueKey('audio-repeat'),
                      avatar: Icon(switch (_playback.repeat) {
                        AudioRepeatMode.one => Icons.repeat_one_rounded,
                        _ => Icons.repeat_rounded,
                      }, size: 16),
                      label: Text(switch (_playback.repeat) {
                        AudioRepeatMode.off => l10n.audioRepeatOff,
                        AudioRepeatMode.one => l10n.audioRepeatOne,
                        AudioRepeatMode.all => l10n.audioRepeatAll,
                      }),
                      onPressed: _playback.cycleRepeat,
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  ({int index, Duration offset})? _locate(List<int> durations, double second) {
    var remaining = (second * 1000).round();
    for (var i = 0; i < durations.length; i++) {
      final duration = durations[i];
      if (duration <= 0) return null;
      if (remaining < duration) {
        return (index: i, offset: Duration(milliseconds: remaining));
      }
      remaining -= duration;
    }
    return null;
  }
}

class _SurahTicks extends StatelessWidget {
  const _SurahTicks({
    required this.durations,
    required this.currentIndex,
    required this.color,
    required this.activeColor,
  });

  final List<int> durations;
  final int currentIndex;
  final Color color;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        height: 7,
        width: double.infinity,
        child: CustomPaint(
          painter: _TicksPainter(
            durations: durations,
            currentIndex: currentIndex,
            color: color,
            activeColor: activeColor,
          ),
        ),
      ),
    );
  }
}

class _TicksPainter extends CustomPainter {
  _TicksPainter({
    required this.durations,
    required this.currentIndex,
    required this.color,
    required this.activeColor,
  });

  final List<int> durations;
  final int currentIndex;
  final Color color;
  final Color activeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final total = durations.fold<int>(0, (sum, value) => sum + value);
    if (total <= 0) return;
    var cumulative = 0;
    final paint = Paint()..strokeWidth = 1.2;
    for (var i = 0; i < durations.length - 1; i++) {
      cumulative += durations[i];
      final x = size.width * (cumulative / total);
      paint.color = i <= currentIndex ? activeColor : color;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_TicksPainter oldDelegate) =>
      oldDelegate.currentIndex != currentIndex ||
      oldDelegate.durations != durations;
}
