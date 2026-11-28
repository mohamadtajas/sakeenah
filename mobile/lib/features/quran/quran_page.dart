import 'package:material_ui/material_ui.dart';

import '../../data/app_services.dart';
import '../../data/models/local_date.dart';
import '../../data/models/quran.dart';
import '../../data/models/quran_reader.dart';
import '../../data/text.dart';
import '../../data/worship/daily_ayah.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/sakeenah_theme.dart';
import 'quran_reader_page.dart';

class MushafPage extends StatefulWidget {
  const MushafPage({super.key});

  @override
  State<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<MushafPage>
    with SingleTickerProviderStateMixin {
  late final AppServices _services = AppServices.current;
  late final TabController _tabs = TabController(length: 4, vsync: this);
  final TextEditingController _search = TextEditingController();
  List<Surah> _surahs = const [];
  List<Juz> _juzs = const [];
  Map<int, Surah> _surahById = const {};
  List<QuranBookmark> _bookmarks = const [];
  ReaderPosition? _position;
  Ayah? _daily;
  bool _loading = true;
  bool _failed = false;
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = ++_loadToken;
    try {
      final surahs = await _services.quran.surahs();
      final juzs = await _services.quran.juzs();
      final bookmarks = await _services.quranReader.bookmarks();
      final position = await _services.quranReader.position();
      final daily = await _services.quran.ayahByOrdinal(
        dailyAyahOrdinal(localDateKey(DateTime.now())),
      );
      if (!mounted || token != _loadToken) return;
      setState(() {
        _surahs = surahs;
        _juzs = juzs;
        _surahById = {for (final surah in surahs) surah.number: surah};
        _bookmarks = bookmarks;
        _position = position;
        _daily = daily;
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        _loading = false;
        _failed = _surahs.isEmpty;
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

  Future<void> _openSurah(Surah surah, {int? ayah}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            QuranReaderPage.surah(surah: surah.number, initialAyah: ayah),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _openJuz(Juz juz) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuranReaderPage.juz(juz: juz.number),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _openBookmark(QuranBookmark bookmark) async {
    final surah = _surahById[bookmark.surah];
    if (surah == null) return;
    await _openSurah(surah, ayah: bookmark.ayah);
  }

  String _surahName(int number) =>
      _surahById[number]?.name ?? number.toString();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_failed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 42, color: scheme.outline),
              const SizedBox(height: 12),
              Text(
                l10n.quranReaderError,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _retry, child: Text(l10n.retry)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: l10n.quranTabSurahs),
            Tab(text: l10n.quranTabJuz),
            Tab(text: l10n.quranTabBookmarks),
            Tab(text: l10n.quranTabResume),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _surahTab(l10n),
              _juzTab(l10n),
              _bookmarksTab(l10n),
              _resumeTab(l10n),
            ],
          ),
        ),
      ],
    );
  }

  Widget _surahTab(AppLocalizations l10n) {
    final query = normalizeArabic(_search.text);
    final filtered = query.isEmpty
        ? _surahs
        : _surahs
              .where(
                (surah) =>
                    normalizeArabic(surah.name).contains(query) ||
                    normalizeArabic(surah.englishName).contains(query) ||
                    normalizeArabic(surah.meaning).contains(query),
              )
              .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            key: const ValueKey('quran-search'),
            controller: _search,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.quranSearch,
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
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    l10n.quranSearchEmpty,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final surah = filtered[index];
                    return _SurahTile(
                      surah: surah,
                      onTap: () => _openSurah(surah),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _juzTab(AppLocalizations l10n) {
    return ListView.builder(
      key: const ValueKey('juz-list'),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      itemCount: _juzs.length,
      itemBuilder: (context, index) {
        final juz = _juzs[index];
        final surah = _surahName(juz.surah);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            onTap: () => _openJuz(juz),
            leading: CircleAvatar(
              radius: 18,
              child: Text(
                '${juz.number}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            title: Text(l10n.quranJuz(juz.number)),
            subtitle: Text(
              l10n.quranJuzStart(surah, juz.ayah),
              style: const TextStyle(fontSize: 10),
            ),
            trailing: Text(
              l10n.quranAyahCount(juz.ayahCount),
              style: const TextStyle(fontSize: 10),
            ),
          ),
        );
      },
    );
  }

  Widget _bookmarksTab(AppLocalizations l10n) {
    if (_bookmarks.isEmpty) {
      return Center(
        child: Text(
          l10n.quranNoBookmarks,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
      itemCount: _bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = _bookmarks[index];
        return ListTile(
          onTap: () => _openBookmark(bookmark),
          leading: const Icon(Icons.bookmark_rounded),
          title: Text(
            l10n.quranBookmarkAt(_surahName(bookmark.surah), bookmark.ayah),
          ),
          trailing: IconButton(
            tooltip: l10n.quranRemoveBookmark,
            onPressed: () async {
              await _services.quranReader.removeBookmark(
                bookmark.surah,
                bookmark.ayah,
              );
              if (mounted) await _load();
            },
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        );
      },
    );
  }

  Widget _resumeTab(AppLocalizations l10n) {
    final position = _position;
    final daily = _daily;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (position == null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                l10n.quranNoResume,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          Card(
            child: ListTile(
              onTap: () {
                final surah = _surahById[position.surah];
                if (surah != null) {
                  _openSurah(surah, ayah: position.ayah);
                }
              },
              leading: const Icon(Icons.auto_stories_rounded),
              title: Text(l10n.quranContinue),
              subtitle: Text(
                l10n.quranResumeAt(_surahName(position.surah), position.ayah),
              ),
              trailing: const Icon(Icons.chevron_left_rounded),
            ),
          ),
        if (daily != null) ...[
          const SizedBox(height: 14),
          Card(
            child: InkWell(
              key: const ValueKey('quran-daily-ayah-card'),
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                final surah = _surahById[daily.surah];
                if (surah != null) {
                  _openSurah(surah, ayah: daily.number);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.quranDailyAyah,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      daily.text,
                      textAlign: TextAlign.center,
                      style:
                          SakeenahTheme.quran(
                            Theme.of(context).textTheme.bodyLarge!,
                            size: 24,
                          ).copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.quranBookmarkAt(
                        _surahName(daily.surah),
                        daily.number,
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SurahTile extends StatelessWidget {
  const _SurahTile({required this.surah, required this.onTap});

  final Surah surah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: scheme.primary.withValues(alpha: 0.12),
          child: Text(
            '${surah.number}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
        ),
        title: Text(
          surah.name,
          style: SakeenahTheme.quran(
            Theme.of(context).textTheme.titleMedium!,
            size: 19,
          ).copyWith(color: scheme.onSurface),
        ),
        subtitle: Text(
          '${surah.englishName} · ${l10n.quranAyahCount(surah.ayahCount)}',
          style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
        ),
        trailing: Text(
          surah.isMakkan ? l10n.quranMakkah : l10n.quranMadinah,
          style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
