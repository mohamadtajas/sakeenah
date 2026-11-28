import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakeenah_mobile/app.dart';
import 'package:sakeenah_mobile/data/app_services.dart';
import 'package:sakeenah_mobile/data/audio/playback_controller.dart';
import 'package:sakeenah_mobile/data/db/app_database.dart';
import 'package:sakeenah_mobile/data/models/audio.dart';
import 'package:sakeenah_mobile/data/repositories/adhan_settings_repository.dart';
import 'package:sakeenah_mobile/data/worship/adhan_scheduler.dart';
import 'package:sakeenah_mobile/data/worship/prayer_settings.dart';
import 'package:sakeenah_mobile/features/adhkar/adhkar_category_page.dart';
import 'package:sakeenah_mobile/features/adhkar/adhkar_page.dart';
import 'package:sakeenah_mobile/features/audio/audio_page.dart';
import 'package:sakeenah_mobile/features/dashboard/dashboard_page.dart';
import 'package:sakeenah_mobile/features/audio/mini_player.dart';
import 'package:sakeenah_mobile/features/audio/player_page.dart';
import 'package:sakeenah_mobile/features/quran/quran_page.dart';
import 'package:sakeenah_mobile/features/quran/quran_reader_page.dart';
import 'package:sakeenah_mobile/features/settings/credits_page.dart';
import 'package:sakeenah_mobile/features/settings/settings_page.dart';
import 'package:sakeenah_mobile/l10n/app_localizations.dart';
import 'package:sakeenah_mobile/theme/sakeenah_theme.dart';
import 'package:sakeenah_mobile/widgets/qibla_dial.dart';

import 'support/fake_audio_engine.dart';
import 'support/fake_notification_service.dart';

