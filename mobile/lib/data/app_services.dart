import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'audio/audio_downloads.dart';
import 'audio/just_audio_engine.dart';
import 'audio/playback_controller.dart';
import 'db/app_database.dart';
import 'location/location_service.dart';
import 'repositories/adhkar_practice_repository.dart';
import 'repositories/adhkar_repository.dart';
import 'repositories/adhan_settings_repository.dart';
import 'repositories/adhkar_reminder_repository.dart';
import 'repositories/prayer_log_repository.dart';
import 'repositories/quran_reader_repository.dart';
import 'repositories/quran_repository.dart';
import 'seed/adhkar_seeder.dart';
import 'seed/quran_seeder.dart';
import 'settings_store.dart';
import 'worship/adhan_scheduler.dart';
import 'worship/prayer_notification_service.dart';
import 'widgets/prayer_widget_publisher.dart';
import 'widgets/widget_bridge.dart';
import 'worship/prayer_settings.dart';

/// Loads the bundled Quran and adhkar assets into the local database.
///
/// A content version in the settings table gates the work: matching version and
/// complete row counts skip the asset reads entirely. Bumping [contentVersion]
/// (or a partial content set) replaces both collections atomically.
abstract final class ContentBootstrap {
  static const quranAsset = 'assets/data/quran.json';
  static const adhkarAsset = 'assets/data/adhkar.json';
  static const versionKey = 'content_version';

  /// Bump whenever the bundled assets change.
  static const contentVersion = 1;

  static Future<void> seed(
    AppDatabase db,
    AssetBundle bundle, {
    int version = contentVersion,
  }) async {
    if (await _isCurrent(db, version)) return;

    final quranJson = await bundle.loadString(quranAsset);
    final adhkarJson = await bundle.loadString(adhkarAsset);

    await db.transaction(() async {
      // Content only; bookmarks, reader position and streaks are user state
      // and intentionally survive a content refresh.
      await db.delete(db.ayahs).go();
      await db.delete(db.juzs).go();
      await db.delete(db.quranPages).go();
      await db.delete(db.surahs).go();
      await db.delete(db.adhkarItems).go();
      await db.delete(db.adhkarCategories).go();

      await QuranSeeder.seedInto(db, quranJson);
      await AdhkarSeeder.seedInto(db, adhkarJson);
      await SettingsStore.write(db, versionKey, '$version');
    });
  }

  static Future<bool> _isCurrent(AppDatabase db, int version) async {
    if (await SettingsStore.readInt(db, versionKey) != version) return false;
    final row = await db.customSelect('''
      SELECT
        (SELECT COUNT(*) FROM surahs) AS surahs,
        (SELECT COUNT(*) FROM ayahs) AS ayahs,
        (SELECT COUNT(*) FROM juzs) AS juzs,
        (SELECT COUNT(*) FROM quran_pages) AS pages,
        (SELECT COUNT(*) FROM adhkar_categories) AS categories,
        (SELECT COUNT(*) FROM adhkar_items) AS items
    ''').getSingle();
    return row.read<int>('surahs') == 114 &&
        row.read<int>('ayahs') == 6236 &&
        row.read<int>('juzs') == 30 &&
        row.read<int>('pages') == 604 &&
        row.read<int>('categories') == 126 &&
        row.read<int>('items') == 302;
  }
}

/// Long-lived offline services created once at startup.
class AppServices {
  AppServices._(
    this.database,
    this.quran,
    this.quranReader,
    this.adhkar,
    this.adhkarPractice,
    this.prayerLog,
    this.prayerSettingsRepository,
    this.prayerSettings,
    this.themeMode,
    this.locale,
    this.location,
    this.adhanSettings,
    this.adhkarReminders,
    this.notifications,
    this.widgets,
    this.downloads,
    this.defaultReciterId,
  );

  static const themeKey = 'ui.theme';
  static const localeKey = 'ui.locale';
  static const defaultReciterKey = 'audio.defaultReciter';

