import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:sakeenah_mobile/app.dart';
import 'package:sakeenah_mobile/data/app_services.dart';
import 'package:sakeenah_mobile/data/audio/playback_controller.dart';
import 'package:sakeenah_mobile/data/db/app_database.dart';
import 'package:sakeenah_mobile/data/settings_store.dart';
import 'package:sakeenah_mobile/data/worship/prayer_settings.dart';
import 'package:sakeenah_mobile/features/settings/settings_page.dart';

import 'support/fake_audio_engine.dart';

void main() {
  setUpAll(() async {
    await AppServices.initialize(
      database: AppDatabase.memory(),
      bundle: _FileAssetBundle(),
      playback: PlaybackController(FakeAudioEngine()),
    );
    await AppServices.current.updatePrayerSettings(
      PrayerSettings.defaults().copyWith(configured: true),
    );
  });

  tearDownAll(AppServices.shutdown);

  Future<void> pumpUi(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('shell shows the four destinations', (tester) async {
    await tester.pumpWidget(const SakeenahApp());
    await pumpUi(tester);

    expect(find.text('سَكينة'), findsWidgets);
    expect(find.text('الرئيسية'), findsWidgets);
    expect(find.text('المصحف'), findsWidgets);
    expect(find.text('الأذكار'), findsWidgets);
    expect(find.text('الصوت'), findsWidgets);
  });

  testWidgets('tapping the Mushaf tab opens the Quran page', (tester) async {
    await tester.pumpWidget(const SakeenahApp());
    await pumpUi(tester);

    await tester.tap(find.text('المصحف').last);
    await pumpUi(tester);

    expect(find.text('السور'), findsOneWidget);
    expect(find.text('الفاتحة'), findsWidgets);
  });

  testWidgets(
    'language switch defaults invalid locale to Arabic and persists English',
    (tester) async {
      const homeWidgetUpdates = MethodChannel('home_widget/updates');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(homeWidgetUpdates, (_) async => null);
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(homeWidgetUpdates, null),
      );

      Directory? directory;
      var baselineRestored = false;

      Future<AppServices> restoreBaseline() async {
        final baseline = (await tester.runAsync(
          () => AppServices.initialize(
            database: AppDatabase.memory(),
            bundle: _FileAssetBundle(),
            playback: PlaybackController(FakeAudioEngine()),
          ),
        ))!;
        await tester.runAsync(
          () => baseline.updatePrayerSettings(
            PrayerSettings.defaults().copyWith(configured: true),
          ),
        );
        return baseline;
      }

      addTearDown(() async {
        if (baselineRestored) return;
        await tester.pumpWidget(const SizedBox.shrink());
        await AppServices.shutdown();
        final tempDirectory = directory;
        if (tempDirectory != null && tempDirectory.existsSync()) {
          await tester.runAsync(() => tempDirectory.delete(recursive: true));
        }
        await restoreBaseline();
      });

      await AppServices.shutdown();
      directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('sakeenah_locale_test'),
      ))!;
      final databaseFile = File(
        '${directory.path}${Platform.pathSeparator}app.sqlite',
      );

      await tester.runAsync(() async {
        final seeded = AppDatabase(NativeDatabase(databaseFile));
        await SettingsStore.write(seeded, 'ui.locale', 'fr');
        await seeded.close();
      });

      Future<AppServices> initialize() => AppServices.initialize(
        database: AppDatabase(NativeDatabase(databaseFile)),
        bundle: _FileAssetBundle(),
        playback: PlaybackController(FakeAudioEngine()),
      );

      var services = (await tester.runAsync(initialize))!;
      await tester.runAsync(
        () => services.updatePrayerSettings(
          PrayerSettings.defaults().copyWith(configured: true),
        ),
      );
      await tester.pumpWidget(const SakeenahApp());
      await pumpUi(tester);

      expect(find.text('الرئيسية'), findsWidgets);
      expect(
        Directionality.of(tester.element(find.text('الرئيسية').last)),
        TextDirection.rtl,
      );
      expect(find.byKey(const ValueKey('language-toggle')), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('language-toggle')));
      await pumpUi(tester);
      expect(find.text('Home'), findsWidgets);
      expect(
        Directionality.of(tester.element(find.text('Home').last)),
        TextDirection.ltr,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      expect(await SettingsStore.read(services.database, 'ui.locale'), 'en');

      await tester.pumpWidget(const SizedBox.shrink());
      await AppServices.shutdown();
      services = (await tester.runAsync(initialize))!;
      await tester.runAsync(
        () => services.updatePrayerSettings(
          PrayerSettings.defaults().copyWith(configured: true),
        ),
      );
      await tester.pumpWidget(const SakeenahApp());
      await pumpUi(tester);

      expect(find.text('Home'), findsWidgets);
      expect(
        Directionality.of(tester.element(find.text('Home').last)),
        TextDirection.ltr,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await AppServices.shutdown();
      await tester.runAsync(() => directory!.delete(recursive: true));
      await restoreBaseline();
      baselineRestored = true;
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  testWidgets('settings opens and switches the theme', (tester) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const SakeenahApp());
    await pumpUi(tester);

    await tester.tap(find.byTooltip('الإعدادات'));
    await pumpUi(tester);
    expect(find.text('الإعدادات'), findsWidgets);

    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await pumpUi(tester);

    final context = tester.element(find.byType(SettingsPage));
    expect(Theme.of(context).brightness, Brightness.light);
    expect(AppServices.current.themeMode.value, ThemeMode.light);
    expect(
      await SettingsStore.read(
        AppServices.current.database,
        AppServices.themeKey,
      ),
      'light',
    );
  });
}

class _FileAssetBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(bytes);
  }
}
