import 'package:material_ui/material_ui.dart';

/// Colour tokens for the Sakeenah palette.
///
/// The five brand colours are the owner-supplied palette. The remaining values
/// are derived tints for states, borders and the dark theme.
abstract final class SakeenahColors {
  // Alabaster Light
  static const canvas = Color(0xFFF7F5F0);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF145349);
  static const primarySoft = Color(0xFFE6F0ED);
  static const accent = Color(0xFFB88E3B);
  static const accentInk = Color(0xFF6B511A);
  static const text = Color(0xFF1B2422);
  static const secondaryText = Color(0xFF5A6864);
  static const border = Color(0xFFE5E0D5);

  // Sanctuary dark (derived, not a pure inversion).
  static const darkCanvas = Color(0xFF0C1512);
  static const darkSurface = Color(0xFF13211D);
  static const darkRaised = Color(0xFF1A2B26);
  static const darkPrimary = Color(0xFF7FC3B2);
  static const darkPrimarySoft = Color(0xFF1D332C);
  static const darkAccent = Color(0xFFD4AF63);
  static const darkText = Color(0xFFF4F1E8);
  static const darkSecondaryText = Color(0xFFA8B5AF);
  static const darkBorder = Color(0xFF2A3B35);

  // Compatibility aliases for feature widgets; migrate callers to semantic
  // ColorScheme values when those widgets are touched.
  static const green = primary;
  static const ivory = canvas;
  static const gold = accent;
  static const ink = text;
  static const sand = primarySoft;
  static const greenDark = primary;
  static const greenSoft = primarySoft;
  static const goldSoft = Color(0xFFF2E8D2);
  static const goldInk = accentInk;
  static const muted = secondaryText;
  static const line = border;

  // Legacy dark aliases.
  static const night = darkCanvas;
  static const nightSurface = darkSurface;
  static const nightRaised = darkRaised;
  static const nightLine = darkBorder;
  static const nightMuted = darkSecondaryText;
  static const nightError = Color(0xFFFFB4AB);
  static const error = Color(0xFFB3261E);
  static const errorSoft = Color(0xFFF9DEDC);
}

abstract final class SakeenahTheme {
  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: SakeenahColors.darkPrimary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: SakeenahColors.darkPrimary,
          onPrimary: SakeenahColors.darkCanvas,
          primaryContainer: SakeenahColors.darkPrimarySoft,
          onPrimaryContainer: SakeenahColors.darkText,
          secondary: SakeenahColors.darkAccent,
          onSecondary: SakeenahColors.darkCanvas,
          secondaryContainer: SakeenahColors.darkRaised,
          onSecondaryContainer: SakeenahColors.darkAccent,
          surface: SakeenahColors.darkSurface,
          onSurface: SakeenahColors.darkText,
          surfaceContainerLowest: SakeenahColors.darkCanvas,
          surfaceContainerLow: SakeenahColors.darkSurface,
          surfaceContainer: SakeenahColors.darkRaised,
          surfaceContainerHigh: const Color(0xFF223831),
          surfaceContainerHighest: const Color(0xFF2A4038),
          onSurfaceVariant: SakeenahColors.darkSecondaryText,
          outline: SakeenahColors.darkBorder,
          outlineVariant: SakeenahColors.darkRaised,
          error: SakeenahColors.nightError,
          onError: const Color(0xFF690005),
        );
    return _base(
      scheme: scheme,
      scaffold: SakeenahColors.darkCanvas,
      card: SakeenahColors.darkSurface,
      bar: SakeenahColors.darkSurface,
      dark: true,
    );
  }

  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: SakeenahColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: SakeenahColors.primary,
          onPrimary: SakeenahColors.surface,
          primaryContainer: SakeenahColors.primarySoft,
          onPrimaryContainer: SakeenahColors.primary,
          secondary: SakeenahColors.accent,
          onSecondary: SakeenahColors.text,
          secondaryContainer: const Color(0xFFF2E8D2),
          onSecondaryContainer: SakeenahColors.accentInk,
          surface: SakeenahColors.surface,
          onSurface: SakeenahColors.text,
          surfaceContainerLowest: SakeenahColors.surface,
          surfaceContainerLow: SakeenahColors.surface,
          surfaceContainer: SakeenahColors.canvas,
          surfaceContainerHigh: SakeenahColors.primarySoft,
          surfaceContainerHighest: const Color(0xFFD7E7E2),
          onSurfaceVariant: SakeenahColors.secondaryText,
          outline: SakeenahColors.border,
          outlineVariant: SakeenahColors.primarySoft,
          error: SakeenahColors.error,
          onError: SakeenahColors.surface,
        );
    return _base(
      scheme: scheme,
      scaffold: SakeenahColors.canvas,
      card: SakeenahColors.surface,
      bar: SakeenahColors.canvas,
      dark: false,
    );
  }

  static ThemeData _base({
    required ColorScheme scheme,
    required Color scaffold,
    required Color card,
    required Color bar,
    required bool dark,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      fontFamily: 'Tajawal',
    );
    final primary = scheme.primary;
    final accent = dark ? SakeenahColors.darkAccent : SakeenahColors.accent;
    final selectedFill = scheme.primaryContainer;
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: bar,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: scheme.onSurface),
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bar,
        surfaceTintColor: Colors.transparent,
        indicatorColor: selectedFill,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => base.textTheme.labelMedium?.copyWith(
            fontFamily: 'Tajawal',
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: scheme.onPrimary,
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w700,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? primary : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primaryContainer
              : scheme.surfaceContainerHigh,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? primary : scheme.outline,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? primary : scheme.outline,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: scheme.outline,
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.16),
        trackHeight: 4,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: scheme.outlineVariant,
        circularTrackColor: scheme.outlineVariant,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? selectedFill
                : scheme.surfaceContainerLow,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurface,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
          iconColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w600),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: selectedFill,
        labelStyle: TextStyle(fontSize: 11, color: scheme.onSurface),
        secondaryLabelStyle: TextStyle(
          fontSize: 11,
          color: scheme.onPrimaryContainer,
        ),
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.onSurface,
        contentTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          color: scheme.surface,
        ),
        actionTextColor: accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: accent,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w700,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.onSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(
          fontFamily: 'Tajawal',
          color: scheme.surface,
          fontSize: 11,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
        fontFamily: 'Tajawal',
      ),
    );
  }

  /// Large Quran text uses the dedicated Amiri Quran face.
  static TextStyle quran(TextStyle base, {double size = 28}) =>
      base.copyWith(fontFamily: 'AmiriQuran', fontSize: size, height: 2.1);
}
