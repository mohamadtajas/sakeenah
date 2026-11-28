import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../data/app_services.dart';
import '../../data/models/quran.dart';
import '../../data/repositories/quran_reader_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/sakeenah_theme.dart';

class QuranReaderPage extends StatefulWidget {
  const QuranReaderPage.surah({
    super.key,
    required int this.surah,
    this.initialAyah,
  }) : juz = null;

  const QuranReaderPage.juz({
    super.key,
    required int this.juz,
    this.initialAyah,
  }) : surah = null;

  final int? surah;
  final int? juz;
  final int? initialAyah;

  @override
  State<QuranReaderPage> createState() => _QuranReaderPageState();
}

class _QuranReaderPageState extends State<QuranReaderPage> {
  late final AppServices _services = AppServices.current;
  final ItemScrollController _scroll = ItemScrollController();
  final ItemPositionsListener _positions = ItemPositionsListener.create();
  Timer? _saveTimer;
  AppLifecycleListener? _lifecycle;
  ({int surah, int ayah})? _pending;
  List<_Entry> _entries = const [];
  Set<String> _bookmarked = {};
  int _fontSize = QuranReaderRepository.defaultFontSize;
  int _initialIndex = 0;
  String _surahTitle = '';
  bool _loading = true;
  bool _failed = false;
  bool _canPop = false;
  bool _popping = false;
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onPause: () => unawaited(_flushPending()),
    );
    _load();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _lifecycle?.dispose();
    _positions.itemPositions.removeListener(_onPositions);
    unawaited(_flushPending());
    super.dispose();
  }

  Future<void> _flushPending() async {
    _saveTimer?.cancel();
    final pending = _pending;
    if (pending == null) return;
    _pending = null;
    try {
      await _services.quranReader.savePosition(pending.surah, pending.ayah);
    } catch (_) {
      // Keep the position so the next pause/back can retry instead of
      // silently losing it.
      _pending ??= pending;
    }
  }

  Future<void> _load() async {
    final token = ++_loadToken;
    try {
      final quran = _services.quran;
      final size = await _services.quranReader.fontSize();
      final bookmarks = await _services.quranReader.bookmarks();
      final entries = <_Entry>[];
      Surah? header;
      if (widget.surah != null) {
        header = await quran.surahByNumber(widget.surah!);
        final ayahs = await quran.ayahsForSurah(widget.surah!);
        if (header != null) entries.add(_Entry.surah(header));
        entries.addAll(ayahs.map(_Entry.ayah));
      } else {
        final ayahs = await quran.ayahsForJuz(widget.juz!);
        final surahs = {
          for (final surah in await quran.surahs()) surah.number: surah,
        };
        var current = -1;
        for (final ayah in ayahs) {
          if (ayah.surah != current) {
            current = ayah.surah;
            final surah = surahs[ayah.surah];
            if (surah != null) {
              entries.add(_Entry.surah(surah, showBismillah: ayah.number == 1));
            }
          }
          entries.add(_Entry.ayah(ayah));
        }
      }
      var initialIndex = 0;
      final initialAyah = widget.initialAyah;
      if (initialAyah != null) {
        final index = entries.indexWhere(
          (entry) => entry.ayah?.number == initialAyah,
        );
        if (index >= 0) initialIndex = index;
      }
      if (!mounted || token != _loadToken) return;
      setState(() {
        _entries = entries;
        _bookmarked = {
          for (final bookmark in bookmarks)
            '${bookmark.surah}:${bookmark.ayah}',
        };
        _fontSize = size;
        _initialIndex = initialIndex;
        _surahTitle = header?.name ?? '';
        _loading = false;
        _failed = false;
      });
      _positions.itemPositions.addListener(_onPositions);
    } catch (_) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _failed = false;
    });
    _load();
  }

  void _onPositions() {
    final positions = _positions.itemPositions.value;
    if (positions.isEmpty) return;
    final visible =
        positions.where((position) => position.itemTrailingEdge > 0).toList()
          ..sort((a, b) => a.index.compareTo(b.index));
    for (final position in visible) {
      if (position.index < 0 || position.index >= _entries.length) continue;
      final ayah = _entries[position.index].ayah;
      if (ayah != null) {
        _queueSave(ayah);
        return;
      }
    }
  }

  void _queueSave(Ayah ayah) {
    _pending = (surah: ayah.surah, ayah: ayah.number);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      unawaited(_flushPending());
    });
  }

  void _saveNow(Ayah ayah) {
    _pending = (surah: ayah.surah, ayah: ayah.number);
    _saveTimer?.cancel();
    unawaited(_flushPending());
  }

  Future<void> _toggleBookmark(Ayah ayah) async {
    try {
      await _services.quranReader.toggleBookmark(ayah.surah, ayah.number);
      final bookmarked = await _services.quranReader.isBookmarked(
        ayah.surah,
        ayah.number,
      );
      if (!mounted) return;
      final key = '${ayah.surah}:${ayah.number}';
      setState(() {
        if (bookmarked) {
          _bookmarked.add(key);
        } else {
          _bookmarked.remove(key);
        }
      });
    } catch (_) {
      // Leave the previous icon state on a failed write.
    }
  }

  Future<void> _changeFont(int delta) async {
    final previous = _fontSize;
    final next = (_fontSize + delta).clamp(
      QuranReaderRepository.minFontSize,
      QuranReaderRepository.maxFontSize,
    );
    if (next == _fontSize) return;
    setState(() => _fontSize = next);
    try {
      await _services.quranReader.saveFontSize(next);
    } catch (_) {
      if (mounted) setState(() => _fontSize = previous);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final title = widget.surah != null
        ? _surahTitle
        : l10n.quranJuz(widget.juz!);
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_handlePop());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            IconButton(
              key: const ValueKey('quran-font-decrease'),
              tooltip: l10n.quranFontDecrease,
              onPressed: _fontSize <= QuranReaderRepository.minFontSize
                  ? null
                  : () => _changeFont(-2),
              icon: const Icon(Icons.text_decrease_rounded),
            ),
            IconButton(
              key: const ValueKey('quran-font-increase'),
              tooltip: l10n.quranFontIncrease,
              onPressed: _fontSize >= QuranReaderRepository.maxFontSize
                  ? null
                  : () => _changeFont(2),
              icon: const Icon(Icons.text_increase_rounded),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _failed
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.quranReaderError,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _retry, child: Text(l10n.retry)),
                  ],
                ),
              )
            : ScrollablePositionedList.builder(
                initialScrollIndex: _initialIndex,
                itemCount: _entries.length,
                itemScrollController: _scroll,
                itemPositionsListener: _positions,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  final surah = entry.surah;
                  if (surah != null) {
                    return _SurahHeader(
                      surah: surah,
                      showBismillah: entry.showBismillah,
                    );
                  }
                  final ayah = entry.ayah!;
                  return _AyahTile(
                    ayah: ayah,
                    fontSize: _fontSize.toDouble(),
                    bookmarked: _bookmarked.contains(
                      '${ayah.surah}:${ayah.number}',
                    ),
                    onTap: () => _saveNow(ayah),
                    onBookmark: () => _toggleBookmark(ayah),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _handlePop() async {
    if (_canPop || _popping) return;
    _popping = true;
    try {
      await _flushPending();
    } finally {
      _popping = false;
      if (mounted) {
        setState(() => _canPop = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).pop();
        });
      }
    }
  }
}