  final AppDatabase database;
  final QuranRepository quran;
  final QuranReaderRepository quranReader;
  final AdhkarRepository adhkar;
  final AdhkarPracticeRepository adhkarPractice;
  final PrayerLogRepository prayerLog;
  final PrayerSettingsRepository prayerSettingsRepository;
  final ValueNotifier<PrayerSettings> prayerSettings;
  final ValueNotifier<ThemeMode> themeMode;
  final ValueNotifier<Locale> locale;
  final LocationService location;
  final AdhanSettingsRepository adhanSettings;
  final AdhkarReminderRepository adhkarReminders;
  final PrayerNotificationService notifications;
  final PrayerWidgetPublisher widgets;
  final AudioDownloadManager downloads;
  String? defaultReciterId;
  PlaybackController? _playback;

  AdhanScheduler get adhanScheduler => AdhanScheduler(
    preferences: adhanSettings,
    settings: prayerSettings,
    service: notifications,
    adhkarPreferences: adhkarReminders,
  );

  PlaybackController get playback =>
      _playback ??= PlaybackController(JustAudioEngine());

  static ThemeMode themeModeFrom(String? raw) =>
      raw == 'light' ? ThemeMode.light : ThemeMode.dark;

  static Locale localeFrom(String? raw) =>
      raw == 'en' ? const Locale('en') : const Locale('ar');

  static AppServices? _current;

  static AppServices get current {
    final services = _current;
    if (services == null) {
      throw StateError('AppServices.initialize() has not completed');
    }
    return services;
  }

  static Future<AppServices> initialize({
    AssetBundle? bundle,
    AppDatabase? database,
    LocationService? location,
    PlaybackController? playback,
    PrayerNotificationService? notifications,
    WidgetBridge? widgetBridge,
    AudioDownloadManager? downloads,
  }) async {
    final db = database ?? await AppDatabase.open();
    try {
      await ContentBootstrap.seed(db, bundle ?? rootBundle);
      final settingsRepository = PrayerSettingsRepository(db);
      final settings = await settingsRepository.load();
      final theme = themeModeFrom(await SettingsStore.read(db, themeKey));
      final locale = localeFrom(await SettingsStore.read(db, localeKey));
      final prayerLog = DriftPrayerLogRepository(db);
      final prayerSettings = ValueNotifier(settings);
      final services = AppServices._(
        db,
        DriftQuranRepository(db),
        DriftQuranReaderRepository(db),
        DriftAdhkarRepository(db),
        DriftAdhkarPracticeRepository(db),
        prayerLog,
        settingsRepository,
        prayerSettings,
        ValueNotifier(theme),
        ValueNotifier(locale),
        location ?? LocationService(),
        AdhanSettingsRepository(db),
        AdhkarReminderRepository(db),
        notifications ?? LocalPrayerNotificationService(),
        PrayerWidgetPublisher(
          settings: prayerSettings,
          log: prayerLog,
          bridge: widgetBridge ?? const HomeWidgetBridge(),
        ),
        downloads ?? await _defaultDownloads(),
        await SettingsStore.read(db, defaultReciterKey),
      );
      _current = services;
      services._playback = playback;
      return services;
    } catch (_) {
      await db.close();
      rethrow;
    }
  }

  static Future<AudioDownloadManager> _defaultDownloads() async {
    try {
      return AudioDownloadManager(await AudioDownloadStore.forApp());
    } catch (_) {
      // Tests and desktop runs have no path_provider; a temp folder keeps
      // the download manager usable without affecting the app data.
      return AudioDownloadManager(
        AudioDownloadStore(
          root: Directory('${Directory.systemTemp.path}/sakeenah_audio'),
        ),
      );
    }
  }

  Future<void> updatePrayerSettings(PrayerSettings settings) async {
    await prayerSettingsRepository.save(settings);
    prayerSettings.value = settings.sanitized();
  }

  Future<void> setDefaultReciter(String reciterId) async {
    defaultReciterId = reciterId;
    await SettingsStore.write(database, defaultReciterKey, reciterId);
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await SettingsStore.write(
      database,
      themeKey,
      mode == ThemeMode.light ? 'light' : 'dark',
    );
  }

  Future<void> setLocale(Locale next) async {
    final languageCode = next.languageCode == 'en' ? 'en' : 'ar';
    final normalized = Locale(languageCode);
    await SettingsStore.write(database, localeKey, languageCode);
    locale.value = normalized;
  }

  static Future<void> shutdown() async {
    final services = _current;
    _current = null;
    services?.prayerSettings.dispose();
    services?.themeMode.dispose();
    services?.locale.dispose();
    services?._playback?.dispose();
    await services?.database.close();
  }
}
