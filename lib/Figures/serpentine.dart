import 'package:flutter/material.dart';
import 'package:reprise_dressage_app/Figures/transition.dart';

class Serpentine extends CustomPainter {
  final Offset fromLetter;
  final Offset toLetter;
  final double nbLoop;
  final Color color;
  final double w;
  final double h;
  final List<Transition> transitions;
  final bool premiereBoucleInversee;
  final double? rayonBoucle;

  Serpentine(
    this.fromLetter,
    this.toLetter,
    this.nbLoop,
    this.color,
    this.w,
    this.h, [
    this.transitions = const [],
    this.premiereBoucleInversee = false,
    this.rayonBoucle,
  ]);

  /// Construit le tracé complet de la serpentine (en pixels), indépendamment
  /// du rendu. Réutilisé à la fois pour la peinture statique et pour
  /// l'animation du cheval.
  ///
  /// Chaque boucle est un crochet (demi-cercle) qui touche UNE SEULE piste,
  /// relié au suivant — qui touche l'autre piste — par un doublé (segment
  /// droit, perpendiculaire au sens du parcours). L'espace disponible est
  /// divisé à parts égales entre les boucles ; chaque crochet est centré
  /// au milieu de sa part, le doublé comble le reste de chaque côté (y
  /// compris en entrée depuis [fromLetter] et en sortie vers [toLetter]).
  ///
  /// [rayonBoucle] fixe le rayon des crochets, en pixels. Par défaut, la
  /// longueur totale divisée par deux fois le nombre de boucles — c'est ce
  /// rayon qui, combiné à la largeur de la carrière, détermine s'il reste
  /// un écart entre deux crochets (comblé par un doublé) : avec 3 boucles
  /// sur 60 m par exemple, le rayon (10 m) est pile la demi-largeur, donc
  /// aucun écart ; avec 4 boucles, le rayon (7,5 m) laisse un écart de 5 m.
  ///
  /// Le tracé démarre toujours exactement sur [fromLetter]. La PREMIÈRE
  /// boucle touche par défaut le grand côté K-V-E-S-H ; passez
  /// [premiereBoucleInversee] à true pour qu'elle touche l'autre côté
  /// (F-P-B-R-M) en premier.
  static Path buildPath(
    Offset fromLetter,
    Offset toLetter,
    double nbLoop,
    double w,
    double h, [
    bool premiereBoucleInversee = false,
    double? rayonBoucle,
  ]) {
    final path = Path()..moveTo(fromLetter.dx, fromLetter.dy);
    if (nbLoop <= 0) {
      path.lineTo(toLetter.dx, toLetter.dy);
      return path;
    }

    // true = la serpentine progresse le long de la longueur (axe Y),
    // comme la classique "serpentine A-C" ; false = le long de la largeur.
    final bool vertical = !(fromLetter.dx == w || fromLetter.dx == 0);
    final double largeurPerp = vertical ? w : h;

    final double longueurTotale = vertical
        ? (toLetter.dy - fromLetter.dy).abs()
        : (toLetter.dx - fromLetter.dx).abs();
    if (longueurTotale <= 0) {
      path.lineTo(toLetter.dx, toLetter.dy);
      return path;
    }

    final double signe = vertical
        ? (toLetter.dy >= fromLetter.dy ? 1.0 : -1.0)
        : (toLetter.dx >= fromLetter.dx ? 1.0 : -1.0);

    final double espacement = longueurTotale / nbLoop;
    final double radius = rayonBoucle ?? espacement / 2;

    // Point à une distance [longueur] de fromLetter le long du parcours, et
    // à une position [perp] perpendiculaire (0 = la piste touchée quand
    // premiereBoucleInversee vaut true, largeurPerp = l'autre piste).
    Offset pointA(double longueur, double perp) {
      return vertical
          ? Offset(perp, fromLetter.dy + signe * longueur)
          : Offset(fromLetter.dx + signe * longueur, perp);
    }

    bool versZero = premiereBoucleInversee;

    for (var i = 0; i < nbLoop; i++) {
      final double centreLongueur = espacement * (i + 0.5);
      final double centrePerp = versZero ? radius : largeurPerp - radius;

      // Doublé jusqu'au début du crochet.
      final debut = pointA(centreLongueur - radius, centrePerp);
      path.lineTo(debut.dx, debut.dy);

      // Le crochet lui-même : demi-cercle qui touche une seule piste.
      final centre = pointA(centreLongueur, centrePerp);
      final double angleDebut;
      final double sweep;
      if (vertical) {
        angleDebut = -signe * (3.14 / 2);
        sweep = versZero ? -signe * 3.14 : signe * 3.14;
      } else {
        angleDebut = signe > 0 ? 3.14 : 0;
        sweep = versZero ? signe * 3.14 : -signe * 3.14;
      }
      path.arcTo(
        Rect.fromCircle(center: centre, radius: radius),
        angleDebut,
        sweep,
        false,
      );

      versZero = !versZero;
    }

    // Doublé final jusqu'à l'arrivée.
    path.lineTo(toLetter.dx, toLetter.dy);

    return path;
  }

  /// Calcule la valeur de [premiereBoucleInversee] à utiliser pour que la
  /// 1ère boucle touche le côté OPPOSÉ à celui d'où l'on arrive : si on
  /// arrive de K (grand côté K-V-E-S-H), le 1er crochet doit toucher le
  /// côté de F (grand côté F-P-B-R-M), pas celui de K.
  static bool inverseePourArriverDe(
    Offset prevLetter,
    Offset fromLetter,
    Offset toLetter,
    double w,
  ) {
    final bool vertical = !(fromLetter.dx == w || fromLetter.dx == 0);
    return vertical
        ? prevLetter.dx > fromLetter.dx
        : prevLetter.dy > fromLetter.dy;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildPath(
      fromLetter,
      toLetter,
      nbLoop,
      w,
      h,
      premiereBoucleInversee,
      rayonBoucle,
    );
    Transition.draw(canvas, path, color, transitions, w, h);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