void main() {
  late FakeAudioEngine engine;
  late PlaybackController playback;

  setUpAll(() async {
    engine = FakeAudioEngine();
    playback = PlaybackController(engine);
    await AppServices.initialize(
      database: AppDatabase.memory(),
      bundle: _FileAssetBundle(),
      playback: playback,
      notifications: FakeNotificationService(),
    );
    await AppServices.current.updatePrayerSettings(
      PrayerSettings.defaults().copyWith(configured: true),
    );
  });

  tearDownAll(AppServices.shutdown);

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(320, 640),
    Locale locale = const Locale('ar'),
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, widget) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: widget!,
        ),
        theme: theme ?? SakeenahTheme.dark(),
        home: child,
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
  }

  testWidgets('dashboard fits a small phone at 2x text', (tester) async {
    await pump(
      tester,
      Scaffold(
        body: DashboardPage(
          onSelectTab: (_) {},
          clock: () => DateTime.utc(2026, 11, 26, 3),
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'mobile worship and Quran surfaces keep the sanctuary radii and text contrast',
    (tester) async {
      await pump(
        tester,
        Scaffold(
          body: DashboardPage(
            onSelectTab: (_) {},
            clock: () => DateTime.utc(2026, 11, 26, 3),
          ),
        ),
        theme: SakeenahTheme.light(),
      );
      final prayerHero = tester.widget<Container>(
        find.byKey(const ValueKey('dashboard-prayer-hero')),
      );
      expect(
        (prayerHero.decoration! as BoxDecoration).borderRadius,
        BorderRadius.circular(16),
      );
      expect(tester.takeException(), isNull);

      await pump(
        tester,
        Scaffold(body: AdhkarPage(clock: () => DateTime.utc(2026, 11, 26, 9))),
        theme: SakeenahTheme.light(),
      );
      final streakHeader = tester.widget<Container>(
        find.byKey(const ValueKey('adhkar-streak-header')),
      );
      expect(
        (streakHeader.decoration! as BoxDecoration).borderRadius,
        BorderRadius.circular(16),
      );
      final today = tester.widget<Text>(find.text('أذكار اليوم'));
      expect(
        today.style?.color,
        SakeenahTheme.light().colorScheme.onSecondaryContainer,
      );
      expect(tester.takeException(), isNull);

      await pump(
        tester,
        const QuranReaderPage.surah(surah: 1),
        theme: SakeenahTheme.light(),
      );
      final firstAyah = tester.widget<InkWell>(
        find.byKey(const ValueKey('quran-ayah-1-1')),
      );
      expect(firstAyah.borderRadius, BorderRadius.circular(12));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dashboard, Mushaf and adhkar fit 320x640 at 2x in Arabic and English themes',
    (tester) async {
      for (final locale in const [Locale('ar'), Locale('en')]) {
        for (final theme in [SakeenahTheme.light(), SakeenahTheme.dark()]) {
          await pump(
            tester,
            Scaffold(
              body: DashboardPage(
                onSelectTab: (_) {},
                clock: () => DateTime.utc(2026, 11, 26, 3),
              ),
            ),
            locale: locale,
            theme: theme,
          );
          expect(tester.takeException(), isNull, reason: 'dashboard $locale');

          await pump(
            tester,
            const Scaffold(body: MushafPage()),
            locale: locale,
            theme: theme,
          );
          expect(tester.takeException(), isNull, reason: 'Mushaf $locale');

          await pump(
            tester,
            Scaffold(
              body: AdhkarPage(clock: () => DateTime.utc(2026, 11, 26, 9)),
            ),
            locale: locale,
            theme: theme,
          );
          expect(tester.takeException(), isNull, reason: 'adhkar $locale');
        }
      }
    },
  );

  testWidgets('adhkar catalog fits a small phone at 2x text', (tester) async {
    await pump(
      tester,
      Scaffold(body: AdhkarPage(clock: () => DateTime.utc(2026, 11, 26, 9))),
    );
    for (var i = 0; i < 3; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('adhkar category fits a small phone at 2x text', (tester) async {
    final categories = await AppServices.current.adhkar.categories();
    final category = categories.firstWhere(
      (item) => item.itemCount > 0,
      orElse: () => categories.first,
    );
    await pump(
      tester,
      AdhkarCategoryPage(
        category: category,
        clock: () => DateTime.utc(2026, 11, 26, 9),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('qibla dial fits at 2x text', (tester) async {
    await pump(
      tester,
      const Scaffold(body: Center(child: QiblaDial(bearing: 137))),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Quran catalog fits a small phone at 2x text', (tester) async {
    await pump(tester, const Scaffold(body: MushafPage()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Quran reader fits a small phone at 2x text', (tester) async {
    await pump(tester, const QuranReaderPage.surah(surah: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('audio catalog fits a small phone at 2x text', (tester) async {
    await pump(tester, Scaffold(body: AudioPage(playback: playback)));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'audio player and settings fit 320x640 at 2x in Arabic and English themes',
    (tester) async {
      await playback.playQueue([
        const AudioTrack(
          id: 'polish',
          reciterId: 'Alafasy_128kbps',
          reciterName: 'مشاري العفاسي',
          surah: 1,
          ayah: 1,
          surahName: 'الفاتحة',
          url: 'https://example.test/001001.mp3',
        ),
      ]);

      for (final locale in const [Locale('ar'), Locale('en')]) {
        for (final theme in [SakeenahTheme.light(), SakeenahTheme.dark()]) {
          await pump(
            tester,
            Scaffold(body: AudioPage(playback: playback)),
            locale: locale,
            theme: theme,
          );
          expect(tester.takeException(), isNull, reason: 'audio $locale');

          await pump(
            tester,
            PlayerPage(playback: playback),
            locale: locale,
            theme: theme,
          );
          expect(tester.takeException(), isNull, reason: 'player $locale');

          final scheduler = AdhanScheduler(
            preferences: AdhanSettingsRepository(AppServices.current.database),
            settings: AppServices.current.prayerSettings,
            service: FakeNotificationService(),
          );
          await pump(
            tester,
            SettingsPage(
              themeMode: theme.brightness == Brightness.dark
                  ? ThemeMode.dark
                  : ThemeMode.light,
              onThemeChanged: (_) {},
              locale: locale,
              onLocaleChanged: (_) {},
              location: AppServices.current.location,
              adhanScheduler: scheduler,
            ),
            locale: locale,
            theme: theme,
          );
          for (var index = 0; index < 8; index++) {
            await tester.drag(
              find.byType(Scrollable).first,
              const Offset(0, -300),
            );
            await tester.pump(const Duration(milliseconds: 80));
            expect(tester.takeException(), isNull, reason: 'settings $locale');
          }
        }
      }
    },
  );

  testWidgets('audio player and mini-player fit at 2x text', (tester) async {
    await playback.playQueue([
      const AudioTrack(
        id: 'test',
        reciterId: 'test',
        reciterName: 'مشاري العفاسي',
        surah: 1,
        ayah: 1,
        surahName: 'الفاتحة',
        url: 'https://example.test/001001.mp3',
      ),
    ]);
    await pump(tester, PlayerPage(playback: playback));
    expect(tester.takeException(), isNull);

    engine.emit(engine.current.copyWith(error: 'connection closed'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);

    await pump(tester, MiniPlayer(playback: playback));
    expect(tester.takeException(), isNull);
  });

  testWidgets('adhan settings fit a small phone at 2x text', (tester) async {
    final scheduler = AdhanScheduler(
      preferences: AdhanSettingsRepository(AppServices.current.database),
      settings: AppServices.current.prayerSettings,
      service: FakeNotificationService(),
    );
    await pump(
      tester,
      SettingsPage(
        themeMode: ThemeMode.dark,
        onThemeChanged: (_) {},
        location: AppServices.current.location,
        adhanScheduler: scheduler,
      ),
      size: const Size(320, 640),
    );
    for (var i = 0; i < 8; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('credits fit a small phone at 2x text', (tester) async {
    await pump(tester, const CreditsPage());
    await tester.tap(find.text('مشروع تنزيل (Tanzil)'));
    await tester.pumpAndSettle();
    final license = find.text('نص الترخيص الكامل');
    expect(license, findsOneWidget);
    await tester.ensureVisible(license);
    await tester.pump();
    await tester.tap(license);
    await tester.pumpAndSettle();
    expect(find.byType(SelectableText), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('app shell with mini-player fits at 2x text', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await playback.playQueue([
      const AudioTrack(
        id: 'shell',
        reciterId: 'test',
        reciterName: 'مشاري العفاسي',
        surah: 1,
        ayah: 1,
        surahName: 'الفاتحة',
        url: 'https://example.test/001001.mp3',
      ),
    ]);
    await tester.pumpWidget(const SakeenahApp());
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    for (final label in const ['المصحف', 'الأذكار', 'الصوت', 'الرئيسية']) {
      await tester.tap(find.text(label).last);
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      expect(tester.takeException(), isNull, reason: 'tab $label');
    }
  });
}

class _FileAssetBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(bytes);
  }
}
