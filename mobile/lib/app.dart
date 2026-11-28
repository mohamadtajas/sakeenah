import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';

import 'data/app_services.dart';
import 'l10n/app_localizations.dart';
import 'shell/app_shell.dart';
import 'theme/sakeenah_theme.dart';

class SakeenahApp extends StatelessWidget {
  const SakeenahApp({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppServices.current;
    return ValueListenableBuilder<Locale>(
      valueListenable: services.locale,
      builder: (context, locale, _) => ValueListenableBuilder<ThemeMode>(
        valueListenable: services.themeMode,
        builder: (context, mode, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: SakeenahTheme.light(),
          darkTheme: SakeenahTheme.dark(),
          themeMode: mode,
          home: AppShell(
            themeMode: mode,
            locale: locale,
            onThemeChanged: (next) {
              unawaited(services.updateThemeMode(next).catchError((_) {}));
            },
            onLocaleChanged: (next) {
              unawaited(services.setLocale(next).catchError((_) {}));
            },
          ),
        ),
      ),
    );
  }
}
