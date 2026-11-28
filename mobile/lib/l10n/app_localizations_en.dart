// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sakeenah';

  @override
  String get navDashboard => 'Home';

  @override
  String get navQuran => 'Mushaf';

  @override
  String get navAdhkar => 'Adhkar';

  @override
  String get navAudio => 'Audio';

  @override
  String get settings => 'Settings';

  @override
  String get languageSection => 'Language';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get languageEnglish => 'English';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get dashboardWelcome => 'Tranquility of the heart';

  @override
  String get dashboardSubtitle =>
      'Quran, prayer times, adhkar and audio — offline.';

  @override
  String get prayerCardTitle => 'Prayer & Qibla';

  @override
  String get prayerCardBody =>
      'Prayer times calculated on your device, a prayer log and a streak.';

  @override
  String get quranCardTitle => 'Mushaf';

  @override
  String get quranCardBody =>
      'The full Uthmani text by surah or juz, with bookmarks and last position.';

  @override
  String get adhkarCardTitle => 'Adhkar';

  @override
  String get adhkarCardBody =>
      'The full Hisn al-Muslim with counters, progress and a daily streak.';

  @override
  String get audioCardTitle => 'Recitations & anasheed';

  @override
  String get audioCardBody =>
      'Background playback, playlists and downloads for offline listening.';

  @override
  String get quranPageTitle => 'Mushaf';

  @override
  String get adhkarPageTitle => 'Adhkar';

  @override
  String get audioPageTitle => 'Audio';

  @override
  String get settingsPageTitle => 'Settings';

  @override
  String get settingsOverview => 'Overview';

  @override
  String get settingsPlaceholder =>
      'Location, reminders and audio settings arrive in later phases.';

  @override
  String get dashboardTitle => 'Home';

  @override
  String get themeSection => 'Appearance';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String versionLine(String version) {
    return 'Version $version';
  }

  @override
  String get startupErrorTitle => 'Sakeenah could not start';

  @override
  String get startupErrorBody =>
      'The local data could not be prepared. Try again, and reinstall the app if the problem persists.';

  @override
  String get retry => 'Try again';

  @override
  String get prayerNext => 'Next prayer';

  @override
  String prayerTimeRemaining(String time) {
    return '$time remaining';
  }

  @override
  String get prayerToday => 'Today\'s times';

  @override
  String get prayerStreak => 'Prayer streak';

  @override
  String get prayerBestStreak => 'Best streak';

  @override
  String get prayerExcusedDay => 'Excused day';

  @override
  String get prayerMarkOnTime => 'On time';

  @override
  String get prayerMarkLate => 'Late';

  @override
  String get prayerMarkQada => 'Made up';

  @override
  String get prayerMarkMissed => 'Missed';

  @override
  String get prayerClear => 'Clear';

  @override
  String get prayerExcuse => 'Mark today excused';

  @override
  String get prayerUnExcuse => 'Remove excused day';

  @override
  String get prayerLocationMissing =>
      'Your location is not set; showing the default Makkah coordinates.';

  @override
  String get prayerOpenSettings => 'Set location';

  @override
  String get qiblaTitle => 'Qibla';

  @override
  String qiblaBearing(String degrees) {
    return 'Qibla $degrees°';
  }

  @override
  String get hijriTitle => 'Hijri date';

  @override
  String get prayerSettings => 'Prayer settings';

  @override
  String get prayerLocationSection => 'Location and times';

  @override
  String get prayerCalculationSection => 'Calculation';

  @override
  String get cityLabel => 'City';

  @override
  String get customLocation => 'Custom location';

  @override
  String get latitudeLabel => 'Latitude';

  @override
  String get longitudeLabel => 'Longitude';

  @override
  String get timezoneLabel => 'Timezone';

  @override
  String get methodLabel => 'Calculation method';

  @override
  String get madhabLabel => 'Asr madhab';

  @override
  String get shafi => 'Shafi';

  @override
  String get hanafi => 'Hanafi';

  @override
  String get highLatitudeLabel => 'High latitude rule';

  @override
  String get hijriAdjustmentLabel => 'Hijri adjustment';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get sunrise => 'Sunrise';

  @override
  String get save => 'Save';

  @override
  String get prayerInvalidCoordinates => 'Enter valid coordinates.';

  @override
  String get prayerTimesUnavailable =>
      'Prayer times are not available for this location and date. Try another location or a lower latitude.';

  @override
  String get settingsSaveFailed => 'Could not save settings. Try again.';

  @override
  String get adhkarToday => 'Today\'s adhkar';

  @override
  String get adhkarMorning => 'Morning adhkar';

  @override
  String get adhkarEvening => 'Evening adhkar';

  @override
  String get adhkarFeatured => 'Featured adhkar';

  @override
  String get adhkarAll => 'All adhkar';

  @override
  String get adhkarSearch => 'Search adhkar';

  @override
  String get adhkarNoResults => 'No results';

  @override
  String adhkarRemaining(String count) {
    return '$count remaining';
  }

  @override
  String get adhkarDone => 'Done';

  @override
  String get adhkarTapToCount => 'Tap to count';

  @override
  String get adhkarCompletedTitle => 'Adhkar completed';

  @override
  String get adhkarCompletedBody => 'Added to today\'s streak.';

  @override
  String get adhkarResetItem => 'Reset this dhikr';

  @override
  String adhkarCategoryProgress(int completed, int total) {
    return 'Progress: $completed of $total';
  }

  @override
  String get adhkarClose => 'Close';

  @override
  String get adhkarResetCategory => 'Reset section';

  @override
  String get adhkarCompletedBodyGeneric => 'This adhkar section is complete.';

  @override
  String adhkarStreakCount(int count) {
    return 'Adhkar streak: $count';
  }

  @override
  String adhkarBestCount(int count) {
    return 'Best streak: $count';
  }

  @override
  String get adhkarPrevious => 'Previous';

  @override
  String get adhkarNext => 'Next';

  @override
  String get adhkarLoadError => 'Could not load adhkar.';

  @override
  String get adhkarActionError => 'Could not save progress.';

  @override
  String get adhkarClearSearch => 'Clear search';

  @override
  String get adhkarGoHome => 'Home';

  @override
  String prayerTodayProgress(int count) {
    return 'Today: $count / 5';
  }

  @override
  String get locationTitle => 'Set location';

  @override
  String get locationBody =>
      'Your location is used on this device only to calculate prayer times and qibla. It is never sent to a server.';

  @override
  String get locationUse => 'Use my location';

  @override
  String get locationChooseCity => 'Choose a city';

  @override
  String get locationDenied =>
      'Location access was not allowed. You can choose a city manually.';

  @override
  String get locationDeniedForever =>
      'Location permission is blocked. Open the app settings to allow it.';

  @override
  String get locationUnavailable => 'Could not get your location. Try again.';

  @override
  String get locationOpenSettings => 'Open app settings';

  @override
  String get locationFetching => 'Getting your location…';

  @override
  String get locationSaved => 'Current location applied.';

  @override
  String get locationSourceDevice => 'Device location';

  @override
  String get settingsLocationUse => 'Use my current location';

  @override
  String get quranTabSurahs => 'Surahs';

  @override
  String get quranTabJuz => 'Juz';

  @override
  String get quranTabBookmarks => 'Bookmarks';

  @override
  String get quranTabResume => 'Resume';

  @override
  String get quranSearch => 'Search surahs';

  @override
  String get quranSearchEmpty => 'No matching surahs';

  @override
  String get quranNoBookmarks => 'No bookmarks yet';

  @override
  String get quranNoResume => 'You have not started reading yet';

  @override
  String get quranDailyAyah => 'Ayah of the day';

  @override
  String quranJuz(int number) {
    return 'Juz $number';
  }

  @override
  String quranAyahCount(int count) {
    return '$count ayahs';
  }

  @override
  String get quranMakkah => 'Makkan';

  @override
  String get quranMadinah => 'Madinan';

  @override
  String get quranContinue => 'Continue reading';

  @override
  String quranResumeAt(String surah, int ayah) {
    return '$surah · Ayah $ayah';
  }

  @override
  String quranBookmarkAt(String surah, int ayah) {
    return '$surah · Ayah $ayah';
  }

  @override
  String get quranRemoveBookmark => 'Remove bookmark';

  @override
  String get quranAddBookmark => 'Add bookmark';

  @override
  String get quranSajda => 'Sajda';

  @override
  String get quranReaderError => 'Could not load the Quran.';

  @override
  String get quranFontDecrease => 'Decrease font size';

  @override
  String get quranFontIncrease => 'Increase font size';

  @override
  String get quranRead => 'Read';

  @override
  String quranJuzStart(String surah, int ayah) {
    return 'Starts at $surah · $ayah';
  }

  @override
  String quranAyahLabel(int number) {
    return 'Ayah $number';
  }

  @override
  String get audioChooseReciter => 'Choose reciter';

  @override
  String get audioSearchSurah => 'Search surahs';

  @override
  String get audioPlaySurah => 'Play surah';

  @override
  String get audioNowPlaying => 'Now playing';

  @override
  String get audioPlay => 'Play';

  @override
  String get audioPause => 'Pause';

  @override
  String get audioNext => 'Next';

  @override
  String get audioPrevious => 'Previous';

  @override
  String get audioSpeed => 'Speed';

  @override
  String get audioRepeat => 'Repeat';

  @override
  String get audioRepeatOff => 'No repeat';

  @override
  String get audioRepeatOne => 'Repeat ayah';

  @override
  String get audioRepeatAll => 'Repeat surah';

  @override
  String get audioQueueEmpty => 'Nothing is playing yet';

  @override
  String get audioStop => 'Stop';

  @override
  String audioAyahLabel(int number) {
    return 'Ayah $number';
  }

  @override
  String get audioReciterLabel => 'Reciter';

  @override
  String get audioStopPlayback => 'Stop playback';

  @override
  String get adhanSection => 'Adhan and notifications';

  @override
  String get adhanEnable => 'Enable prayer notifications';

  @override
  String get adhanPreAlert => 'Pre-alert';

  @override
  String get adhanNoPreAlert => 'No pre-alert';

  @override
  String adhanMinutes(int minutes) {
    return '$minutes minutes before';
  }

  @override
  String get adhanSound => 'Adhan sound';

  @override
  String get adhanTest => 'Send a test notification';

  @override
  String get adhanTestSent => 'Test notification sent.';

  @override
  String get adhanPermissionDenied =>
      'Notification permission was not granted.';

  @override
  String get adhanSaveFailed => 'Could not save adhan settings.';

  @override
  String get adhanHint =>
      'Notifications are scheduled on-device for two weeks and refreshed when the app opens.';

  @override
  String get audioLoadError => 'Could not load the surah list.';

  @override
  String get audioPlaybackError =>
      'Could not play the recitation. Check your internet connection.';

  @override
  String get adhanBatteryTitle => 'Keep adhan on time';

  @override
  String get adhanBatteryHint =>
      'Allow the app to run in the background and turn off battery optimisation for it in system settings.';

  @override
  String get creditsSection => 'About';

  @override
  String get creditsTitle => 'Sources and licences';

  @override
  String get creditsIntro =>
      'The app relies on the following sources. The Quran text is bundled verbatim and is never edited.';

  @override
  String get creditsTanzilName => 'Tanzil Project';

  @override
  String get creditsTanzilWhat => 'Uthmani Quran text and surah/juz metadata';

  @override
  String get creditsTanzilLicense => 'CC BY 3.0 — © Tanzil Project';

  @override
  String get creditsTanzilNotice =>
      'The Uthmani Quran text is used unmodified, with its source (Tanzil Project) indicated and a link to tanzil.net.';

  @override
  String get creditsAdhkarName => 'Hisn al-Muslim (HisnElMuslim)';

  @override
  String get creditsAdhkarWhat => 'Adhkar texts, repeat counts and references';

  @override
  String get creditsAdhkarLicense => 'MIT — © Abdellah SELLAM';

  @override
  String get creditsAdhkarNotice =>
      'Adhkar texts come from the open-source Hisn al-Muslim collection under the MIT licence.';

  @override
  String get creditsAdhanName => 'Adhan recordings';

  @override
  String get creditsAdhanWhat =>
      'Three bundled adhan recordings (29-second excerpt on iOS)';

  @override
  String get creditsAdhanLicense => 'CC0 1.0 and public domain';

  @override
  String get creditsAdhanNotice =>
      'Beautiful adhan by Adam-synagda (CC0) and Adhan by Aishatu98 (CC0) via Wikimedia Commons, plus the Sabah Fakhri adhan (public domain). Audio was format-converted; iOS uses a 29-second excerpt within the system limit.';

  @override
  String get creditsAudioName => 'EveryAyah';

  @override
  String get creditsAudioWhat => 'Ayah-by-ayah Quran recitation';

  @override
  String get creditsAudioLicense => 'Freely available';

  @override
  String get creditsAudioNotice =>
      'Recitations stream from everyayah.com and are not bundled in the app.';

  @override
  String get creditsFontsName => 'Fonts';

  @override
  String get creditsFontsWhat => 'Tajawal and Amiri Quran';

  @override
  String get creditsFontsLicense => 'SIL OFL 1.1';

  @override
  String get creditsFontsNotice =>
      'Arabic fonts under the SIL Open Font License 1.1.';

  @override
  String get creditsFullLicense => 'Full licence text';

  @override
  String get creditsOpenSource => 'Open source';

  @override
  String get adhanScheduleFailed =>
      'Settings were saved, but notifications could not be scheduled.';

  @override
  String get audioDownloadAll => 'Download all surahs';

  @override
  String get audioCancelDownload => 'Stop downloading';

  @override
  String audioDownloadProgress(int done, int total) {
    return 'Downloading: $done / $total';
  }

  @override
  String get audioDownloadComplete => 'Download complete.';

  @override
  String get audioDownloadFailed =>
      'Some files could not be downloaded. Check your connection.';

  @override
  String get audioDownloaded => 'Downloaded';

  @override
  String get audioDeleteDownload => 'Delete download';

  @override
  String get audioDeleted => 'Surah download deleted.';

  @override
  String audioStorageUsed(String size) {
    return 'Stored: $size';
  }

  @override
  String get audioAllDownloaded => 'All surahs downloaded';

  @override
  String get audioCancelDownloadShort => 'Stop';

  @override
  String get audioDownloadStopped => 'Download stopped.';

  @override
  String get audioDownloadSurah => 'Download surah';

  @override
  String get widgetsSection => 'Home-screen widgets';

  @override
  String get widgetPinHint => 'Pin a widget with one tap.';

  @override
  String get widgetNextPrayer => 'Next-prayer widget';

  @override
  String get widgetPrayerTimes => 'Prayer-times widget';

  @override
  String get widgetStreak => 'Streak widget';

  @override
  String get widgetPinUnsupported =>
      'Pinning widgets is not supported on this device.';

  @override
  String get audioModeQuran => 'Quran';

  @override
  String get audioModeAnasheed => 'Anasheed';

  @override
  String get anasheedSearchHint => 'Search anasheed';

  @override
  String get anasheedEmpty => 'No results.';

  @override
  String get anasheedError => 'Could not load anasheed. Check your connection.';

  @override
  String get anasheedSourceNote =>
      'Results from Openverse under open licences.';

  @override
  String get creditsOpenverseName => 'Openverse';

  @override
  String get creditsOpenverseWhat => 'Openly licensed audio index for anasheed';

  @override
  String get creditsOpenverseLicense => 'CC — per work';

  @override
  String get creditsOpenverseNotice =>
      'Anasheed results come from Openverse with each work licence and source shown.';

  @override
  String get adhanHealthTitle => 'Notification health';

  @override
  String get adhanHealthHint =>
      'For on-time adhan, allow notifications and exact alarms, and turn off battery optimisation.';

  @override
  String get adhanNotificationsOn => 'Notifications allowed';

  @override
  String get adhanNotificationsOff => 'Notifications blocked';

  @override
  String get adhanExactOn => 'Exact alarms allowed';

  @override
  String get adhanExactOff => 'Exact alarms blocked';

  @override
  String get adhanBatteryOk => 'Battery unrestricted';

  @override
  String get adhanBatteryNeedsSetup => 'Battery restricted by system';

  @override
  String adhanPendingCount(int count) {
    return 'Scheduled notifications: $count';
  }

  @override
  String get adhanAllowExact => 'Allow exact alarms';

  @override
  String get adhanOpenBattery => 'Battery settings';

  @override
  String get adhanTestNow => 'Test now';

  @override
  String get adhanTestInTwo => 'Test in 2 minutes';

  @override
  String get adhanTestScheduled =>
      'The test notification will arrive in two minutes.';

  @override
  String get adhkarRemindersTitle => 'Adhkar reminders';

  @override
  String get adhkarRemindersHint =>
      'A gentle reminder for morning, evening and sleep adhkar.';

  @override
  String get adhkarSleep => 'Sleep adhkar';

  @override
  String adhkarAfterFajr(int minutes) {
    return '$minutes minutes after Fajr';
  }

  @override
  String adhkarAfterAsr(int minutes) {
    return '$minutes minutes after Asr';
  }

  @override
  String adhkarSleepAt(String time) {
    return 'At $time';
  }

  @override
  String get defaultReciterTitle => 'Default reciter';

  @override
  String get defaultReciterHint =>
      'Used when the audio tab opens and recitation starts.';

  @override
  String audioAyahOf(int index, int total) {
    return 'Ayah $index of $total';
  }

  @override
  String get audioModeRadio => 'Radio';

  @override
  String get audioRadioHint => 'Islamic stations only, live.';

  @override
  String get adhanSoundBeautiful => 'Calm adhan (CC0)';

  @override
  String get adhanSoundAdhan => 'Melodic adhan (CC0)';

  @override
  String get adhanSoundSabah => 'Sabah Fakhri adhan (public domain)';

  @override
  String get adhanSoundSilent => 'Silent';

  @override
  String get adhanSoundHint =>
      'Choose the adhan tone; it plays at prayer time only.';

  @override
  String get audioLiveBadge => 'Live';

  @override
  String get audioLiveHint =>
      'Live stream — seeking and skipping are disabled.';
}
