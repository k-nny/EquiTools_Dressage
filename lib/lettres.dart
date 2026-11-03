import 'dart:ui';

/// Les deux tailles de carrière standard du dressage. La largeur est
/// toujours 20 m ; seule la longueur (et donc l'emplacement des lettres)
/// change.
enum TailleCarriere { grande, petite }

extension TailleCarriereInfo on TailleCarriere {
  double get longueur => this == TailleCarriere.grande ? 60 : 40;

  String get label =>
      this == TailleCarriere.grande ? '20 × 60 m' : '20 × 40 m';
}

class Lettres {
  Lettres._();

  /// Taille de carrière actuellement utilisée par toute l'application.
  /// Changez cette valeur (puis redessinez) pour basculer de carrière —
  /// voir le sélecteur dans ecran.dart.
  static TailleCarriere taille = TailleCarriere.grande;

  /// Dimensions réelles de la carrière actuelle, en mètres.
  static double get width => 20.0;
  static double get length => taille.longueur;

  /// Positions des lettres en coordonnées réelles (mètres) pour la taille
  /// de carrière actuelle.
  ///
  /// x = largeur (0 → 20), y = longueur (0 → length)
  static Map<String, Offset> get letters =>
      taille == TailleCarriere.grande ? _lettresGrande : _lettresPetite;

  static const Map<String, Offset> _lettresGrande = {
    // Centre
    'A': Offset(10, 0),
    'D': Offset(10, 6),
    'L': Offset(10, 18),
    'X': Offset(10, 30),
    'I': Offset(10, 42),
    'G': Offset(10, 54),
    'C': Offset(10, 60),

    // Côté gauche
    'F': Offset(0, 6),
    'P': Offset(0, 18),
    'B': Offset(0, 30),
    'R': Offset(0, 42),
    'M': Offset(0, 54),

    // Côté droit
    'K': Offset(20, 6),
    'V': Offset(20, 18),
    'E': Offset(20, 30),
    'S': Offset(20, 42),
    'H': Offset(20, 54),
  };

  /// Carrière 20×40 m : mêmes conventions de côté que la grande carrière
  /// (lettres K/E/H sur le côté x=20, F/B/M sur le côté x=0), pour que
  /// toute la géométrie des figures (qui se base sur ces côtés, pas sur
  /// les noms de lettres) continue de fonctionner sans changement.
  static const Map<String, Offset> _lettresPetite = {
    // Centre
    'A': Offset(10, 0),
    'D': Offset(10, 6),
    'L': Offset(10, 13),
    'X': Offset(10, 20),
    'I': Offset(10, 27),
    'G': Offset(10, 34),
    'C': Offset(10, 40),

    // Côté gauche
    'F': Offset(0, 6),
    'P': Offset(0, 13),
    'B': Offset(0, 20),
    'R': Offset(0, 27),
    'M': Offset(0, 34),

    // Côté droit
    'K': Offset(20, 6),
    'V': Offset(20, 13),
    'E': Offset(20, 20),
    'S': Offset(20, 27),
    'H': Offset(20, 34),
  };

  /// Retourne la position réelle d'une lettre, ou null si cette lettre
  static Offset? getLetterOrNull(String letter) => letters[letter];

  /// Retourne la position réelle d'une lettre.
  static Offset getLetter(String letter) {
    final position = letters[letter];

    if (position == null) {
      throw ArgumentError(
        "Lettre '$letter' inexistante en carrière ${taille.label}",
      );
    }

    return position;
  }

  /// Convertit une position réelle (mètres)
  /// en position écran (pixels)
  static Offset toPixels(
    Offset meters,
    double canvasWidth,
    double canvasHeight,
  ) {
    return Offset(
      meters.dx / width * canvasWidth,
      meters.dy / length * canvasHeight,
    );
  }

  /// Raccourci : lettre -> pixels
  static Offset letterToPixels(
    String letter,
    double canvasWidth,
    double canvasHeight,
  ) {
    return toPixels(getLetter(letter), canvasWidth, canvasHeight);
  }
}
