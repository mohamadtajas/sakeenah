import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../data/app_services.dart';
import '../../data/models/adhkar.dart';
import '../../data/text.dart';
import '../../data/worship/adhkar_practice.dart';
import '../../data/worship/timezone_bootstrap.dart';
import '../../l10n/app_localizations.dart';
import 'adhkar_category_page.dart';

class AdhkarPage extends StatefulWidget {
  const AdhkarPage({super.key, this.clock, this.onSelectTab});

  /// Test seam; defaults to [DateTime.now].
  final DateTime Function()? clock;
  final ValueChanged<int>? onSelectTab;

  @override
  State<AdhkarPage> createState() => _AdhkarPageState();
}

class _AdhkarPageState extends State<AdhkarPage> {
  late final AppServices _services = AppServices.current;
  final TextEditingController _search = TextEditingController();
  Timer? _dateTimer;
  AppLifecycleListener? _lifecycle;
  List<AdhkarCategory> _categories = const [];
  Map<String, AdhkarCategoryProgress> _progress = const {};
  Map<String, String> _searchIndex = const {};
  AdhkarStreak? _streak;
  bool _loading = true;
  bool _failed = false;
  late String _date = _todayKey();
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    _services.prayerSettings.addListener(_checkDate);
    _load();
    _dateTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkDate(),
    );
    _lifecycle = AppLifecycleListener(onResume: _checkDate);
  }

  @override
  void dispose() {
    _search.dispose();
    _dateTimer?.cancel();
    _lifecycle?.dispose();
    _services.prayerSettings.removeListener(_checkDate);
    super.dispose();
  }

  String _todayKey() => dateKeyInTimezone(
    _services.prayerSettings.value.timezone,
    now: widget.clock?.call(),
  );

  void _checkDate() {
    if (!mounted || _todayKey() == _date) return;
    _load();
  }

  Future<void> _load() async {
    final token = ++_loadToken;
    final today = _todayKey();
    try {
      final categories = await _services.adhkar.categories();
      final progress = await _services.adhkarPractice.allCategoryProgress(
        today,
      );
      final streak = await _services.adhkarPractice.streak(today);
      final searchIndex = await _services.adhkar.searchIndex();
      if (!mounted || token != _loadToken) return;
      setState(() {
        _categories = categories;
        _progress = progress;
        _streak = streak;
        _searchIndex = searchIndex;
        _date = today;
        _loading = false;
        _failed = false;
      });
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

  Future<void> _open(AdhkarCategory category) async {
    _haptic(HapticFeedback.selectionClick);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdhkarCategoryPage(
          category: category,
          clock: widget.clock,
          onGoHome: widget.onSelectTab == null
              ? null
              : () => widget.onSelectTab!(0),
        ),
      ),
    );
    if (!mounted) return;
    _search.clear();
    setState(() {});
    _load();
  }

  void _haptic(Future<void> Function() action) {
    unawaited(action().catchError((_) {}));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_failed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 42,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 14),
              Text(
                l10n.adhkarLoadError,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              FilledButton(onPressed: _retry, child: Text(l10n.retry)),
            ],
          ),
        ),
      );
    }

    final featured = _categories
        .where((category) => category.featured)
        .toList();
    final query = normalizeArabic(_search.text);
    final filtered = query.isEmpty
        ? _categories.where((category) => !category.featured).toList()
        : _categories
              .where(
                (category) =>
                    _searchIndex[category.id]?.contains(query) ?? false,
              )
              .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      children: [
        _StreakHeader(streak: _streak),
        _FeaturedSection(
          visible: query.isEmpty,
          categories: featured,
          progress: _progress,
          onOpen: _open,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: _SectionTitle(text: l10n.adhkarAll)),
            const SizedBox(width: 8),
            Text(
              '${filtered.length}',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('adhkar-search'),
          controller: _search,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.adhkarSearch,
            prefixIcon: const Icon(Icons.search_rounded, size: 19),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.adhkarClearSearch,
                    onPressed: () {
                      _search.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                l10n.adhkarNoResults,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          )
        else
          for (final category in filtered)
            _CategoryRow(
              category: category,
              progress: _progress[category.id],
              onTap: () => _open(category),
            ),
      ],
    );
  }
}

class _StreakHeader extends StatelessWidget {
  const _StreakHeader({required this.streak});

