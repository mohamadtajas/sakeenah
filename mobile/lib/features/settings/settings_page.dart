import 'package:home_widget/home_widget.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/app_services.dart';
import '../../data/audio/quran_audio_catalog.dart';
import '../../data/cities.dart';
import '../../data/location/device_location.dart';
import '../../data/location/location_service.dart';
import '../../data/models/adhan.dart';
import '../../data/models/adhkar_reminders.dart';
import '../../data/worship/adhan_scheduler.dart';
import '../../data/worship/prayer_method.dart';
import '../../data/worship/prayer_notification_service.dart';
import '../../data/widgets/widget_bridge.dart';
import 'credits_page.dart';
import '../../data/worship/coordinate_input.dart';
import '../../data/worship/prayer_settings.dart';
import '../../data/worship/timezone_bootstrap.dart';
import '../../l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.location,
    this.locale = const Locale('ar'),
    this.onLocaleChanged,
    this.adhanScheduler,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final LocationService location;
  final Locale locale;
  final ValueChanged<Locale>? onLocaleChanged;
  final AdhanScheduler? adhanScheduler;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late ThemeMode _mode = widget.themeMode;
  late Locale _locale = widget.locale;
  late final AppServices _services = AppServices.current;
  late PrayerSettings _settings = _services.prayerSettings.value;
  late final TextEditingController _latitude = TextEditingController(
    text: _settings.latitude.toStringAsFixed(4),
  );
  late final TextEditingController _longitude = TextEditingController(
    text: _settings.longitude.toStringAsFixed(4),
  );
  late String? _cityId = _settings.cityId;
  late String _timezone = _settings.timezone;
  late PrayerMethod _method = _settings.method;
  late PrayerMadhab _madhab = _settings.madhab;
  late PrayerHighLatitude _highLatitude = _settings.highLatitude;
  late int _hijriAdjustment = _settings.hijriAdjustment;
  late String? _locationSource = _settings.locationSource;
  bool _saving = false;
  bool _locating = false;
  late final AdhanScheduler _adhanScheduler =
      widget.adhanScheduler ?? _services.adhanScheduler;
  AdhanPreferences _adhan = AdhanPreferences.defaults();
  AdhkarReminderPreferences _adhkar = AdhkarReminderPreferences.defaults();
  AdhanDiagnostics? _health;
  late String? _defaultReciterId = _services.defaultReciterId;
  bool _adhanBusy = false;

  late final List<String> _timezones = _buildTimezones();

  @override
  void initState() {
    super.initState();
    _loadAdhan();
  }

  Future<void> _loadAdhan() async {
    try {
      final prefs = await _adhanScheduler.preferences.load();
      final adhkar = await _adhanScheduler.loadAdhkarPreferences();
      final health = await _adhanScheduler.diagnostics();
      if (mounted) {
        setState(() {
          _adhan = prefs;
          _adhkar = adhkar;
          _health = health;
        });
      }
    } catch (_) {
      // Keep the defaults already shown; saving still works.
    }
  }

  Future<void> _refreshHealth() async {
    try {
      final health = await _adhanScheduler.diagnostics();
      if (mounted) setState(() => _health = health);
    } catch (_) {}
  }

  @override
  void dispose() {
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locale != widget.locale) _locale = widget.locale;
  }

  List<String> _buildTimezones() {
    final values = allTimezoneNames();
    if (!values.contains(_timezone)) values.add(_timezone);
    return values..sort();
  }

  void _pickCity(String? value) {
    if (value == null || value == 'custom') {
      setState(() {
        _cityId = null;
        _locationSource = 'manual';
      });
      return;
    }
    final city = cityById(value);
    if (city == null) return;
    setState(() {
      _cityId = city.id;
      _timezone = city.timezone;
      _latitude.text = city.latitude.toStringAsFixed(4);
      _longitude.text = city.longitude.toStringAsFixed(4);
      _locationSource = 'city';
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    final result = await widget.location.currentLocation();
    if (!mounted) return;
    if (!result.isSuccess) {
      setState(() => _locating = false);
      _showLocationError(result.failure!);
      return;
    }
    final fix = result.location!;
    setState(() {
      _locating = false;
      _cityId = null;
      _locationSource = 'device';
      _latitude.text = fix.latitude.toStringAsFixed(4);
      _longitude.text = fix.longitude.toStringAsFixed(4);
      _timezone = fix.timezone ?? _timezone;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.locationSaved)),
    );
  }

  void _showLocationError(LocationFailure failure) {
    final l10n = AppLocalizations.of(context)!;
    final message = switch (failure) {
      LocationFailure.denied => l10n.locationDenied,
      LocationFailure.deniedForever => l10n.locationDeniedForever,
      LocationFailure.timeout ||
      LocationFailure.unavailable => l10n.locationUnavailable,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: failure == LocationFailure.deniedForever
            ? SnackBarAction(
                label: l10n.locationOpenSettings,
                onPressed: widget.location.openAppSettings,
              )
            : null,
      ),
    );
  }

  Future<void> _save() async {
    final latitude = parseCoordinate(_latitude.text);
    final longitude = parseCoordinate(_longitude.text);
    if (latitude == null ||
        longitude == null ||
        !isValidLatitude(latitude) ||
        !isValidLongitude(longitude)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.prayerInvalidCoordinates),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final updated = _settings
        .copyWith(
          latitude: latitude,
          longitude: longitude,
          timezone: _timezone,
          method: _method,
          madhab: _madhab,
          highLatitude: _highLatitude,
          hijriAdjustment: _hijriAdjustment,
          configured: true,
          cityId: _cityId,
          clearCity: _cityId == null,
          locationSource: _locationSource,
        )
        .sanitized();
    try {
      await _services.updatePrayerSettings(updated);
      if (!mounted) return;
      setState(() {
        _settings = updated;
        _latitude.text = updated.latitude.toStringAsFixed(4);
        _longitude.text = updated.longitude.toStringAsFixed(4);
        _timezone = updated.timezone;
        _locationSource = updated.locationSource;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.settingsSaved)),
      );
      // Prayer times moved: refresh the two-week notification plan and widgets.
      try {
        await _adhanScheduler.refresh();
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.adhanScheduleFailed),
          ),
        );
      }
      try {
        await _services.widgets.refresh();
      } catch (_) {
        // Widgets update again on the next launch.
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.settingsSaveFailed),
        ),
      );
    }
  }

  Future<void> _saveAdhan(AdhanPreferences next) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _adhan = next;
      _adhanBusy = true;
    });
    try {
      // Save and reschedule separately so a scheduling failure does not
      // pretend the preference itself was lost.
      await _adhanScheduler.preferences.save(next);
      try {
        await _adhanScheduler.refresh();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.adhanScheduleFailed)));
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.adhanSaveFailed)));
      }
    } finally {
      if (mounted) setState(() => _adhanBusy = false);
    }
  }

  Future<void> _enableAdhan() async {
    final l10n = AppLocalizations.of(context)!;
    if (_adhanBusy) return;
    setState(() => _adhanBusy = true);
    try {
      final granted = await _adhanScheduler.requestPermissions();
      if (!mounted) return;
      if (!granted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.adhanPermissionDenied)));
        return;
      }
      await _adhanScheduler.refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.adhanScheduleFailed)));
      }
    } finally {
      if (mounted) setState(() => _adhanBusy = false);
    }
  }

  Future<void> _testAdhan() async {
    final l10n = AppLocalizations.of(context)!;
    if (_adhanBusy) return;
    setState(() => _adhanBusy = true);
    try {
      await _adhanScheduler.sendTest();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.adhanTestSent)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.adhanScheduleFailed)));
    } finally {
      if (mounted) setState(() => _adhanBusy = false);
    }
  }

  Future<void> _saveAdhkar(AdhkarReminderPreferences next) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _adhkar = next;
      _adhanBusy = true;
    });
    try {
      await _adhanScheduler.saveAdhkarPreferences(next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.adhanScheduleFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _adhanBusy = false);
        await _refreshHealth();
      }
    }
  }

  Future<void> _requestExact() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final granted = await _adhanScheduler.requestExactAlarms();
      await _refreshHealth();
      if (!mounted) return;
      if (!granted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.adhanPermissionDenied)));
        return;
      }
      await _adhanScheduler.refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.adhanScheduleFailed)));
    }
  }

  Future<void> _openBattery() async {
    await AlarmSupport.openBatterySettings();
    await _refreshHealth();
  }

  Future<void> _testScheduled() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _adhanScheduler.sendScheduledTest(const Duration(minutes: 2));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.adhanTestScheduled)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.adhanScheduleFailed)));
    }
  }

  Future<void> _pickSleepTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _adhkar.sleepHour,
        minute: _adhkar.sleepMinute,
      ),
    );
    if (picked == null) return;
    await _saveAdhkar(
      _adhkar.copyWith(sleepHour: picked.hour, sleepMinute: picked.minute),
    );
  }

  Future<void> _setDefaultReciter(String id) async {
    setState(() => _defaultReciterId = id);
    await _services.setDefaultReciter(id);
  }

  String _sleepTime(AppLocalizations l10n) {
    final hour = _adhkar.sleepHour.toString().padLeft(2, '0');
    final minute = _adhkar.sleepMinute.toString().padLeft(2, '0');
    return l10n.adhkarSleepAt('$hour:$minute');
  }

  String get _firstReciterId => QuranAudioCatalog.reciters.first.id;

  Future<void> _pinWidget(String provider) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
      if (!supported) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.widgetPinUnsupported)));
        return;
      }
      await _services.widgets.refresh();
      await HomeWidget.requestPinWidget(androidName: provider);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.widgetPinUnsupported)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsPageTitle)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _SectionCard(
            title: l10n.prayerSettings,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_locationSource == 'device')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.my_location_rounded,
                          size: 15,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          l10n.locationSourceDevice,
                          style: TextStyle(fontSize: 10, color: scheme.primary),
                        ),
                      ],
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: _locating ? null : _useCurrentLocation,
                  icon: _locating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded, size: 18),
                  label: Text(l10n.settingsLocationUse),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('city-${_cityId ?? 'custom'}'),
                  initialValue: _cityId ?? 'custom',
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.cityLabel),
                  items: [
                    DropdownMenuItem(
                      value: 'custom',
                      child: Text(l10n.customLocation),
                    ),
                    for (final city in cities)
                      DropdownMenuItem(
                        value: city.id,
                        child: Text(
                          isArabic
                              ? '${city.name} - ${city.country}'
                              : '${city.nameEn} - ${city.countryEn}',
                        ),
                      ),
                  ],
                  onChanged: _pickCity,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _latitude,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.latitudeLabel,
                        ),
                        onChanged: (_) => setState(() {
                          _cityId = null;
                          _locationSource = 'manual';
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _longitude,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.longitudeLabel,
                        ),
                        onChanged: (_) => setState(() {
                          _cityId = null;
                          _locationSource = 'manual';
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownMenu<String>(
                  initialSelection: _timezone,
                  enableFilter: true,
                  requestFocusOnTap: true,
                  expandedInsets: EdgeInsets.zero,
                  menuHeight: 360,
                  label: Text(l10n.timezoneLabel),
                  dropdownMenuEntries: [
                    for (final zone in _timezones)
                      DropdownMenuEntry(value: zone, label: zone),
                  ],
                  onSelected: (value) {
                    if (value != null) {
                      setState(() {
                        _timezone = value;
                        _cityId = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PrayerMethod>(
                  initialValue: _method,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.methodLabel),
                  items: [
                    for (final method in PrayerMethod.values)
                      DropdownMenuItem(
                        value: method,
                        child: Text(method.arabicName),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _method = value);
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.madhabLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                SegmentedButton<PrayerMadhab>(
                  segments: [
                    ButtonSegment(
                      value: PrayerMadhab.shafi,
                      label: Text(l10n.shafi),
                    ),
                    ButtonSegment(
                      value: PrayerMadhab.hanafi,
                      label: Text(l10n.hanafi),
                    ),
                  ],
                  selected: {_madhab},
                  onSelectionChanged: (selection) =>
                      setState(() => _madhab = selection.first),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PrayerHighLatitude>(
                  initialValue: _highLatitude,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.highLatitudeLabel,
                  ),
                  items: [
                    for (final rule in PrayerHighLatitude.values)
                      DropdownMenuItem(
                        value: rule,
                        child: Text(rule.arabicName),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _highLatitude = value);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.hijriAdjustmentLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.prayerClear,
                      onPressed: _hijriAdjustment <= -3
                          ? null
                          : () => setState(() => _hijriAdjustment--),
                      icon: const Icon(Icons.remove_rounded),
                    ),
                    Text(
                      _hijriAdjustment == 0
                          ? '0'
                          : '${_hijriAdjustment > 0 ? '+' : '-'}${_hijriAdjustment.abs()}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      tooltip: l10n.hijriAdjustmentLabel,
                      onPressed: _hijriAdjustment >= 3
                          ? null
                          : () => setState(() => _hijriAdjustment++),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: l10n.adhanSection,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.adhanHint,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.6,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _enableAdhan,
                  icon: const Icon(
                    Icons.notifications_active_outlined,
                    size: 17,
                  ),
                  label: Text(l10n.adhanEnable),
                ),
                const SizedBox(height: 4),
                for (final prayer in obligatoryPrayerNames) ...[
                  SwitchListTile(
                    key: ValueKey('adhan-enable-${prayer.name}'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      prayer.arabicName,
                      style: TextStyle(fontSize: 12, color: scheme.onSurface),
                    ),
                    value: _adhan.isEnabled(prayer),
                    onChanged: _adhanBusy
                        ? null
                        : (value) => _saveAdhan(
                            _adhan.copyWith(
                              enabled: {..._adhan.enabled, prayer: value},
                            ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 4,
                      bottom: 4,
                    ),
                    child: DropdownButtonFormField<int>(
                      key: ValueKey(
                        'adhan-pre-${prayer.name}-${_adhan.preAlertFor(prayer)}',
                      ),
                      initialValue: _adhan.preAlertFor(prayer),
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.adhanPreAlert,
                        isDense: true,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 0,
                          child: Text(l10n.adhanNoPreAlert),
                        ),
                        for (final minutes in const [5, 10, 15, 20])
                          DropdownMenuItem(
                            value: minutes,
                            child: Text(l10n.adhanMinutes(minutes)),
                          ),
                      ],
                      onChanged: _adhanBusy
                          ? null
                          : (value) {
                              if (value == null) return;
                              _saveAdhan(
                                _adhan.copyWith(
                                  preAlerts: {
                                    ..._adhan.preAlerts,
                                    prayer: value,
                                  },
                                ),
                              );
                            },
                    ),
                  ),
                ],
                Text(
                  l10n.adhanSound,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  key: ValueKey('adhan-sound-${_adhan.soundId}'),
                  initialValue: _adhan.soundId,
                  isExpanded: true,
                  decoration: const InputDecoration(isDense: true),
                  items: [
                    DropdownMenuItem(
                      value: 'beautiful',
                      child: Text(l10n.adhanSoundBeautiful),
                    ),
                    DropdownMenuItem(
                      value: 'adhan',
                      child: Text(l10n.adhanSoundAdhan),
                    ),
                    DropdownMenuItem(
                      value: 'sabah',
                      child: Text(l10n.adhanSoundSabah),
                    ),
                    DropdownMenuItem(
                      value: 'silent',
                      child: Text(l10n.adhanSoundSilent),
                    ),
                  ],
                  onChanged: _adhanBusy
                      ? null
                      : (value) {
                          if (value == null) return;
                          _saveAdhan(_adhan.copyWith(soundId: value));
                        },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.adhanSoundHint,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.6,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _testAdhan,
                  icon: const Icon(Icons.notifications_outlined, size: 17),
                  label: Text(l10n.adhanTest),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                  decoration: BoxDecoration(
                    color: scheme.secondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: scheme.secondary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.battery_saver_outlined,
                        size: 16,
                        color: scheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.adhanBatteryTitle,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.adhanBatteryHint,
                              style: TextStyle(
                                fontSize: 10,
                                height: 1.6,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: l10n.adhanHealthTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.adhanHealthHint,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.6,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _HealthPill(
                      label: (_health?.notificationsEnabled ?? true)
                          ? l10n.adhanNotificationsOn
                          : l10n.adhanNotificationsOff,
                      ok: _health?.notificationsEnabled ?? true,
                    ),
                    _HealthPill(
                      label: (_health?.exactAlarms ?? true)
                          ? l10n.adhanExactOn
                          : l10n.adhanExactOff,
                      ok: _health?.exactAlarms ?? true,
                    ),
                    _HealthPill(
                      label: (_health?.batteryOptimized ?? false)
                          ? l10n.adhanBatteryNeedsSetup
                          : l10n.adhanBatteryOk,
                      ok: !(_health?.batteryOptimized ?? false),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.adhanPendingCount(_health?.pendingCount ?? 0),
                  style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    if (!(_health?.exactAlarms ?? true))
                      OutlinedButton(
                        onPressed: _requestExact,
                        child: Text(l10n.adhanAllowExact),
                      ),
                    if (_health?.batteryOptimized ?? false)
                      OutlinedButton(
                        onPressed: _openBattery,
                        child: Text(l10n.adhanOpenBattery),
                      ),
                    TextButton(
                      onPressed: _testAdhan,
                      child: Text(l10n.adhanTestNow),
                    ),
                    TextButton(
                      onPressed: _testScheduled,
                      child: Text(l10n.adhanTestInTwo),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: l10n.adhkarRemindersTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.adhkarRemindersHint,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.6,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                SwitchListTile(
                  key: const ValueKey('adhkar-morning'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.adhkarMorning,
                    style: TextStyle(fontSize: 12, color: scheme.onSurface),
                  ),
                  value: _adhkar.morning,
                  onChanged: _adhanBusy
                      ? null
                      : (value) =>
                            _saveAdhkar(_adhkar.copyWith(morning: value)),
                ),
                if (_adhkar.morning)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 4,
                      bottom: 4,
                    ),
                    child: DropdownButtonFormField<int>(
                      key: ValueKey(
                        'adhkar-morning-offset-${_adhkar.morningOffsetMinutes}',
                      ),
                      initialValue: _adhkar.morningOffsetMinutes,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.adhkarMorning,
                        isDense: true,
                      ),
                      items: [
                        for (final minutes in AdhkarReminderPreferences.offsets)
                          DropdownMenuItem(
                            value: minutes,
                            child: Text(l10n.adhkarAfterFajr(minutes)),
                          ),
                      ],
                      onChanged: _adhanBusy
                          ? null
                          : (value) {
                              if (value == null) return;
                              _saveAdhkar(
                                _adhkar.copyWith(morningOffsetMinutes: value),
                              );
                            },
                    ),
                  ),
                SwitchListTile(
                  key: const ValueKey('adhkar-evening'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.adhkarEvening,
                    style: TextStyle(fontSize: 12, color: scheme.onSurface),
                  ),
                  value: _adhkar.evening,
                  onChanged: _adhanBusy
                      ? null
                      : (value) =>
                            _saveAdhkar(_adhkar.copyWith(evening: value)),
                ),
                if (_adhkar.evening)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 4,
                      bottom: 4,
                    ),
                    child: DropdownButtonFormField<int>(
                      key: ValueKey(
                        'adhkar-evening-offset-${_adhkar.eveningOffsetMinutes}',
                      ),
                      initialValue: _adhkar.eveningOffsetMinutes,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.adhkarEvening,
                        isDense: true,
                      ),
                      items: [
                        for (final minutes in AdhkarReminderPreferences.offsets)
                          DropdownMenuItem(
                            value: minutes,
                            child: Text(l10n.adhkarAfterAsr(minutes)),
                          ),
                      ],
                      onChanged: _adhanBusy
                          ? null
                          : (value) {
                              if (value == null) return;
                              _saveAdhkar(
                                _adhkar.copyWith(eveningOffsetMinutes: value),
                              );
                            },
                    ),
                  ),
                SwitchListTile(
                  key: const ValueKey('adhkar-sleep'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.adhkarSleep,
                    style: TextStyle(fontSize: 12, color: scheme.onSurface),
                  ),
                  value: _adhkar.sleep,
                  onChanged: _adhanBusy
                      ? null
                      : (value) => _saveAdhkar(_adhkar.copyWith(sleep: value)),
                ),
                if (_adhkar.sleep)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 4,
                      bottom: 4,
                    ),
                    child: OutlinedButton.icon(
                      onPressed: _adhanBusy ? null : _pickSleepTime,
                      icon: const Icon(Icons.schedule_rounded, size: 17),
                      label: Text(_sleepTime(l10n)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: l10n.defaultReciterTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.defaultReciterHint,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.6,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  key: ValueKey(
                    'default-reciter-${_defaultReciterId ?? 'none'}',
                  ),
                  initialValue: _defaultReciterId ?? _firstReciterId,
                  isExpanded: true,
                  items: [
                    for (final reciter in QuranAudioCatalog.reciters)
                      DropdownMenuItem(
                        value: reciter.id,
                        child: Text(
                          '${reciter.name} · ${reciter.style}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) _setDefaultReciter(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: l10n.languageSection,
            child: SegmentedButton<Locale>(
              segments: [
                ButtonSegment(
                  value: const Locale('ar'),
                  label: Text(l10n.languageArabic),
                ),
                ButtonSegment(
                  value: const Locale('en'),
                  label: Text(l10n.languageEnglish),
                ),
              ],
              selected: {_locale},
              onSelectionChanged: (selection) {
                final next = selection.first;
                setState(() => _locale = next);
                widget.onLocaleChanged?.call(next);
              },
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: l10n.themeSection,
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode_outlined),
                  label: Text(l10n.themeDark),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode_outlined),
                  label: Text(l10n.themeLight),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) {
                final mode = selection.first;
                setState(() => _mode = mode);
                widget.onThemeChanged(mode);
              },
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: l10n.creditsSection,
            child: ListTile(
              key: const ValueKey('settings-credits'),
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.info_outline_rounded, color: scheme.primary),
              title: Text(
                l10n.creditsTitle,
                style: TextStyle(fontSize: 12, color: scheme.onSurface),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const CreditsPage()),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: l10n.widgetsSection,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.widgetPinHint,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.6,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                for (final entry in [
                  (PrayerWidgets.nextPrayer, l10n.widgetNextPrayer),
                  (PrayerWidgets.prayerTimes, l10n.widgetPrayerTimes),
                  (PrayerWidgets.streak, l10n.widgetStreak),
                ])
                  ListTile(
                    key: ValueKey('pin-widget-${entry.$1}'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.widgets_outlined,
                      color: scheme.primary,
                    ),
                    title: Text(
                      entry.$2,
                      style: TextStyle(fontSize: 11, color: scheme.onSurface),
                    ),
                    trailing: Icon(
                      Icons.add_circle_outline_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                    onTap: () => _pinWidget(entry.$1),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              l10n.versionLine('0.1.0'),
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _HealthPill extends StatelessWidget {
  const _HealthPill({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = ok ? scheme.primary : scheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.error_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 9, color: color)),
        ],
      ),
    );
  }
}
