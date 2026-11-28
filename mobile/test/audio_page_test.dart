import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakeenah_mobile/data/app_services.dart';
import 'package:sakeenah_mobile/data/audio/anasheed_catalog.dart';
import 'package:sakeenah_mobile/data/audio/playback_controller.dart';
import 'package:sakeenah_mobile/data/db/app_database.dart';
import 'package:sakeenah_mobile/data/models/audio.dart';
import 'package:sakeenah_mobile/data/worship/prayer_settings.dart';
import 'package:sakeenah_mobile/features/audio/audio_page.dart';
import 'package:sakeenah_mobile/features/audio/mini_player.dart';
import 'package:sakeenah_mobile/features/audio/player_page.dart';
import 'package:sakeenah_mobile/l10n/app_localizations.dart';
import 'package:sakeenah_mobile/theme/sakeenah_theme.dart';

import 'support/fake_audio_engine.dart';

void main() {
  late FakeAudioEngine engine;
  late PlaybackController playback;

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

  setUp(() {
    engine = FakeAudioEngine();
    playback = PlaybackController(engine);
  });

  tearDown(() => playback.dispose());

  Future<void> pump(WidgetTester tester, Widget child) async {
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
        home: Scaffold(body: child),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
  }

  List<AudioTrack> tracks() => [
    for (var ayah = 1; ayah <= 7; ayah++)
      AudioTrack(
        id: 'test:00100$ayah',
        reciterId: 'Alafasy_128kbps',
        reciterName: 'مشاري العفاسي',
        surah: 1,
        ayah: ayah,
        surahName: 'الفاتحة',
        url: 'https://example.test/00100$ayah.mp3',
      ),
  ];

  testWidgets('audio page lists reciters and plays a surah', (tester) async {
    await pump(tester, AudioPage(playback: playback));

    expect(find.text('اختر القارئ'), findsOneWidget);
    expect(find.textContaining('مشاري العفاسي'), findsWidgets);
    expect(find.byKey(const ValueKey('audio-play-1')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('audio-play-1')));
    await tester.pumpAndSettle();

    expect(playback.current?.surah, 1);
    expect(playback.queue, hasLength(7));
    expect(playback.playing, isTrue);
  });

  testWidgets('selected audio mode uses the emerald soft active surface', (
    tester,
  ) async {
    await pump(tester, AudioPage(playback: playback));

    final finder = find.byKey(const ValueKey('audio-mode-quran'));
    final chip = tester.widget<ChoiceChip>(finder);
    final scheme = Theme.of(tester.element(finder)).colorScheme;
    final label = chip.label as Text;

    expect(chip.selected, isTrue);
    expect(chip.selectedColor, scheme.primaryContainer);
    expect(label.style?.color, scheme.onPrimaryContainer);
    expect(tester.takeException(), isNull);
  });

  testWidgets('player controls speed, repeat and play/pause', (tester) async {
    await playback.playQueue(tracks());
    await pump(tester, PlayerPage(playback: playback));

    expect(find.text('الفاتحة'), findsWidgets);
    expect(find.textContaining('مشاري العفاسي'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('audio-toggle')));
    await tester.pumpAndSettle();
    expect(playback.playing, isFalse);

    await tester.tap(find.byKey(const ValueKey('audio-speed')));
    await tester.pumpAndSettle();
    expect(playback.speed, 1.25);

    await tester.tap(find.byKey(const ValueKey('audio-repeat')));
    await tester.pumpAndSettle();
    expect(playback.repeat, AudioRepeatMode.one);
  });

  testWidgets('primary transport uses emerald, not gold', (tester) async {
    await playback.playQueue(tracks());
    await pump(tester, PlayerPage(playback: playback));

    final finder = find.byKey(const ValueKey('audio-toggle'));
    final toggle = tester.widget<IconButton>(finder);
    final scheme = Theme.of(tester.element(finder)).colorScheme;

    expect(toggle.style?.backgroundColor?.resolve({}), scheme.primary);
    expect(toggle.style?.foregroundColor?.resolve({}), scheme.onPrimary);
  });

  testWidgets('unknown duration disables seek and shows a placeholder', (
    tester,
  ) async {
    await playback.playQueue(tracks());
    await pump(tester, PlayerPage(playback: playback));

    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('audio-seek')),
    );
    expect(slider.onChanged, isNull);
    expect(find.text('--:--'), findsOneWidget);

    engine.emit(
      engine.current.copyWith(
        duration: const Duration(seconds: 10),
        position: const Duration(seconds: 2),
      ),
    );
    await tester.pumpAndSettle();

    final ready = tester.widget<Slider>(
      find.byKey(const ValueKey('audio-seek')),
    );
    expect(ready.onChanged, isNotNull);
    expect(find.text('0:10'), findsOneWidget);
  });

  testWidgets('live radio player hides seeking and skipping', (tester) async {
    await playback.playQueue([
      const AudioTrack(
        id: 'radio:quran_kuwait',
        reciterId: 'radio',
        reciterName: 'الكويت',
        surah: 0,
        ayah: 1,
        surahName: 'إذاعة القرآن الكريم — الكويت',
        url: 'https://example.test/radio.mp3',
        subtitleOverride: 'بث مباشر',
      ),
    ]);
    await pump(tester, PlayerPage(playback: playback));

    expect(find.text('مباشر'), findsOneWidget);
    expect(find.byKey(const ValueKey('audio-seek')), findsNothing);
    expect(find.byIcon(Icons.skip_next_rounded), findsNothing);
    expect(find.byIcon(Icons.skip_previous_rounded), findsNothing);
    expect(find.byKey(const ValueKey('audio-toggle')), findsOneWidget);
    expect(find.byIcon(Icons.radio_rounded), findsWidgets);
  });

  testWidgets('radio tab lists curated stations and plays one', (tester) async {
    await pump(tester, AudioPage(playback: playback));

    await tester.ensureVisible(find.text('الإذاعات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإذاعات'));
    await tester.pumpAndSettle();

    expect(find.text('إذاعة القرآن الكريم — الكويت'), findsOneWidget);
    expect(find.text('إذاعة القرآن الكريم — الشارقة'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('radio-play-quran_kuwait')));
    await tester.pumpAndSettle();

    expect(playback.current?.reciterId, 'radio');
    expect(playback.queue, hasLength(1));
    expect(playback.playing, isTrue);
  });

  testWidgets('mini player stays hidden until something plays', (tester) async {
    await pump(tester, MiniPlayer(playback: playback));
    expect(find.text('الفاتحة'), findsNothing);

    await playback.playQueue(tracks());
    await tester.pumpAndSettle();
    expect(find.text('الفاتحة'), findsOneWidget);
    expect(find.byKey(const ValueKey('mini-toggle')), findsOneWidget);
  });

  testWidgets('mini player uses the elevated surface layer', (tester) async {
    await playback.playQueue(tracks());
    await pump(tester, MiniPlayer(playback: playback));

    final surface = tester.widget<Material>(
      find.byKey(const ValueKey('mini-player-surface')),
    );
    expect(surface.color, SakeenahTheme.dark().colorScheme.surface);
  });

  testWidgets('player surfaces a playback error and retries', (tester) async {
    await playback.playQueue(tracks());
    await pump(tester, PlayerPage(playback: playback));

    engine.emit(
      engine.current.copyWith(playing: false, error: 'connection closed'),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('تعذر تشغيل التلاوة. تحقق من اتصالك بالإنترنت.'),
      findsOneWidget,
    );
    final before = engine.playCalls;
    await tester.tap(find.byKey(const ValueKey('audio-retry')));
    await tester.pumpAndSettle();
    expect(engine.playCalls, before + 1);
  });

  testWidgets('mini player flags a playback error', (tester) async {
    await playback.playQueue(tracks());
    await pump(tester, MiniPlayer(playback: playback));
    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);

    engine.emit(engine.current.copyWith(error: 'connection closed'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });

  testWidgets('stopping from the mini player dismisses it', (tester) async {
    await playback.playQueue(tracks());
    await pump(tester, MiniPlayer(playback: playback));
    expect(find.byKey(const ValueKey('mini-toggle')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('mini-toggle')), findsNothing);
    expect(playback.current, isNull);
    expect(playback.queue, isEmpty);
  });

  testWidgets('retry re-applies the queue after a failed load', (tester) async {
    await playback.playQueue(tracks());
    engine.emit(engine.current.copyWith(error: 'load failed'));
    final before = engine.playCalls;

    await playback.retry();
    await tester.pumpAndSettle();

    expect(engine.playCalls, before + 1);
    expect(playback.current?.surah, 1);
    expect(playback.queue, hasLength(7));
  });

  testWidgets('anasheed tab lists and plays a licensed result', (tester) async {
    await pump(
      tester,
      AudioPage(playback: playback, anasheed: _FakeAnasheed()),
    );

    await tester.tap(find.text('الأناشيد'));
    await tester.pumpAndSettle();

    expect(find.text('نشيد تجريبي'), findsOneWidget);
    expect(find.textContaining('CC BY 3.0'), findsOneWidget);
    expect(find.textContaining('Openverse'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('anasheed-play-1')));
    await tester.pumpAndSettle();

    expect(playback.current?.surahName, 'نشيد تجريبي');
    expect(playback.current?.url, 'https://example.test/nasheed.mp3');
  });
}

class _FakeAnasheed implements AnasheedSource {
  @override
  Future<List<AnasheedTrack>> search(String query) async => const [
    AnasheedTrack(
      id: '1',
      title: 'نشيد تجريبي',
      creator: 'فنان',
      license: 'by',
      licenseVersion: '3.0',
      audioUrl: 'https://example.test/nasheed.mp3',
      landingUrl: 'https://example.test/source',
      source: 'wikimedia_audio',
      duration: Duration(minutes: 1),
    ),
  ];
}

class _FileAssetBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(bytes);
  }
}
