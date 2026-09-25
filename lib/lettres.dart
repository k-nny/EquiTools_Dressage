import 'dart:ui';

class Lettres {
  Lettres._();

  /// Dimensions réelles de la carrière en mètres
  static const double width = 20.0;
  static const double length = 60.0;

  /// Positions des lettres en coordonnées réelles (mètres)
  ///
  /// x = largeur (0 → 20)
  /// y = longueur (0 → 60)
  static const Map<String, Offset> letters = {
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

  /// Retourne la position réelle d'une lettre
  static Offset getLetter(String letter) {
    final position = letters[letter];

    if (position == null) {
      throw ArgumentError('Lettre inconnue : $letter');
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
