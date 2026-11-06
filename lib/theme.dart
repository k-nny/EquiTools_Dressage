import 'package:flutter/material.dart';

/// Palette du logo EquiTools : noir charbon, or, ivoire.
/// Purement visuel : aucune couleur d'allure n'est modifiée ici (elles
/// restent définies dans reprise.dart).
///
/// Règle d'usage : l'or décore (bordures, filets, sélection) ; pour du
/// petit texte sur fond clair on utilise [orFonce] (contraste suffisant).
class Palette {
  Palette._();

  /// Noir du logo : couleur principale (boutons, titres, texte).
  static const Color charbon = Color(0xFF1D2225);

  /// Or du logo : accent décoratif.
  static const Color or = Color(0xFFB38328);

  /// Or assombri : texte doré sur fond clair, icônes.
  static const Color orFonce = Color(0xFF8F6A1D);

  /// Or clair du logo : reflets, éléments sélectionnés.
  static const Color orClair = Color(0xFFD9B780);

  /// Teinte très pâle d'or : fonds de zones, panneau autour de la carrière.
  static const Color orPale = Color(0xFFF3EAD6);

  /// Fond de l'application.
  static const Color ivoire = Color(0xFFFBF8F2);

  /// Surface de la carrière (claire, pour bien faire ressortir les allures).
  static const Color sol = Color(0xFFFFFDF8);

  static const Color carte = Colors.white;

  /// Filets et bordures discrètes.
  static const Color traitFin = Color(0xFFE7DFCE);
}

ThemeData construireTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: Palette.or,
    brightness: Brightness.light,
  );
  final scheme = base.copyWith(
    surface: Palette.ivoire,
    primary: Palette.charbon,
    onPrimary: Colors.white,
    primaryContainer: Palette.orPale,
    onPrimaryContainer: Palette.charbon,
    secondary: Palette.or,
    onSecondary: Colors.white,
    onSurface: Palette.charbon,
    outline: Palette.orFonce,
    outlineVariant: Palette.traitFin,
    surfaceTint: Colors.transparent,
  );

  const stade = StadiumBorder();

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.ivoire,
    appBarTheme: const AppBarTheme(
      backgroundColor: Palette.ivoire,
      foregroundColor: Palette.charbon,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w800,
        color: Palette.charbon,
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
        side: BorderSide(color: Palette.or.withValues(alpha: 0.8)),
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
              ? Palette.charbon
              : Palette.charbon.withValues(alpha: 0.75),
        ),
        side: WidgetStatePropertyAll(
          BorderSide(color: Palette.or.withValues(alpha: 0.6)),
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
        color: Palette.charbon,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Palette.ivoire,
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
      fillColor: Palette.ivoire,
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
        borderSide: const BorderSide(color: Palette.or, width: 2),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
