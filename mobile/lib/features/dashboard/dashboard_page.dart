import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../data/app_services.dart';
import '../../data/worship/prayer_log.dart';
import '../../data/worship/prayer_schedule.dart';
import '../../data/worship/prayer_times_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/feature_card.dart';
import '../../widgets/qibla_dial.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.onSelectTab, this.clock});

  final ValueChanged<int> onSelectTab;
  final DateTime Function()? clock;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final AppServices _services = AppServices.current;
  Timer? _ticker;
  PrayerSchedule? _schedule;
  DateTime _now = DateTime.now().toUtc();
  PrayerDay? _day;
  PrayerStreak? _streak;
  bool _unavailable = false;
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    _services.prayerSettings.addListener(_refresh);
    _refresh();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = _nowUtc();
      final schedule = _schedule;
      if (schedule == null || !schedule.isSameLocalDate(now)) {
        _refresh();
        return;
      }
      setState(() => _now = now);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _services.prayerSettings.removeListener(_refresh);
    super.dispose();
  }

  DateTime _nowUtc() => (widget.clock?.call() ?? DateTime.now()).toUtc();

  void _refresh({bool loadDay = true}) {
    _now = _nowUtc();
    final schedule = const PrayerScheduleService().tryBuild(
      _services.prayerSettings.value,
      nowUtc: _now,
    );
    if (schedule == null) {
      if (mounted) {
        setState(() {
          _schedule = null;
          _unavailable = true;
        });
      }
      return;
    }
    final dateChanged = _schedule?.dateKey != schedule.dateKey;
    if (mounted) {
      setState(() {
        _schedule = schedule;
        _unavailable = false;
      });
    }
    if (loadDay || dateChanged) _loadDay(schedule.dateKey);
  }

  Future<void> _loadDay(String date) async {
    final token = ++_loadToken;
    final day = await _services.prayerLog.day(date);
    final streak = await _services.prayerLog.streak(date);
    if (!mounted || token != _loadToken || _schedule?.dateKey != date) return;
    setState(() {
      _day = day;
      _streak = streak;
    });
  }

  Future<void> _setStatus(PrayerSlot slot, PrayerStatus? status) async {
    final schedule = _schedule;
    if (schedule == null) return;
    if (status != null && !schedule.passedAt(slot.name, _now)) return;
    await _services.prayerLog.setStatus(slot.ownerDate, slot.name, status);
    final today = _schedule?.dateKey;
    if (today != null) await _loadDay(today);
    await _refreshWidgets();
  }

  Future<void> _refreshWidgets() async {
    try {
      await _services.widgets.refresh();
    } catch (_) {
      // Widgets are a convenience; logging must never fail because of them.
    }
  }

  Future<void> _togglePrayer(PrayerSlot slot) async {
    final current = slot.ownerDate == _schedule?.dateKey
        ? _day?.statusOf(slot.name)
        : null;
    await _setStatus(
      slot,
      current?.countsAsDone == true ? null : PrayerStatus.onTime,
    );
  }

  Future<void> _toggleExcused() async {
    final date = _schedule?.dateKey;
    if (date == null) return;
    await _services.prayerLog.setExcused(date, !(_day?.excused ?? false));
    await _loadDay(date);
    await _refreshWidgets();
  }

  @override
  Widget build(BuildContext context) {
    final schedule = _schedule;
    if (_unavailable) return _UnavailableView();
    if (schedule == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      children: [
        if (!schedule.settings.configured) ...[
          _LocationHint(text: l10n.prayerLocationMissing),
          const SizedBox(height: 12),
        ],
        _PrayerHero(schedule: schedule, streak: _streak, nowUtc: _now),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      l10n.prayerToday,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      schedule.hijri.formatAr(),
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (final slot in schedule.displayAt(_now)) ...[
                  if (slot.name == PrayerName.sunrise)
                    _SunriseRow(slot: slot, label: l10n.sunrise)
                  else
                    _PrayerRow(
                      key: ValueKey('prayer-${slot.ownerDate}-${slot.name.id}'),
                      slot: slot,
                      status: slot.ownerDate == schedule.dateKey
                          ? _day?.statusOf(slot.name)
                          : null,
                      excused: _day?.excused ?? false,
                      passed: schedule.passedAt(slot.name, _now),
                      enabled:
                          schedule.passedAt(slot.name, _now) ||
                          (slot.ownerDate == schedule.dateKey &&
                              _day?.statusOf(slot.name) != null) ||
                          (_day?.excused ?? false),
                      onTap: () => _togglePrayer(slot),
                      onAction: (action) => _setStatus(slot, switch (action) {
                        PrayerAction.onTime => PrayerStatus.onTime,
                        PrayerAction.late => PrayerStatus.late,
                        PrayerAction.qada => PrayerStatus.qada,
                        PrayerAction.missed => PrayerStatus.missed,
                        PrayerAction.clear => null,
                      }),
                    ),
                  if (slot.name != PrayerName.isha)
                    Divider(
                      height: 8,
                      color: scheme.outline.withValues(alpha: 0.5),
                    ),
                ],
                const SizedBox(height: 10),
                _StreakRow(
                  streak: _streak,
                  excused: _day?.excused ?? false,
                  onExcused: _toggleExcused,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: width,
                  child: FeatureCard(
                    icon: Icons.menu_book_outlined,
                    title: l10n.quranCardTitle,
                    body: l10n.quranCardBody,
                    onTap: () => widget.onSelectTab(1),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: FeatureCard(
                    icon: Icons.nights_stay_outlined,
                    title: l10n.adhkarCardTitle,
                    body: l10n.adhkarCardBody,
                    onTap: () => widget.onSelectTab(2),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: FeatureCard(
                    icon: Icons.headphones_outlined,
                    title: l10n.audioCardTitle,
                    body: l10n.audioCardBody,
                    onTap: () => widget.onSelectTab(3),
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

class _UnavailableView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore_off_outlined, size: 36, color: scheme.primary),
            const SizedBox(height: 12),
            Text(
              l10n.prayerTimesUnavailable,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.7,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerHero extends StatelessWidget {
  const _PrayerHero({
    required this.schedule,
    required this.streak,
    required this.nowUtc,
  });

  final PrayerSchedule schedule;
  final PrayerStreak? streak;
  final DateTime nowUtc;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final next = schedule.nextAt(nowUtc);
    return Container(
      key: const ValueKey('dashboard-prayer-hero'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [scheme.primary.withValues(alpha: 0.17), scheme.surface],
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.mosque_rounded,
                          size: 17,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l10n.prayerNext,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      next.name.arabicName,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      next.timeLabel,
                      style: TextStyle(
                        fontSize: 34,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.prayerTimeRemaining(
                        _remaining(schedule.remainingAt(nowUtc)),
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  QiblaDial(bearing: schedule.qibla),
                  const SizedBox(height: 4),
                  Text(
                    l10n.qiblaTitle,
                    style: TextStyle(
                      fontSize: 9,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: scheme.outline.withValues(alpha: 0.6), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 15,
                color: scheme.secondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  schedule.hijri.formatAr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 17,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${streak?.current ?? 0}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.prayerStreak,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _remaining(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

class _LocationHint extends StatelessWidget {
  const _LocationHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: scheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.secondary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.location_off_outlined, size: 17, color: scheme.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum PrayerAction { onTime, late, qada, missed, clear }

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    super.key,
    required this.slot,
    required this.status,
    required this.excused,
    required this.passed,
    required this.enabled,
    required this.onTap,
    required this.onAction,
  });

  final PrayerSlot slot;
  final PrayerStatus? status;
  final bool excused;
  final bool passed;
  final bool enabled;
  final VoidCallback onTap;
  final ValueChanged<PrayerAction> onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final done = status?.countsAsDone ?? false;
    final muted = !passed && status == null;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              _icon(status, excused),
              size: 20,
              color: done
                  ? scheme.primary
                  : status == PrayerStatus.missed
                  ? scheme.error
                  : excused
                  ? scheme.secondary
                  : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                slot.name.arabicName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                  color: muted ? scheme.onSurfaceVariant : scheme.onSurface,
                ),
              ),
            ),
            if (status != null && status != PrayerStatus.onTime)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: Text(
                  status == PrayerStatus.excused
                      ? l10n.prayerExcusedDay
                      : status!.arabicName,
                  style: TextStyle(
                    fontSize: 10,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            Text(
              slot.timeLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: muted ? scheme.onSurfaceVariant : scheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            PopupMenuButton<PrayerAction>(
              enabled: enabled,
              tooltip: MaterialLocalizations.of(context).showMenuTooltip,
              icon: Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              onSelected: onAction,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: PrayerAction.onTime,
                  child: Text(l10n.prayerMarkOnTime),
                ),
                PopupMenuItem(
                  value: PrayerAction.late,
                  child: Text(l10n.prayerMarkLate),
                ),
                PopupMenuItem(
                  value: PrayerAction.qada,
                  child: Text(l10n.prayerMarkQada),
                ),
                PopupMenuItem(
                  value: PrayerAction.missed,
                  child: Text(l10n.prayerMarkMissed),
                ),
                PopupMenuItem(
                  value: PrayerAction.clear,
                  child: Text(l10n.prayerClear),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon(PrayerStatus? status, bool excused) {
    if (excused) return Icons.free_breakfast_outlined;
    return switch (status) {
      PrayerStatus.onTime => Icons.check_circle_rounded,
      PrayerStatus.late => Icons.schedule_rounded,
      PrayerStatus.qada => Icons.replay_rounded,
      PrayerStatus.missed => Icons.cancel_outlined,
      PrayerStatus.excused => Icons.free_breakfast_outlined,
      null => Icons.radio_button_unchecked,
    };
  }
}

class _SunriseRow extends StatelessWidget {
  const _SunriseRow({required this.slot, required this.label});

  final PrayerSlot slot;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.wb_sunny_outlined, size: 19, color: scheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ),
          Text(
            slot.timeLabel,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _StreakRow extends StatelessWidget {
  const _StreakRow({
    required this.streak,
    required this.excused,
    required this.onExcused,
  });

  final PrayerStreak? streak;
  final bool excused;
  final VoidCallback onExcused;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _Chip(
              icon: Icons.local_fire_department_rounded,
              text: '${l10n.prayerStreak} ${streak?.current ?? 0}',
            ),
            _Chip(
              icon: Icons.today_outlined,
              text: l10n.prayerTodayProgress(streak?.todayCount ?? 0),
            ),
            _Chip(
              icon: Icons.emoji_events_outlined,
              text: '${l10n.prayerBestStreak} ${streak?.best ?? 0}',
            ),
          ],
        ),
        const SizedBox(height: 2),
        TextButton.icon(
          onPressed: onExcused,
          icon: Icon(
            excused ? Icons.undo_rounded : Icons.free_breakfast_outlined,
            size: 16,
          ),
          label: Text(
            excused ? l10n.prayerUnExcuse : l10n.prayerExcuse,
            style: const TextStyle(fontSize: 10),
          ),
          style: TextButton.styleFrom(
            foregroundColor: excused
                ? scheme.secondary
                : scheme.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(0, 30),
            alignment: AlignmentDirectional.centerStart,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: scheme.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10,
                color: scheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
