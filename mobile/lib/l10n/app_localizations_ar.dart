// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'سَكينة';

  @override
  String get navDashboard => 'الرئيسية';

  @override
  String get navQuran => 'المصحف';

  @override
  String get navAdhkar => 'الأذكار';

  @override
  String get navAudio => 'الصوت';

  @override
  String get settings => 'الإعدادات';

  @override
  String get languageSection => 'اللغة';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get comingSoon => 'قريبًا';

  @override
  String get dashboardWelcome => 'طمأنينة القلب';

  @override
  String get dashboardSubtitle =>
      'القرآن، ومواقيت الصلاة، والأذكار، والصوت — دون إنترنت.';

  @override
  String get prayerCardTitle => 'الصلاة والقبلة';

  @override
  String get prayerCardBody =>
      'مواقيت محسوبة على جهازك، وسجل صلوات، وسلسلة استمرارية.';

  @override
  String get quranCardTitle => 'المصحف';

  @override
  String get quranCardBody =>
      'النص العثماني كاملًا، قراءة بالسور أو الأجزاء، مع العلامات وآخر موضع.';

  @override
  String get adhkarCardTitle => 'الأذكار';

  @override
  String get adhkarCardBody =>
      'حصن المسلم كاملًا مع العدادات والتقدم وسلسلة يومية.';

  @override
  String get audioCardTitle => 'التلاوات والأناشيد';

  @override
  String get audioCardBody =>
      'تشغيل في الخلفية، قوائم تشغيل، وتنزيلات للاستماع دون إنترنت.';

  @override
  String get quranPageTitle => 'المصحف';

  @override
  String get adhkarPageTitle => 'الأذكار';

  @override
  String get audioPageTitle => 'الصوت';

  @override
  String get settingsPageTitle => 'الإعدادات';

  @override
  String get settingsOverview => 'نظرة عامة';

  @override
  String get settingsPlaceholder =>
      'ستصل إعدادات الموقع والتذكير والصوت في المراحل القادمة.';

  @override
  String get dashboardTitle => 'الرئيسية';

  @override
  String get themeSection => 'المظهر';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeLight => 'فاتح';

  @override
  String versionLine(String version) {
    return 'الإصدار $version';
  }

  @override
  String get startupErrorTitle => 'تعذّر بدء سَكينة';

  @override
  String get startupErrorBody =>
      'لم نتمكن من تجهيز البيانات المحلية. أعد المحاولة، وإن استمرت المشكلة فأعد تثبيت التطبيق.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get prayerNext => 'الصلاة القادمة';

  @override
  String prayerTimeRemaining(String time) {
    return 'متبقي $time';
  }

  @override
  String get prayerToday => 'مواقيت اليوم';

  @override
  String get prayerStreak => 'سلسلة الصلوات';

  @override
  String get prayerBestStreak => 'أفضل سلسلة';

  @override
  String get prayerExcusedDay => 'يوم معذور';

  @override
  String get prayerMarkOnTime => 'في الوقت';

  @override
  String get prayerMarkLate => 'متأخرة';

  @override
  String get prayerMarkQada => 'قضاء';

  @override
  String get prayerMarkMissed => 'فائتة';

  @override
  String get prayerClear => 'مسح';

  @override
  String get prayerExcuse => 'احتساب اليوم معذورًا';

  @override
  String get prayerUnExcuse => 'إلغاء عذر اليوم';

  @override
  String get prayerLocationMissing =>
      'لم يتم ضبط موقعك بعد؛ المواقيت المعروضة لإحداثيات مكة الافتراضية.';

  @override
  String get prayerOpenSettings => 'ضبط الموقع';

  @override
  String get qiblaTitle => 'القبلة';

  @override
  String qiblaBearing(String degrees) {
    return 'اتجاه القبلة $degrees°';
  }

  @override
  String get hijriTitle => 'التاريخ الهجري';

  @override
  String get prayerSettings => 'إعدادات الصلاة';

  @override
  String get prayerLocationSection => 'الموقع والمواقيت';

  @override
  String get prayerCalculationSection => 'طريقة الحساب';

  @override
  String get cityLabel => 'المدينة';

  @override
  String get customLocation => 'موقع مخصص';

  @override
  String get latitudeLabel => 'خط العرض';

  @override
  String get longitudeLabel => 'خط الطول';

  @override
  String get timezoneLabel => 'المنطقة الزمنية';

  @override
  String get methodLabel => 'طريقة الحساب';

  @override
  String get madhabLabel => 'مذهب العصر';

  @override
  String get shafi => 'شافعي';

  @override
  String get hanafi => 'حنفي';

  @override
  String get highLatitudeLabel => 'خطوط العرض العالية';

  @override
  String get hijriAdjustmentLabel => 'تعديل التاريخ الهجري';

  @override
  String get settingsSaved => 'تم حفظ الإعدادات';

  @override
  String get sunrise => 'الشروق';

  @override
  String get save => 'حفظ';

  @override
  String get prayerInvalidCoordinates => 'أدخل إحداثيات صحيحة.';

  @override
  String get prayerTimesUnavailable =>
      'تعذّر حساب مواقيت الصلاة لهذا الموقع والتاريخ. جرّب موقعًا آخر أو خط عرض أقل.';

  @override
  String get settingsSaveFailed => 'تعذّر حفظ الإعدادات. حاول مرة أخرى.';

  @override
  String get adhkarToday => 'أذكار اليوم';

  @override
  String get adhkarMorning => 'أذكار الصباح';

  @override
  String get adhkarEvening => 'أذكار المساء';

  @override
  String get adhkarFeatured => 'أذكار مختارة';

  @override
  String get adhkarAll => 'كل الأذكار';

  @override
  String get adhkarSearch => 'ابحث في الأذكار';

  @override
  String get adhkarNoResults => 'لا توجد نتائج';

  @override
  String adhkarRemaining(String count) {
    return 'متبقي $count';
  }

  @override
  String get adhkarDone => 'تم';

  @override
  String get adhkarTapToCount => 'اضغط للعد';

  @override
  String get adhkarCompletedTitle => 'أتممت الأذكار';

  @override
  String get adhkarCompletedBody => 'أُضيفت إلى سلسلة اليوم.';

  @override
  String get adhkarResetItem => 'إعادة هذا الذكر';

  @override
  String adhkarCategoryProgress(int completed, int total) {
    return 'التقدم: $completed من $total';
  }

  @override
  String get adhkarClose => 'إغلاق';

  @override
  String get adhkarResetCategory => 'إعادة القسم';

  @override
  String get adhkarCompletedBodyGeneric => 'تم إكمال أذكار هذا القسم.';

  @override
  String adhkarStreakCount(int count) {
    return 'سلسلة الأذكار: $count';
  }

  @override
  String adhkarBestCount(int count) {
    return 'أفضل سلسلة: $count';
  }

  @override
  String get adhkarPrevious => 'السابق';

  @override
  String get adhkarNext => 'التالي';

  @override
  String get adhkarLoadError => 'تعذر تحميل الأذكار.';

  @override
  String get adhkarActionError => 'تعذر حفظ التقدم.';

  @override
  String get adhkarClearSearch => 'مسح البحث';

  @override
  String get adhkarGoHome => 'الرئيسية';

  @override
  String prayerTodayProgress(int count) {
    return 'اليوم: $count / 5';
  }

  @override
  String get locationTitle => 'تحديد الموقع';

  @override
  String get locationBody =>
      'نستخدم موقعك على هذا الجهاز فقط لحساب مواقيت الصلاة والقبلة. لا يُرسل إلى أي خادم.';

  @override
  String get locationUse => 'استخدم موقعي';

  @override
  String get locationChooseCity => 'اختيار مدينة';

  @override
  String get locationDenied =>
      'لم يتم السماح بالوصول إلى الموقع. يمكنك اختيار مدينة يدويًا.';

  @override
  String get locationDeniedForever =>
      'تم رفض إذن الموقع. افتح إعدادات التطبيق للسماح به.';

  @override
  String get locationUnavailable => 'تعذر تحديد موقعك الآن. حاول مرة أخرى.';

  @override
  String get locationOpenSettings => 'فتح إعدادات التطبيق';

  @override
  String get locationFetching => 'جارٍ تحديد موقعك…';

  @override
  String get locationSaved => 'تم استخدام موقعك الحالي.';

  @override
  String get locationSourceDevice => 'موقع الجهاز';

  @override
  String get settingsLocationUse => 'استخدم موقعي الحالي';

  @override
  String get quranTabSurahs => 'السور';

  @override
  String get quranTabJuz => 'الأجزاء';

  @override
  String get quranTabBookmarks => 'العلامات';

  @override
  String get quranTabResume => 'المتابعة';

  @override
  String get quranSearch => 'ابحث عن سورة';

  @override
  String get quranSearchEmpty => 'لا توجد سور مطابقة';

  @override
  String get quranNoBookmarks => 'لا توجد علامات بعد';

  @override
  String get quranNoResume => 'لم تبدأ القراءة بعد';

  @override
  String get quranDailyAyah => 'آية اليوم';

  @override
  String quranJuz(int number) {
    return 'الجزء $number';
  }

  @override
  String quranAyahCount(int count) {
    return '$count آية';
  }

  @override
  String get quranMakkah => 'مكية';

  @override
  String get quranMadinah => 'مدنية';

  @override
  String get quranContinue => 'متابعة القراءة';

  @override
  String quranResumeAt(String surah, int ayah) {
    return '$surah · الآية $ayah';
  }

  @override
  String quranBookmarkAt(String surah, int ayah) {
    return '$surah · الآية $ayah';
  }

  @override
  String get quranRemoveBookmark => 'إزالة العلامة';

  @override
  String get quranAddBookmark => 'إضافة علامة';

  @override
  String get quranSajda => 'سجدة';

  @override
  String get quranReaderError => 'تعذر تحميل المصحف.';

  @override
  String get quranFontDecrease => 'تصغير الخط';

  @override
  String get quranFontIncrease => 'تكبير الخط';

  @override
  String get quranRead => 'قراءة';

  @override
  String quranJuzStart(String surah, int ayah) {
    return 'يبدأ من $surah · $ayah';
  }

  @override
  String quranAyahLabel(int number) {
    return 'الآية $number';
  }

  @override
  String get audioChooseReciter => 'اختر القارئ';

  @override
  String get audioSearchSurah => 'ابحث عن سورة';

  @override
  String get audioPlaySurah => 'تشغيل السورة';

  @override
  String get audioNowPlaying => 'قيد التشغيل';

  @override
  String get audioPlay => 'تشغيل';

  @override
  String get audioPause => 'إيقاف مؤقت';

  @override
  String get audioNext => 'التالي';

  @override
  String get audioPrevious => 'السابق';

  @override
  String get audioSpeed => 'السرعة';

  @override
  String get audioRepeat => 'التكرار';

  @override
  String get audioRepeatOff => 'بدون تكرار';

  @override
  String get audioRepeatOne => 'تكرار الآية';

  @override
  String get audioRepeatAll => 'تكرار السورة';

  @override
  String get audioQueueEmpty => 'لم يتم تشغيل أي تلاوة';

  @override
  String get audioStop => 'إيقاف';

  @override
  String audioAyahLabel(int number) {
    return 'الآية $number';
  }

  @override
  String get audioReciterLabel => 'القارئ';

  @override
  String get audioStopPlayback => 'إيقاف التلاوة';

  @override
  String get adhanSection => 'الأذان والتنبيهات';

  @override
  String get adhanEnable => 'تفعيل إشعارات الصلاة';

  @override
  String get adhanPreAlert => 'التنبيه المسبق';

  @override
  String get adhanNoPreAlert => 'بدون تنبيه مسبق';

  @override
  String adhanMinutes(int minutes) {
    return 'قبلها بـ $minutes دقيقة';
  }

  @override
  String get adhanSound => 'صوت الأذان';

  @override
  String get adhanTest => 'إرسال إشعار تجريبي';

  @override
  String get adhanTestSent => 'تم إرسال إشعار تجريبي.';

  @override
  String get adhanPermissionDenied => 'لم يتم منح إذن الإشعارات.';

  @override
  String get adhanSaveFailed => 'تعذر حفظ إعدادات الأذان.';

  @override
  String get adhanHint =>
      'تُجدول التنبيهات محليًا لمدة أسبوعين وتُجدد عند فتح التطبيق.';

  @override
  String get audioLoadError => 'تعذر تحميل قائمة السور.';

  @override
  String get audioPlaybackError =>
      'تعذر تشغيل التلاوة. تحقق من اتصالك بالإنترنت.';

  @override
  String get adhanBatteryTitle => 'لضمان وصول الأذان في وقته';

  @override
  String get adhanBatteryHint =>
      'اسمح للتطبيق بالعمل في الخلفية وأوقف تحسين البطارية له من إعدادات النظام.';

  @override
  String get creditsSection => 'عن التطبيق';

  @override
  String get creditsTitle => 'المصادر والتراخيص';

  @override
  String get creditsIntro =>
      'يعتمد التطبيق على المصادر التالية. النص القرآني مضمَّن كما هو دون أي تعديل.';

  @override
  String get creditsTanzilName => 'مشروع تنزيل (Tanzil)';

  @override
  String get creditsTanzilWhat =>
      'النص القرآني العثماني وبيانات السور والأجزاء';

  @override
  String get creditsTanzilLicense => 'CC BY 3.0 — © Tanzil Project';

  @override
  String get creditsTanzilNotice =>
      'يُستخدم النص القرآني العثماني كما هو، مع الإشارة إلى مصدره Tanzil Project ورابط tanzil.net.';

  @override
  String get creditsAdhkarName => 'حصن المسلم (HisnElMuslim)';

  @override
  String get creditsAdhkarWhat => 'نصوص الأذكار وتكرارها ومصادرها';

  @override
  String get creditsAdhkarLicense => 'MIT — © Abdellah SELLAM';

  @override
  String get creditsAdhkarNotice =>
      'نصوص الأذكار مأخوذة من مجموعة حصن المسلم مفتوحة المصدر بترخيص MIT.';

  @override
  String get creditsAdhanName => 'تسجيلات الأذان';

  @override
  String get creditsAdhanWhat =>
      'ثلاثة تسجيلات أذان مضمَّنة (مقتطف ٢٩ ثانية على iOS)';

  @override
  String get creditsAdhanLicense => 'CC0 1.0 وملكية عامة';

  @override
  String get creditsAdhanNotice =>
      'Beautiful adhan — Adam-synagda (CC0)، وAdhan — Aishatu98 (CC0) عبر Wikimedia Commons، وأذان صباح فخري (ملكية عامة). حُوِّلت الصيغة، ويُستخدم مقتطف ٢٩ ثانية على iOS ضمن حد النظام.';

  @override
  String get creditsAudioName => 'EveryAyah';

  @override
  String get creditsAudioWhat => 'تلاوة القرآن آية بآية';

  @override
  String get creditsAudioLicense => 'متاح مجانًا';

  @override
  String get creditsAudioNotice =>
      'تُبَث التلاوات من everyayah.com ولا تُضمَّن ملفاتها في التطبيق.';

  @override
  String get creditsFontsName => 'الخطوط';

  @override
  String get creditsFontsWhat => 'Tajawal و Amiri Quran';

  @override
  String get creditsFontsLicense => 'SIL OFL 1.1';

  @override
  String get creditsFontsNotice =>
      'خطوط عربية مفتوحة بترخيص SIL Open Font License 1.1.';

  @override
  String get creditsFullLicense => 'نص الترخيص الكامل';

  @override
  String get creditsOpenSource => 'فتح المصدر';

  @override
  String get adhanScheduleFailed =>
      'تم حفظ الإعدادات، لكن تعذر جدولة التنبيهات.';

  @override
  String get audioDownloadAll => 'تنزيل كل السور';

  @override
  String get audioCancelDownload => 'إيقاف التنزيل';

  @override
  String audioDownloadProgress(int done, int total) {
    return 'جارٍ التنزيل: $done / $total';
  }

  @override
  String get audioDownloadComplete => 'اكتمل التنزيل.';

  @override
  String get audioDownloadFailed => 'تعذر تنزيل بعض الملفات. تحقق من الاتصال.';

  @override
  String get audioDownloaded => 'منزّلة';

  @override
  String get audioDeleteDownload => 'حذف التنزيل';

  @override
  String get audioDeleted => 'تم حذف تنزيل السورة.';

  @override
  String audioStorageUsed(String size) {
    return 'المحفوظ: $size';
  }

  @override
  String get audioAllDownloaded => 'كل السور منزّلة';

  @override
  String get audioCancelDownloadShort => 'إيقاف';

  @override
  String get audioDownloadStopped => 'تم إيقاف التنزيل.';

  @override
  String get audioDownloadSurah => 'تنزيل السورة';

  @override
  String get widgetsSection => 'أدوات الشاشة الرئيسية';

  @override
  String get widgetPinHint => 'أضف أداة بلمسة واحدة.';

  @override
  String get widgetNextPrayer => 'أداة الصلاة القادمة';

  @override
  String get widgetPrayerTimes => 'أداة مواقيت الصلاة';

  @override
  String get widgetStreak => 'أداة سلسلة الصلاة';

  @override
  String get widgetPinUnsupported => 'إضافة الأدوات غير مدعومة على هذا الجهاز.';

  @override
  String get audioModeQuran => 'القرآن';

  @override
  String get audioModeAnasheed => 'الأناشيد';

  @override
  String get anasheedSearchHint => 'ابحث عن نشيد';

  @override
  String get anasheedEmpty => 'لا توجد نتائج.';

  @override
  String get anasheedError => 'تعذر تحميل الأناشيد. تحقق من الاتصال.';

  @override
  String get anasheedSourceNote => 'نتائج من Openverse بتراخيص مفتوحة.';

  @override
  String get creditsOpenverseName => 'Openverse';

  @override
  String get creditsOpenverseWhat => 'فهرس صوتي مفتوح الترخيص للأناشيد';

  @override
  String get creditsOpenverseLicense => 'CC — حسب كل عمل';

  @override
  String get creditsOpenverseNotice =>
      'تأتي نتائج الأناشيد من Openverse وتُعرض مع ترخيص كل عمل ومصدره.';

  @override
  String get adhanHealthTitle => 'حالة التنبيهات';

  @override
  String get adhanHealthHint =>
      'لضمان وصول الأذان في وقته، اسمح بالإشعارات والأذان الدقيق وأوقف تحسين البطارية.';

  @override
  String get adhanNotificationsOn => 'الإشعارات مسموحة';

  @override
  String get adhanNotificationsOff => 'الإشعارات ممنوعة';

  @override
  String get adhanExactOn => 'الأذان الدقيق مسموح';

  @override
  String get adhanExactOff => 'الأذان الدقيق ممنوع';

  @override
  String get adhanBatteryOk => 'البطارية غير مقيّدة';

  @override
  String get adhanBatteryNeedsSetup => 'قيّد النظام البطارية';

  @override
  String adhanPendingCount(int count) {
    return 'تنبيهات مجدولة: $count';
  }

  @override
  String get adhanAllowExact => 'السماح بالأذان الدقيق';

  @override
  String get adhanOpenBattery => 'إعدادات البطارية';

  @override
  String get adhanTestNow => 'اختبار الآن';

  @override
  String get adhanTestInTwo => 'اختبار بعد دقيقتين';

  @override
  String get adhanTestScheduled => 'سيصل تنبيه الاختبار بعد دقيقتين.';

  @override
  String get adhkarRemindersTitle => 'تذكير الأذكار';

  @override
  String get adhkarRemindersHint => 'تذكير هادئ بأذكار الصباح والمساء والنوم.';

  @override
  String get adhkarSleep => 'أذكار النوم';

  @override
  String adhkarAfterFajr(int minutes) {
    return 'بعد الفجر بـ $minutes دقيقة';
  }

  @override
  String adhkarAfterAsr(int minutes) {
    return 'بعد العصر بـ $minutes دقيقة';
  }

  @override
  String adhkarSleepAt(String time) {
    return 'الساعة $time';
  }

  @override
  String get defaultReciterTitle => 'القارئ الافتراضي';

  @override
  String get defaultReciterHint => 'يُستخدم عند فتح الصوت وبدء التلاوة.';

  @override
  String audioAyahOf(int index, int total) {
    return 'الآية $index من $total';
  }

  @override
  String get audioModeRadio => 'الإذاعات';

  @override
  String get audioRadioHint => 'إذاعات إسلامية فقط، بث مباشر.';

  @override
  String get adhanSoundBeautiful => 'أذان هادئ (CC0)';

  @override
  String get adhanSoundAdhan => 'أذان مرتّل (CC0)';

  @override
  String get adhanSoundSabah => 'أذان صباح فخري (ملك عام)';

  @override
  String get adhanSoundSilent => 'صامت';

  @override
  String get adhanSoundHint => 'اختر نغمة الأذان؛ تُستخدم في وقت الصلاة فقط.';

  @override
  String get audioLiveBadge => 'مباشر';

  @override
  String get audioLiveHint => 'بث مباشر — لا يمكن التقديم أو الإرجاع.';
}