  final AdhkarStreak? streak;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('adhkar-streak-header'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [scheme.secondary.withValues(alpha: 0.14), scheme.surface],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _HeaderLabel(
                icon: Icons.nights_stay_rounded,
                color: scheme.secondary,
                textColor: scheme.onSecondaryContainer,
                text: l10n.adhkarToday,
              ),
              _HeaderLabel(
                icon: Icons.local_fire_department_rounded,
                color: scheme.primary,
                text: l10n.adhkarStreakCount(streak?.current ?? 0),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _TodayChip(
                label: l10n.adhkarMorning,
                done: streak?.todayMorning ?? false,
                icon: Icons.wb_sunny_outlined,
              ),
              _TodayChip(
                label: l10n.adhkarEvening,
                done: streak?.todayEvening ?? false,
                icon: Icons.nightlight_outlined,
              ),
              _HeaderLabel(
                icon: Icons.emoji_events_outlined,
                color: scheme.primary,
                text: l10n.adhkarBestCount(streak?.best ?? 0),
                small: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel({
    required this.icon,
    required this.color,
    required this.text,
    this.small = false,
    this.textColor,
  });

  final IconData icon;
  final Color color;
  final String text;
  final bool small;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: small ? 15 : 18, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: small ? 10 : 12,
              fontWeight: small ? FontWeight.w400 : FontWeight.w700,
              color: textColor ?? (small ? scheme.onSurfaceVariant : color),
            ),
          ),
        ),
      ],
    );
  }
}

class _TodayChip extends StatelessWidget {
  const _TodayChip({
    required this.label,
    required this.done,
    required this.icon,
  });

  final String label;
  final bool done;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: done
            ? scheme.primary.withValues(alpha: 0.12)
            : scheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: done ? scheme.primary.withValues(alpha: 0.35) : scheme.outline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: done ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: done ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 3),
          Icon(
            done ? Icons.check_rounded : Icons.remove_rounded,
            size: 12,
            color: done ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: Theme.of(context).colorScheme.onSurface,
    ),
  );
}

class _FeaturedSection extends StatelessWidget {
  const _FeaturedSection({
    required this.visible,
    required this.categories,
    required this.progress,
    required this.onOpen,
  });

  final bool visible;
  final List<AdhkarCategory> categories;
  final Map<String, AdhkarCategoryProgress> progress;
  final ValueChanged<AdhkarCategory> onOpen;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        _SectionTitle(text: l10n.adhkarFeatured),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final category in categories)
                  SizedBox(
                    width: width,
                    child: _FeaturedCard(
                      category: category,
                      progress: progress[category.id],
                      onTap: () => onOpen(category),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.category,
    required this.progress,
    required this.onTap,
  });

  final AdhkarCategory category;
  final AdhkarCategoryProgress? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = ((progress?.fraction ?? 0) * 100).round();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _iconFor(category.id),
                      size: 19,
                      color: scheme.primary,
                    ),
                  ),
                  const Spacer(),
                  if ((progress?.complete ?? false))
                    Icon(
                      Icons.check_circle_rounded,
                      size: 19,
                      color: scheme.primary,
                    )
                  else
                    Text(
                      '$pct%',
                      style: TextStyle(
                        fontSize: 10,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                category.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress?.fraction ?? 0,
                  minHeight: 4,
                  backgroundColor: scheme.outline,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.progress,
    required this.onTap,
  });

  final AdhkarCategory category;
  final AdhkarCategoryProgress? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final done = progress?.complete ?? false;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: done ? scheme.primary.withValues(alpha: 0.12) : scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: done
                ? scheme.primary.withValues(alpha: 0.35)
                : scheme.outline,
          ),
        ),
        child: Icon(
          _iconFor(category.id),
          size: 18,
          color: done ? scheme.primary : scheme.onSurfaceVariant,
        ),
      ),
      title: Text(
        category.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 13, color: scheme.onSurface),
      ),
      subtitle: Text(
        l10n.adhkarCategoryProgress(
          progress?.completedItems ?? 0,
          category.itemCount,
        ),
        style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
      ),
      trailing: done
          ? Icon(Icons.check_circle_rounded, color: scheme.primary, size: 20)
          : Text(
              '${(((progress?.fraction ?? 0) * 100)).round()}%',
              style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
            ),
    );
  }
}

IconData _iconFor(String categoryId) {
  return switch (categoryId) {
    'morning' => Icons.wb_sunny_outlined,
    'evening' => Icons.nightlight_outlined,
    'sleep' => Icons.bedtime_outlined,
    'waking' => Icons.alarm_rounded,
    'after-prayer' => Icons.mosque_outlined,
    'misc' => Icons.auto_awesome_outlined,
    _ => Icons.menu_book_outlined,
  };
}
