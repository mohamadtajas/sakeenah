import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../data/app_services.dart';
import '../../data/audio/anasheed_catalog.dart';
import '../../data/audio/audio_downloads.dart';
import '../../data/audio/islamic_radios.dart';
import '../../data/audio/playback_controller.dart';
import '../../data/audio/quran_audio_catalog.dart';
import '../../data/models/audio.dart';
import '../../data/models/quran.dart';
import '../../data/text.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/sakeenah_theme.dart';

enum _AudioMode { quran, anasheed, radio }

class AudioPage extends StatefulWidget {
  const AudioPage({super.key, this.playback, this.anasheed});

  final PlaybackController? playback;
  final AnasheedSource? anasheed;

  @override
  State<AudioPage> createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  late final AppServices _services = AppServices.current;
  late final PlaybackController _playback =
      widget.playback ?? _services.playback;
  late final AudioDownloadManager _downloads = _services.downloads;
  late final AnasheedSource _anasheed =
      widget.anasheed ?? const OpenverseAnasheedSource();
  final TextEditingController _search = TextEditingController();
  final TextEditingController _anasheedSearch = TextEditingController();
  List<Surah> _surahs = const [];
  late AudioReciter _reciter;
  _AudioMode _mode = _AudioMode.quran;
  List<AnasheedTrack> _anasheedResults = const [];
  bool _anasheedLoading = false;
  bool _anasheedFailed = false;
  int _anasheedToken = 0;
  Timer? _anasheedDebounce;
  bool _loading = true;
  bool _failed = false;
  bool _wasDownloading = false;

  @override
  void initState() {
    super.initState();
    _reciter =
        QuranAudioCatalog.reciter(_services.defaultReciterId ?? '') ??
        QuranAudioCatalog.reciters.first;
    _downloads.addListener(_onDownloads);
    _load();
  }

  @override
  void dispose() {
    _anasheedDebounce?.cancel();
    _downloads.removeListener(_onDownloads);
    _search.dispose();
    _anasheedSearch.dispose();
    super.dispose();
  }

  void _onDownloads() {
    if (!mounted) return;
    final was = _wasDownloading;
    _wasDownloading = _downloads.running;
    setState(() {});
    if (!was || _downloads.running) return;
    final l10n = AppLocalizations.of(context)!;
    final message = switch (_downloads.error) {
      'cancelled' => l10n.audioDownloadStopped,
      null => l10n.audioDownloadComplete,
      _ => l10n.audioDownloadFailed,
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _load() async {
    try {
      final surahs = await _services.quran.surahs();
      if (!mounted) return;
      setState(() {
        _surahs = surahs;
        _loading = false;
        _failed = false;
      });
      await _downloads.refresh(_reciter, surahs, replace: true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _play(Surah surah) async {
    final queue = [
      for (final track in QuranAudioCatalog.surahQueue(
        reciter: _reciter,
        surah: surah.number,
        surahName: surah.name,
        ayahCount: surah.ayahCount,
      ))
        _downloads.localTrack(track),
    ];
    try {
      await _playback.playQueue(queue);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.audioPlaybackError),
        ),
      );
    }
  }

  Future<void> _downloadSurah(Surah surah) async {
    await _downloads.downloadSurah(_reciter, surah);
  }

  void _deleteSurah(Surah surah) {
    _downloads.store.deleteSurah(_reciter.id, surah.number);
    _downloads.refresh(_reciter, _surahs, replace: true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.audioDeleted)),
    );
  }

  void _selectMode(_AudioMode mode) {
    setState(() => _mode = mode);
    if (mode == _AudioMode.anasheed &&
        _anasheedResults.isEmpty &&
        !_anasheedLoading) {
      _searchAnasheed(_anasheedSearch.text);
    }
  }

  void _onAnasheedQueryChanged(String value) {
    setState(() {});
    _anasheedDebounce?.cancel();
    _anasheedDebounce = Timer(
      const Duration(milliseconds: 450),
      () => _searchAnasheed(value),
    );
  }

  Future<void> _searchAnasheed(String query) async {
    final token = ++_anasheedToken;
    setState(() {
      _anasheedLoading = true;
      _anasheedFailed = false;
    });
    try {
      final results = await _anasheed.search(query);
      if (!mounted || token != _anasheedToken) return;
      setState(() {
        _anasheedResults = results;
        _anasheedLoading = false;
      });
    } catch (_) {
      if (!mounted || token != _anasheedToken) return;
      setState(() {
        _anasheedLoading = false;
        _anasheedFailed = true;
      });
    }
  }

