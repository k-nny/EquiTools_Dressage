import 'package:flutter/material.dart';

/// Palette « écurie » : tons chauds (cuir, sable, crème) et un vert prairie.
/// Purement visuel : aucune couleur d'allure n'est modifiée ici.
class Palette {
  Palette._();

  static const Color cuir = Color(0xFF9C4A2F);
  static const Color brunFonce = Color(0xFF4E342E);
  static const Color creme = Color(0xFFFFF8EE);
  static const Color sable = Color(0xFFF3E2BE);
  static const Color bordureSable = Color(0xFF7A5230);
  static const Color prairie = Color(0xFFE4ECD8);
  static const Color carte = Colors.white;
  static const Color traitFin = Color(0xFFE8D9C5);
}

ThemeData construireTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: Palette.cuir,
    brightness: Brightness.light,
  );
  final scheme = base.copyWith(
    surface: Palette.creme,
    primary: Palette.cuir,
    onSurface: Palette.brunFonce,
    outlineVariant: Palette.traitFin,
  );

  const stade = StadiumBorder();

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.creme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Palette.creme,
      foregroundColor: Palette.brunFonce,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w800,
        color: Palette.brunFonce,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: stade,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: stade,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        side: BorderSide(color: Palette.cuir.withValues(alpha: 0.45)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: stade,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primaryContainer
              : Palette.carte,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Palette.brunFonce
              : Palette.brunFonce.withValues(alpha: 0.75),
        ),
        side: WidgetStatePropertyAll(
          BorderSide(color: Palette.cuir.withValues(alpha: 0.35)),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Palette.carte,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Palette.brunFonce,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Palette.creme,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Palette.carte,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Palette.creme,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Palette.traitFin),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Palette.traitFin),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Palette.cuir, width: 2),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
