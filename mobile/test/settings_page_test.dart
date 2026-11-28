import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakeenah_mobile/data/app_services.dart';
import 'package:sakeenah_mobile/data/db/app_database.dart';
import 'package:sakeenah_mobile/data/location/device_location.dart';
import 'package:sakeenah_mobile/data/location/location_service.dart';
import 'package:sakeenah_mobile/data/models/adhan.dart';
import 'package:sakeenah_mobile/data/repositories/adhan_settings_repository.dart';
import 'package:sakeenah_mobile/data/worship/adhan_scheduler.dart';
import 'package:sakeenah_mobile/data/worship/prayer_times_service.dart';
import 'package:sakeenah_mobile/features/settings/settings_page.dart';
import 'package:sakeenah_mobile/l10n/app_localizations.dart';
import 'package:sakeenah_mobile/theme/sakeenah_theme.dart';

import 'support/fake_notification_service.dart';

import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;

void main() {
  setUpAll(() async {
    await AppServices.initialize(
      database: AppDatabase.memory(),
      bundle: _FileAssetBundle(),
    );
  });

  tearDownAll(AppServices.shutdown);

  testWidgets('theme segment invokes the callback', (tester) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final modes = <ThemeMode>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        theme: SakeenahTheme.light(),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: SettingsPage(
          themeMode: ThemeMode.dark,
          onThemeChanged: modes.add,
          location: AppServices.current.location,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await tester.pump(const Duration(milliseconds: 200));

    expect(modes, [ThemeMode.light]);
  });

  testWidgets('saves manual coordinates and calculation settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 3400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final notifications = FakeNotificationService();
    final scheduler = AdhanScheduler(
      preferences: AdhanSettingsRepository(AppServices.current.database),
      settings: AppServices.current.prayerSettings,
      service: notifications,
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        theme: SakeenahTheme.light(),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: SettingsPage(
          themeMode: ThemeMode.dark,
          onThemeChanged: (_) {},
          location: AppServices.current.location,
          adhanScheduler: scheduler,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    await tester.enterText(find.byType(TextField).at(0), '30.0444');
    await tester.enterText(find.byType(TextField).at(1), '31.2357');
    await tester.tap(find.text('حفظ'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final saved = AppServices.current.prayerSettings.value;
    expect(saved.latitude, 30.0444);
    expect(saved.longitude, 31.2357);
    expect(saved.configured, isTrue);
    expect(saved.locationSource, 'manual');
    expect(find.text('تم حفظ الإعدادات'), findsOneWidget);
    // Changing the city/timezone must move the scheduled adhan plan too.
    expect(notifications.events, isNotEmpty);
  });

  testWidgets('uses and saves the current device location', (tester) async {
    tester.view.physicalSize = const Size(1000, 3400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: SettingsPage(
          themeMode: ThemeMode.dark,
          onThemeChanged: (_) {},
          location: _FakeLocationService(
            const LocationResult.success(
              DeviceLocation(
                latitude: 31.9539,
                longitude: 35.9106,
                timezone: 'Asia/Amman',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('استخدم موقعي الحالي'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('موقع الجهاز'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).at(0)).controller?.text,
      '31.9539',
    );

    await tester.tap(find.text('حفظ'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final saved = AppServices.current.prayerSettings.value;
    expect(saved.locationSource, 'device');
    expect(saved.timezone, 'Asia/Amman');
    expect(saved.cityId, isNull);
  });
  testWidgets('opens the sources and licences page', (tester) async {
    tester.view.physicalSize = const Size(1000, 4600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        theme: SakeenahTheme.light(),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: SettingsPage(
          themeMode: ThemeMode.dark,
          onThemeChanged: (_) {},
          location: AppServices.current.location,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final credits = find.byKey(const ValueKey('settings-credits'));
    await tester.ensureVisible(credits);
    await tester.pump();
    await tester.tap(credits);
    await tester.pumpAndSettle();

    expect(find.text('المصادر والتراخيص'), findsWidgets);
    expect(find.text('مشروع تنزيل (Tanzil)'), findsOneWidget);
    expect(find.text('CC BY 3.0 — © Tanzil Project'), findsOneWidget);
    expect(find.text('تسجيلات الأذان'), findsOneWidget);
    expect(find.text('CC0 1.0 وملكية عامة'), findsOneWidget);
    final license = tester.widget<Text>(find.text('CC0 1.0 وملكية عامة'));
    expect(
      license.style?.color,
      SakeenahTheme.light().colorScheme.onSecondaryContainer,
    );
  });

  testWidgets('adhan toggles save and test notification fires', (tester) async {
    tester.view.physicalSize = const Size(1000, 4600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final notifications = FakeNotificationService();
    final repo = AdhanSettingsRepository(AppServices.current.database);
    await repo.save(AdhanPreferences.defaults());
    final scheduler = AdhanScheduler(
      preferences: repo,
      settings: AppServices.current.prayerSettings,
      service: notifications,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: SettingsPage(
          themeMode: ThemeMode.dark,
          onThemeChanged: (_) {},
          location: AppServices.current.location,
          adhanScheduler: scheduler,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('الأذان والتنبيهات'), findsOneWidget);
    expect(find.text('لضمان وصول الأذان في وقته'), findsOneWidget);
    await tester.tap(find.widgetWithText(SwitchListTile, 'الفجر'));
    await tester.pump(const Duration(milliseconds: 300));

    final saved = await repo.load();
    expect(saved.isEnabled(PrayerName.fajr), isFalse);
    expect(notifications.cancelled, greaterThan(0));

    // Pre-alert offsets are per prayer.
    await tester.tap(find.byKey(const ValueKey('adhan-pre-dhuhr-10')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('قبلها بـ 20 دقيقة').last);
    await tester.pumpAndSettle();

    final alerts = await repo.load();
    expect(alerts.preAlertFor(PrayerName.dhuhr), 20);
    expect(alerts.preAlertFor(PrayerName.fajr), 10);
    expect(alerts.preAlertFor(PrayerName.asr), 10);

    // The adhan recording is a saved preference and reaches the test sound.
    await tester.tap(find.byKey(const ValueKey('adhan-sound-beautiful')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أذان صباح فخري (ملك عام)').last);
    await tester.pumpAndSettle();
    expect((await repo.load()).soundId, 'sabah');

    await tester.tap(find.text('إرسال إشعار تجريبي'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(notifications.testShown, 1);
    expect(notifications.lastTestSoundId, 'sabah');
  });

  testWidgets('denied notification permission is reported', (tester) async {
    tester.view.physicalSize = const Size(1000, 4600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final notifications = FakeNotificationService()..grantPermissions = false;
    final scheduler = AdhanScheduler(
      preferences: AdhanSettingsRepository(AppServices.current.database),
      settings: AppServices.current.prayerSettings,
      service: notifications,
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: SettingsPage(
          themeMode: ThemeMode.dark,
          onThemeChanged: (_) {},
          location: AppServices.current.location,
          adhanScheduler: scheduler,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('تفعيل إشعارات الصلاة'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('لم يتم منح إذن الإشعارات.'), findsOneWidget);
    expect(notifications.events, isEmpty);
  });
}

class _FakeLocationService implements LocationService {
  _FakeLocationService(this.result);

  final LocationResult result;

  @override
  Future<LocationResult> currentLocation() async => result;

  @override
  Future<void> openAppSettings() async {}
}

class _FileAssetBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(bytes);
  }
}
