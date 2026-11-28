import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakeenah_mobile/theme/sakeenah_theme.dart';

double contrastRatio(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  final lighter = a > b ? a : b;
  final darker = a > b ? b : a;
  return (lighter + 0.05) / (darker + 0.05);
}

RoundedRectangleBorder roundedShape(
  WidgetStateProperty<OutlinedBorder?>? shape,
) {
  final resolved = shape?.resolve(const <WidgetState>{});
  expect(resolved, isA<RoundedRectangleBorder>());
  return resolved! as RoundedRectangleBorder;
}

void main() {
  group('Sakeenah light theme', () {
    final theme = SakeenahTheme.light();

    test('provides the Alabaster and Sanctuary Emerald surfaces', () {
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF7F5F0));
      expect(theme.colorScheme.surface, const Color(0xFFFFFFFF));
      expect(theme.colorScheme.primary, const Color(0xFF145349));
      expect(theme.colorScheme.onPrimary, const Color(0xFFFFFFFF));
      expect(theme.colorScheme.primaryContainer, const Color(0xFFE6F0ED));
      expect(theme.colorScheme.secondary, const Color(0xFFB88E3B));
      expect(theme.colorScheme.onSecondaryContainer, const Color(0xFF6B511A));
      expect(theme.colorScheme.onSurface, const Color(0xFF1B2422));
      expect(theme.colorScheme.onSurfaceVariant, const Color(0xFF5A6864));
      expect(theme.colorScheme.outline, const Color(0xFFE5E0D5));
      expect(theme.appBarTheme.backgroundColor, const Color(0xFFF7F5F0));
    });

    test('keeps body, metadata and small active labels accessible', () {
      expect(
        contrastRatio(
          theme.colorScheme.onSurface,
          theme.scaffoldBackgroundColor,
        ),
        greaterThanOrEqualTo(7),
      );
      expect(
        contrastRatio(
          theme.colorScheme.onSurfaceVariant,
          theme.scaffoldBackgroundColor,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrastRatio(theme.colorScheme.primary, theme.colorScheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrastRatio(
          theme.colorScheme.onSecondaryContainer,
          theme.colorScheme.surface,
        ),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('uses the specified card and control geometry', () {
      final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;
      expect(cardShape.borderRadius, BorderRadius.circular(16));
      expect(
        roundedShape(theme.filledButtonTheme.style?.shape).borderRadius,
        BorderRadius.circular(12),
      );
      expect(
        roundedShape(theme.outlinedButtonTheme.style?.shape).borderRadius,
        BorderRadius.circular(12),
      );
    });

    test('Quran type has generous line spacing for diacritics', () {
      final style = SakeenahTheme.quran(const TextStyle());
      expect(style.fontFamily, 'AmiriQuran');
      expect(style.height, greaterThanOrEqualTo(2.0));
      expect(style.height, lessThanOrEqualTo(2.2));
    });
  });

  group('Sakeenah dark theme', () {
    final theme = SakeenahTheme.dark();

    test('uses derived Sanctuary surfaces and preserves readable contrast', () {
      expect(theme.scaffoldBackgroundColor, const Color(0xFF0C1512));
      expect(theme.colorScheme.surface, const Color(0xFF13211D));
      expect(theme.colorScheme.onSurface, const Color(0xFFF4F1E8));
      expect(theme.colorScheme.primary, const Color(0xFF7FC3B2));
      expect(theme.colorScheme.secondary, const Color(0xFFD4AF63));
      expect(
        contrastRatio(
          theme.colorScheme.onSurface,
          theme.scaffoldBackgroundColor,
        ),
        greaterThanOrEqualTo(7),
      );
      expect(
        contrastRatio(theme.colorScheme.primary, theme.colorScheme.surface),
        greaterThanOrEqualTo(4.5),
      );
    });
  });
}
