import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakeenah_mobile/data/app_services.dart';
import 'package:sakeenah_mobile/data/db/app_database.dart';
import 'package:sakeenah_mobile/data/worship/prayer_settings.dart';
import 'package:sakeenah_mobile/features/quran/quran_page.dart';
import 'package:sakeenah_mobile/l10n/app_localizations.dart';
import 'package:sakeenah_mobile/theme/sakeenah_theme.dart';

void main() {
  setUpAll(() async {
    await AppServices.initialize(
      database: AppDatabase.memory(),
      bundle: _FileAssetBundle(),
    );
    await AppServices.current.updatePrayerSettings(
      PrayerSettings.defaults().copyWith(configured: true),
    );
  });

  tearDownAll(AppServices.shutdown);

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
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
        theme: SakeenahTheme.dark(),
        home: const Scaffold(body: MushafPage()),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
  }

  testWidgets('catalog shows surahs, juz, bookmarks and resume tabs', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('السور'), findsOneWidget);
    expect(find.text('الأجزاء'), findsOneWidget);
    expect(find.text('العلامات'), findsOneWidget);
    expect(find.text('المتابعة'), findsOneWidget);
    expect(find.text('البقرة'), findsWidgets);
    expect(find.text('الفاتحة'), findsWidgets);
  });

  testWidgets('search filters the surah list', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byType(TextField).first, 'الكهف');
    await tester.pumpAndSettle();

    expect(find.text('الكهف'), findsWidgets);
    expect(find.text('البقرة'), findsNothing);
  });

  testWidgets('juz tab lists all thirty parts', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('الأجزاء'));
    await tester.pumpAndSettle();

    expect(find.text('الجزء 1'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('juz-list')),
      const Offset(0, -3000),
    );
    await tester.pumpAndSettle();
    expect(find.text('الجزء 30'), findsOneWidget);
  });

  testWidgets('empty bookmarks and resume states are explained', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.text('العلامات'));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد علامات بعد'), findsOneWidget);

    await tester.tap(find.text('المتابعة'));
    await tester.pumpAndSettle();
    expect(find.text('لم تبدأ القراءة بعد'), findsOneWidget);
    expect(find.text('آية اليوم'), findsOneWidget);
    final dailyAyah = tester.widget<InkWell>(
      find.byKey(const ValueKey('quran-daily-ayah-card')),
    );
    expect(dailyAyah.borderRadius, BorderRadius.circular(16));
  });
}

class _FileAssetBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(bytes);
  }
}