class _Entry {
  const _Entry.surah(Surah this.surah, {this.showBismillah = true})
    : ayah = null;

  const _Entry.ayah(Ayah this.ayah) : surah = null, showBismillah = false;

  final Surah? surah;
  final Ayah? ayah;
  final bool showBismillah;
}

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.surah, required this.showBismillah});

  final Surah surah;
  final bool showBismillah;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 10),
      child: Column(
        children: [
          Text(
            surah.name,
            textAlign: TextAlign.center,
            style: SakeenahTheme.quran(
              Theme.of(context).textTheme.headlineSmall!,
              size: 30,
            ).copyWith(color: scheme.primary),
          ),
          const SizedBox(height: 4),
          Text(
            '${surah.isMakkan ? l10n.quranMakkah : l10n.quranMadinah} · '
            '${l10n.quranAyahCount(surah.ayahCount)}',
            style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
          ),
          if (showBismillah && surah.bismillah != null) ...[
            const SizedBox(height: 14),
            Text(
              surah.bismillah!,
              textAlign: TextAlign.center,
              style: SakeenahTheme.quran(
                Theme.of(context).textTheme.titleLarge!,
                size: 24,
              ).copyWith(color: scheme.onSurface),
            ),
          ],
          const SizedBox(height: 8),
          Divider(color: scheme.outline),
        ],
      ),
    );
  }
}

class _AyahTile extends StatelessWidget {
  const _AyahTile({
    required this.ayah,
    required this.fontSize,
    required this.bookmarked,
    required this.onTap,
    required this.onBookmark,
  });

  final Ayah ayah;
  final double fontSize;
  final bool bookmarked;
  final VoidCallback onTap;
  final VoidCallback onBookmark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: l10n.quranAyahLabel(ayah.number),
      child: InkWell(
        key: ValueKey('quran-ayah-${ayah.surah}-${ayah.number}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: scheme.primary.withValues(alpha: 0.12),
                      child: Text(
                        '${ayah.number}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ),
                  if (ayah.sajda) ...[
                    const SizedBox(width: 6),
                    Text(
                      l10n.quranSajda,
                      style: TextStyle(
                        fontSize: 9,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    key: ValueKey(
                      'quran-bookmark-${ayah.surah}-${ayah.number}',
                    ),
                    tooltip: bookmarked
                        ? l10n.quranRemoveBookmark
                        : l10n.quranAddBookmark,
                    visualDensity: VisualDensity.compact,
                    onPressed: onBookmark,
                    icon: Icon(
                      bookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 18,
                      color: bookmarked ? scheme.primary : scheme.outline,
                    ),
                  ),
                ],
              ),
              Text(
                ayah.text,
                textDirection: TextDirection.rtl,
                style: SakeenahTheme.quran(
                  Theme.of(context).textTheme.bodyLarge!,
                  size: fontSize,
                ).copyWith(color: scheme.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