  Future<void> _playAnasheed(int index) async {
    final tracks = [
      for (var i = 0; i < _anasheedResults.length; i++)
        _anasheedResults[i].toAudioTrack(i),
    ];
    try {
      await _playback.playQueue(tracks, initialIndex: index);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.audioPlaybackError),
        ),
      );
    }
  }

  String _size(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  Widget _downloadAction(
    Surah surah,
    AppLocalizations l10n,
    ColorScheme scheme,
  ) {
    final downloaded = _downloads.isDownloaded(surah.number);
    final working =
        _downloads.running && _downloads.currentSurah == '${surah.number}';
    if (working) {
      return const SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (downloaded) {
      return IconButton(
        key: ValueKey('audio-downloaded-${surah.number}'),
        tooltip: l10n.audioDeleteDownload,
        onPressed: _downloads.running ? null : () => _deleteSurah(surah),
        icon: Icon(Icons.download_done_rounded, color: scheme.primary),
      );
    }
    return IconButton(
      key: ValueKey('audio-download-${surah.number}'),
      tooltip: l10n.audioDownloadSurah,
      onPressed: _downloads.running ? null : () => _downloadSurah(surah),
      icon: const Icon(Icons.download_rounded),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    String labelFor(_AudioMode mode) => switch (mode) {
      _AudioMode.quran => l10n.audioModeQuran,
      _AudioMode.anasheed => l10n.audioModeAnasheed,
      _AudioMode.radio => l10n.audioModeRadio,
    };
    IconData iconFor(_AudioMode mode) => switch (mode) {
      _AudioMode.quran => Icons.menu_book_outlined,
      _AudioMode.anasheed => Icons.music_note_rounded,
      _AudioMode.radio => Icons.radio_rounded,
    };
    Widget modeChip(_AudioMode mode) {
      final selected = _mode == mode;
      return ChoiceChip(
        key: ValueKey('audio-mode-${mode.name}'),
        selected: selected,
        showCheckmark: false,
        selectedColor: scheme.primaryContainer,
        backgroundColor: scheme.surfaceContainerLow,
        side: BorderSide(color: scheme.outline),
        avatar: Icon(
          iconFor(mode),
          size: 17,
          color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        ),
        label: Text(
          labelFor(mode),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
          ),
        ),
        onSelected: (_) => _selectMode(mode),
      );
    }

    // At very large text, three chips wrap and squeeze the list. A single
    // dropdown keeps every mode reachable without hiding one off-screen.
    final largeText = MediaQuery.textScalerOf(context).scale(12) > 18;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
          child: largeText
              ? DropdownButtonFormField<_AudioMode>(
                  key: ValueKey('audio-mode-menu-${_mode.name}'),
                  initialValue: _mode,
                  isExpanded: true,
                  decoration: const InputDecoration(isDense: true),
                  items: [
                    for (final mode in _AudioMode.values)
                      DropdownMenuItem(
                        value: mode,
                        child: Row(
                          children: [
                            Icon(iconFor(mode), size: 18),
                            const SizedBox(width: 8),
                            Text(labelFor(mode)),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) _selectMode(value);
                  },
                )
              : Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final mode in _AudioMode.values) modeChip(mode),
                  ],
                ),
        ),
        Expanded(
          child: switch (_mode) {
            _AudioMode.quran => _buildQuran(l10n),
            _AudioMode.anasheed => _buildAnasheed(l10n),
            _AudioMode.radio => _buildRadio(l10n),
          },
        ),
      ],
    );
  }

  Widget _buildQuran(AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_failed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.audioLoadError),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                setState(() => _loading = true);
                _load();
              },
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    final query = normalizeArabic(_search.text);
    final filtered = query.isEmpty
        ? _surahs
        : _surahs
              .where(
                (surah) =>
                    normalizeArabic(surah.name).contains(query) ||
                    normalizeArabic(surah.englishName).contains(query),
              )
              .toList();
    final allDownloaded =
        _surahs.isNotEmpty &&
        _surahs.every((surah) => _downloads.isDownloaded(surah.number));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: DropdownButtonFormField<AudioReciter>(
            initialValue: _reciter,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.audioChooseReciter),
            items: [
              for (final reciter in QuranAudioCatalog.reciters)
                DropdownMenuItem(
                  value: reciter,
                  child: Text(
                    '${reciter.name} · ${reciter.style}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _reciter = value);
              _services.setDefaultReciter(value.id);
              _downloads.refresh(value, _surahs, replace: true);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 2,
                children: [
                  Text(
                    l10n.audioStorageUsed(_size(_downloads.bytes)),
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton.icon(
                    key: const ValueKey('audio-download-all'),
                    onPressed: _downloads.running
                        ? _downloads.cancel
                        : (allDownloaded
                              ? null
                              : () =>
                                    _downloads.downloadAll(_reciter, _surahs)),
                    icon: Icon(
                      _downloads.running
                          ? Icons.stop_rounded
                          : (allDownloaded
                                ? Icons.download_done_rounded
                                : Icons.download_rounded),
                      size: 18,
                    ),
                    label: Text(
                      _downloads.running
                          ? l10n.audioCancelDownloadShort
                          : (allDownloaded
                                ? l10n.audioAllDownloaded
                                : l10n.audioDownloadAll),
                    ),
                  ),
                ],
              ),
              if (_downloads.running) ...[
                LinearProgressIndicator(
                  value: _downloads.total == 0
                      ? null
                      : _downloads.done / _downloads.total,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.audioDownloadProgress(_downloads.done, _downloads.total),
                  style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            key: const ValueKey('audio-search'),
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l10n.audioSearchSurah,
              prefixIcon: const Icon(Icons.search_rounded, size: 19),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final surah = filtered[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 17,
                    backgroundColor: scheme.primary.withValues(alpha: 0.12),
                    child: Text(
                      '${surah.number}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    surah.name,
                    style: SakeenahTheme.quran(
                      Theme.of(context).textTheme.titleMedium!,
                      size: 18,
                    ).copyWith(color: scheme.onSurface),
                  ),
                  subtitle: Text(
                    '${surah.englishName} · ${l10n.quranAyahCount(surah.ayahCount)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _downloadAction(surah, l10n, scheme),
                      IconButton(
                        key: ValueKey('audio-play-${surah.number}'),
                        tooltip: l10n.audioPlaySurah,
                        onPressed: () => _play(surah),
                        icon: const Icon(Icons.play_circle_outline_rounded),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnasheed(AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            key: const ValueKey('anasheed-search'),
            controller: _anasheedSearch,
            textInputAction: TextInputAction.search,
            onChanged: _onAnasheedQueryChanged,
            onSubmitted: _searchAnasheed,
            decoration: InputDecoration(
              hintText: l10n.anasheedSearchHint,
              prefixIcon: const Icon(Icons.search_rounded, size: 19),
              suffixIcon: _anasheedSearch.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _anasheedSearch.clear();
                        _searchAnasheed('');
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
            ),
          ),
        ),
        Expanded(child: _anasheedBody(l10n, scheme)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            l10n.anasheedSourceNote,
            style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _buildRadio(AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    final currentId = _playback.current?.id;
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Text(
            l10n.audioRadioHint,
            style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
          ),
        ),
        for (final radio in islamicRadios)
          Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              leading: CircleAvatar(
                radius: 17,
                backgroundColor: scheme.primary.withValues(alpha: 0.12),
                child: Icon(
                  Icons.radio_rounded,
                  size: 18,
                  color: currentId == 'radio:${radio.id}'
                      ? SakeenahColors.gold
                      : scheme.primary,
                ),
              ),
              title: Text(
                radio.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: scheme.onSurface),
              ),
              subtitle: Text(
                radio.country,
                style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
              ),
              trailing: IconButton(
                key: ValueKey('radio-play-${radio.id}'),
                tooltip: l10n.audioPlay,
                onPressed: () => _playRadio(radio),
                icon: Icon(
                  currentId == 'radio:${radio.id}'
                      ? Icons.graphic_eq_rounded
                      : Icons.play_circle_outline_rounded,
                  color: currentId == 'radio:${radio.id}'
                      ? SakeenahColors.gold
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _playRadio(IslamicRadio radio) async {
    try {
      await _playback.playQueue([radio.toAudioTrack()]);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.audioPlaybackError),
        ),
      );
    }
  }

  Widget _anasheedBody(AppLocalizations l10n, ColorScheme scheme) {
    if (_anasheedLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_anasheedFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.anasheedError),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => _searchAnasheed(_anasheedSearch.text),
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }
    if (_anasheedResults.isEmpty) {
      return Center(
        child: Text(
          l10n.anasheedEmpty,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      itemCount: _anasheedResults.length,
      itemBuilder: (context, index) {
        final track = _anasheedResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            leading: CircleAvatar(
              radius: 17,
              backgroundColor: scheme.primary.withValues(alpha: 0.12),
              child: Icon(
                Icons.music_note_rounded,
                size: 18,
                color: scheme.primary,
              ),
            ),
            title: Text(
              track.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: scheme.onSurface),
            ),
            subtitle: Text(
              [
                if (track.creator.isNotEmpty) track.creator,
                track.licenseLabel,
                if (track.source.isNotEmpty) track.source,
              ].join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant),
            ),
            trailing: IconButton(
              key: ValueKey('anasheed-play-${track.id}'),
              tooltip: l10n.audioPlaySurah,
              onPressed: () => _playAnasheed(index),
              icon: const Icon(Icons.play_circle_outline_rounded),
            ),
          ),
        );
      },
    );
  }
}
