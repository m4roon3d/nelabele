import 'ui.dart';

/// NelaBele brand colours (see the NelaBele design system).
abstract final class Brand {
  static const redEarth = Color(0xFFB4532A);
  static const redEarthText = Color(0xFFA64B24);
  static const redEarthDark = Color(0xFFE58B5E);
  static const fieldGreen = Color(0xFF5C8A38);
  static const fieldGreenDark = Color(0xFF8DBA63);
  static const turmeric = Color(0xFFE3A21A);
  static const turmericDark = Color(0xFFF0B840);
  static const ink = Color(0xFF2A2420);
  static const inkMuted = Color(0xFF6B5E52);
  static const inkDark = Color(0xFFF2ECE2);
  static const inkMutedDark = Color(0xFFB8AD9F);
}

ThemeData nelabeleTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;

  final scheme = ColorScheme.fromSeed(seedColor: Brand.redEarth, brightness: brightness).copyWith(
    primary: dark ? Brand.redEarthDark : Brand.redEarth,
    onPrimary: dark ? const Color(0xFF161D19) : Colors.white,
    secondary: dark ? Brand.fieldGreenDark : Brand.fieldGreen,
    onSecondary: dark ? const Color(0xFF161D19) : Colors.white,
    secondaryContainer: dark ? const Color(0xFF2F4A23) : const Color(0xFFE3EED3),
    onSecondaryContainer: dark ? const Color(0xFFD6EBC4) : const Color(0xFF24401A),
    tertiary: dark ? Brand.turmericDark : Brand.turmeric,
    onTertiary: dark ? const Color(0xFF161D19) : Brand.ink,
    surface: dark ? const Color(0xFF161D19) : const Color(0xFFFBF6EE),
    onSurface: dark ? Brand.inkDark : Brand.ink,
    onSurfaceVariant: dark ? Brand.inkMutedDark : Brand.inkMuted,
    surfaceContainerLowest: dark ? const Color(0xFF111713) : Colors.white,
    surfaceContainerLow: dark ? const Color(0xFF1F2822) : Colors.white,
    surfaceContainer: dark ? const Color(0xFF222C26) : const Color(0xFFF6EFE3),
    surfaceContainerHigh: dark ? const Color(0xFF26302A) : const Color(0xFFF1E9DC),
    surfaceContainerHighest: dark ? const Color(0xFF2B3630) : const Color(0xFFEDE3D3),
    outline: dark ? const Color(0xFF7D8A82) : const Color(0xFF9C8E80),
    outlineVariant: dark ? const Color(0xFF34403A) : const Color(0xFFE6DCCB),
  );

  final chipSelected = dark ? const Color(0xFF5A2A16) : const Color(0xFFF7DED1);
  final chipSelectedInk = dark ? const Color(0xFFF7DED1) : const Color(0xFF6E2A10);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamilyFallback: const ['NotoSansKannada'],
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
    ),
    chipTheme: ChipThemeData(
      selectedColor: chipSelected,
      checkmarkColor: chipSelectedInk,
      secondaryLabelStyle: TextStyle(color: chipSelectedInk, fontWeight: FontWeight.w500),
      side: BorderSide(color: scheme.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHigh,
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
  );
}
