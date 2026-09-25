import 'package:flutter/material.dart';

import 'package:reprise_dressage_app/lettres.dart';
import 'package:reprise_dressage_app/Figures/transition.dart';
import 'package:reprise_dressage_app/Figures/cercle.dart';
import 'package:reprise_dressage_app/Figures/demi_cercle.dart';
import 'package:reprise_dressage_app/Figures/demi_volte.dart';
import 'package:reprise_dressage_app/Figures/demi_volte_renversee.dart';
import 'package:reprise_dressage_app/Figures/serpentine.dart';

/// Les trois allures utilisées dans la reprise, plus l'arrêt.
enum Allure { pas, pasAllonge, trot, galop, arret }

extension AllureStyle on Allure {
  Color get couleur => switch (this) {
    Allure.pas => const Color(0xFFFFC107), // ambre
    Allure.pasAllonge => const Color(0xFFFF8F00), // ambre foncé
    Allure.trot => const Color(0xFF1E88E5), // bleu
    Allure.galop => const Color(0xFF8E24AA), // violet
    Allure.arret => const Color(0xFFE53935), // rouge
  };

  String get label => switch (this) {
    Allure.pas => 'Pas',
    Allure.pasAllonge => 'Pas allongé',
    Allure.trot => 'Trot',
    Allure.galop => 'Galop',
    Allure.arret => 'Arrêt',
  };

  /// Vitesse approximative, en mètres par seconde, utilisée pour la durée
  /// de l'animation du cheval (valeurs indicatives, pas des mesures réelles).
  double get vitesseMetresParSeconde => switch (this) {
    Allure.pas => 1.6,
    Allure.pasAllonge => 1.9,
    Allure.trot => 3.2,
    Allure.galop => 5.5,
    Allure.arret => 0,
  };
}

/// Un repère sur la carrière : soit une lettre officielle, soit un point
/// donné directement en mètres (utile pour les coins, qui n'ont pas de
/// lettre attitrée).
class Repere {
  final String? letter;
  final Offset? metres;

  const Repere.lettre(String this.letter) : metres = null;
  const Repere.point(Offset this.metres) : letter = null;

  Offset toPixels(double w, double h) {
    final m = metres;
    if (m != null) return Lettres.toPixels(m, w, h);
    return Lettres.letterToPixels(letter!, w, h);
  }
}

/// Un mouvement de la reprise : une figure géométrique à parcourir, avec son
/// allure et une courte description. Chaque sous-classe sait construire son
/// propre [Path] en pixels (réutilisé pour le tracé statique ET pour animer
/// le cheval), ce qui évite de dupliquer la géométrie des figures.
abstract class Mouvement {
  final String description;
  final Allure allure;

  const Mouvement(this.description, this.allure);

  List<Transition> get transitions;

  Path buildPath(double w, double h);

  void paintOn(Canvas canvas, double w, double h, {double strokeWidth = 4}) {
    Transition.draw(
      canvas,
      buildPath(w, h),
      allure.couleur,
      transitions,
      w,
      h,
      strokeWidth: strokeWidth,
    );
  }
}

/// Si [a] et [b] sont chacun sur un mur de la carrière (piste) mais des murs
/// différents (un petit côté, un grand côté), renvoie le point du coin par
/// lequel il faut passer pour longer la piste plutôt que couper à travers
/// le coin. Renvoie null si aucun coin n'est concerné : même mur (ligne le
/// long de la piste), murs opposés (vraie diagonale, comme un changement de
/// main), ou l'un des deux points est au centre (X, I, L...).
Offset? _coinEntre(Offset a, Offset b, double w, double h) {
  final aVert = a.dx == 0 || a.dx == w;
  final aHoriz = a.dy == 0 || a.dy == h;
  final bVert = b.dx == 0 || b.dx == w;
  final bHoriz = b.dy == 0 || b.dy == h;

  if (aVert && !aHoriz && bHoriz && !bVert) return Offset(a.dx, b.dy);
  if (aHoriz && !aVert && bVert && !bHoriz) return Offset(b.dx, a.dy);
  return null;
}

class MvtLigne extends Mouvement {
  /// Les points du tracé, dans l'ordre (au moins 2). Entre deux points
  /// consécutifs situés sur des murs différents, le coin de la carrière est
  /// automatiquement inséré (voir [_coinEntre]) — inutile de le préciser à
  /// la main.
  final List<Repere> points;
  @override
  final List<Transition> transitions;

  const MvtLigne(
    this.points,
    Allure allure,
    String description, {
    this.transitions = const [],
  }) : super(description, allure);

  @override
  Path buildPath(double w, double h) {
    final pixels = points.map((p) => p.toPixels(w, h)).toList();
    final path = Path()..moveTo(pixels.first.dx, pixels.first.dy);
    for (var i = 1; i < pixels.length; i++) {
      final prev = pixels[i - 1];
      final next = pixels[i];
      final coin = _coinEntre(prev, next, w, h);
      if (coin != null) path.lineTo(coin.dx, coin.dy);
      path.lineTo(next.dx, next.dy);
    }
    return path;
  }
}

class MvtCercle extends Mouvement {
  final String letter;
  final double diameter;

  /// La lettre d'où l'on arrive, pour que le cercle parte dans le bon sens
  /// (main droite/gauche) en prolongeant la direction d'arrivée. Optionnel :
  /// sans elle, le cercle est tracé dans le sens horaire par défaut.
  final String? prevLetter;
  @override
  final List<Transition> transitions;

  const MvtCercle(
    this.letter,
    this.diameter,
    Allure allure,
    String description, {
    this.prevLetter,
    this.transitions = const [],
  }) : super(description, allure);

  @override
  Path buildPath(double w, double h) {
    final c = Lettres.letterToPixels(letter, w, h);
    final prev = prevLetter == null
        ? null
        : Lettres.letterToPixels(prevLetter!, w, h);
    return Cercle.buildPath(c, diameter, w, h, prev);
  }
}

class MvtDemiCercle extends Mouvement {
  final String prevLetter;
  final String fromLetter;
  final double diameter;
  @override
  final List<Transition> transitions;

  const MvtDemiCercle(
    this.prevLetter,
    this.fromLetter,
    this.diameter,
    Allure allure,
    String description, {
    this.transitions = const [],
  }) : super(description, allure);

  @override
  Path buildPath(double w, double h) {
    final prev = Lettres.letterToPixels(prevLetter, w, h);
    final from = Lettres.letterToPixels(fromLetter, w, h);
    return DemiCercle.buildPath(prev, from, diameter, w, h);
  }
}

class MvtDemiVolte extends Mouvement {
  final String fromLetter;
  final String toLetter;
  final double diameter;
  @override
  final List<Transition> transitions;

  const MvtDemiVolte(
    this.fromLetter,
    this.toLetter,
    this.diameter,
    Allure allure,
    String description, {
    this.transitions = const [],
  }) : super(description, allure);

  @override
  Path buildPath(double w, double h) {
    final from = Lettres.letterToPixels(fromLetter, w, h);
    final to = Lettres.letterToPixels(toLetter, w, h);
    return DemiVolte.buildPath(from, to, diameter, w, h);
  }
}

class MvtDemiVolteRenversee extends Mouvement {
  final String fromLetter;
  final String toLetter;
  final double diameter;
  @override
  final List<Transition> transitions;

  const MvtDemiVolteRenversee(
    this.fromLetter,
    this.toLetter,
    this.diameter,
    Allure allure,
    String description, {
    this.transitions = const [],
  }) : super(description, allure);

  @override
  Path buildPath(double w, double h) {
    final from = Lettres.letterToPixels(fromLetter, w, h);
    final to = Lettres.letterToPixels(toLetter, w, h);
    return DemiVolteRenversee.buildPath(from, to, diameter, w, h);
  }
}

class MvtSerpentine extends Mouvement {
  final String fromLetter;
  final String toLetter;
  final double nbLoop;

  /// La lettre d'où l'on arrive : la 1ère boucle s'écarte automatiquement
  /// du côté opposé (ex. arrivée de K → la boucle touche le côté de F).
  /// Ignorée si [premiereBoucleInversee] est fourni explicitement.
  final String? prevLetter;

  /// Force le sens de la 1ère boucle, en dernier recours si la déduction
  /// depuis [prevLetter] ne convient pas. Laissez à null pour la déduction
  /// automatique.
  final bool? premiereBoucleInversee;

  /// Rayon des crochets, en mètres. Laissez à null pour la valeur par
  /// défaut (longueur totale ÷ 2× le nombre de boucles — c'est ce qui fait
  /// que 3 boucles sur 60 m touchent pile la piste sans doublé, alors que
  /// 4 ou 5 boucles laissent un écart comblé par un doublé).
  final double? rayonBoucle;
  @override
  final List<Transition> transitions;

  const MvtSerpentine(
    this.fromLetter,
    this.toLetter,
    this.nbLoop,
    Allure allure,
    String description, {
    this.prevLetter,
    this.premiereBoucleInversee,
    this.rayonBoucle,
    this.transitions = const [],
  }) : super(description, allure);

  @override
  Path buildPath(double w, double h) {
    final from = Lettres.letterToPixels(fromLetter, w, h);
    final to = Lettres.letterToPixels(toLetter, w, h);

    final bool inversee;
    if (premiereBoucleInversee != null) {
      inversee = premiereBoucleInversee!;
    } else if (prevLetter != null) {
      final prev = Lettres.letterToPixels(prevLetter!, w, h);
      inversee = Serpentine.inverseePourArriverDe(prev, from, to, w);
    } else {
      inversee = false;
    }

    final double? rayonPx = rayonBoucle == null
        ? null
        : rayonBoucle! / Lettres.width * w;

    return Serpentine.buildPath(from, to, nbLoop, w, h, inversee, rayonPx);
  }
}

/// Un arrêt : ce n'est pas un tracé mais un point où le cheval s'immobilise
/// (halte, immobilité, salut).
class MvtArret extends Mouvement {
  final String letter;

  const MvtArret(this.letter, String description)
    : super(description, Allure.arret);

  @override
  List<Transition> get transitions => const [];

  @override
  Path buildPath(double w, double h) {
    final c = Lettres.letterToPixels(letter, w, h);
    return Path()..addOval(Rect.fromCircle(center: c, radius: 1));
  }

  @override
  void paintOn(Canvas canvas, double w, double h, {double strokeWidth = 4}) {
    final c = Lettres.letterToPixels(letter, w, h);
    canvas.drawCircle(c, strokeWidth + 3, Paint()..color = allure.couleur);
  }
}

/// "Club 3 Grand Prix" (FFE), rectangle 60×20 m, retranscrite à partir des
/// codes de mouvements de la feuille de barème officielle (les colonnes
/// "idées directrices" du juge ne sont pas reprises, seuls les codes
/// lettres/figures le sont). Deux simplifications assumées :
///  - les transitions "au pas puis arrêt" (fig. 1 et 22) sont représentées
///    par un simple arrêt : la feuille ne donne pas de lettre précise pour
///    le début de la transition ;
///  - les départs au galop "entre A et F" / "entre A et K" (fig. 10 et 15)
///    sont représentés par tout le segment coloré au galop, pour la même
///    raison (pas de lettre précise donnée).
final List<Mouvement> repriseClub3GrandPrix = [
  const MvtLigne([Repere.lettre('A'), Repere.lettre('X')], Allure.trot,
      'Entrée au trot de travail'),
  const MvtArret('X', 'Transition au pas moyen puis arrêt - Immobilité - Salut'),
  const MvtLigne([Repere.lettre('X'), Repere.lettre('C')], Allure.trot,
      'Départ progressif au trot de travail'),
  const MvtLigne(
    [Repere.lettre('C'), Repere.lettre('M'), Repere.lettre('R')],
    Allure.trot,
    'Piste à main droite, trot de travail',
  ),
  const MvtCercle('R', 15, Allure.trot, 'Cercle de 15 m', prevLetter: 'M'),
  const MvtLigne([Repere.lettre('R'), Repere.lettre('B')], Allure.trot,
      'Trot de travail'),
  const MvtLigne([Repere.lettre('B'), Repere.lettre('E')], Allure.trot,
      'Doubler dans la largeur'),
  const MvtLigne([Repere.lettre('E'), Repere.lettre('V')], Allure.trot,
      'Piste à main gauche, trot de travail'),
  const MvtCercle('V', 15, Allure.trot, 'Cercle de 15 m', prevLetter: 'E'),
  const MvtLigne(
    [Repere.lettre('V'), Repere.lettre('K'), Repere.lettre('A')],
    Allure.trot,
    'Trot de travail',
  ),
  const MvtSerpentine(
    'A',
    'C',
    4,
    Allure.trot,
    'Serpentine de 4 boucles',
    prevLetter: 'K',
  ),
  const MvtLigne([Repere.lettre('C'), Repere.lettre('M')], Allure.pas,
      'Transition au pas moyen'),
  const MvtLigne(
    [Repere.lettre('M'), Repere.lettre('R'), Repere.lettre('V')],
    Allure.pasAllonge,
    'Pas allongé',
  ),
  const MvtLigne([Repere.lettre('V'), Repere.lettre('K')], Allure.pas,
      'Pas moyen'),
  const MvtLigne([Repere.lettre('K'), Repere.lettre('A')], Allure.trot,
      'Trot de travail'),
  const MvtLigne(
    [Repere.lettre('A'), Repere.lettre('F')],
    Allure.galop,
    'Départ au galop de travail à gauche (entre A et F)',
  ),
  const MvtLigne([Repere.lettre('F'), Repere.lettre('B')], Allure.galop,
      'Galop de travail (galoper droit)'),
  const MvtCercle('B', 20, Allure.galop, 'Cercle de 20 m', prevLetter: 'F'),
  const MvtLigne([Repere.lettre('B'), Repere.lettre('R')], Allure.galop,
      'Galop de travail'),
  MvtDemiCercle(
    'B',
    'R',
    20,
    Allure.galop,
    'Demi-cercle de 20 m, transition au trot vers G',
    transitions: [Transition.surLettre('G', Allure.trot.couleur)],
  ),
  const MvtLigne([Repere.lettre('S'), Repere.lettre('E')], Allure.trot,
      'Trot de travail'),
  const MvtLigne(
    [Repere.lettre('E'), Repere.lettre('F'), Repere.lettre('A')],
    Allure.trot,
    'Changement de main au trot de travail',
  ),
  const MvtLigne(
    [Repere.lettre('A'), Repere.lettre('K')],
    Allure.galop,
    'Départ au galop de travail à droite (entre A et K)',
  ),
  const MvtLigne([Repere.lettre('K'), Repere.lettre('E')], Allure.galop,
      'Galop de travail (galoper droit)'),
  const MvtCercle('E', 20, Allure.galop, 'Cercle de 20 m', prevLetter: 'K'),
  const MvtLigne([Repere.lettre('E'), Repere.lettre('S')], Allure.galop,
      'Galop de travail'),
  MvtDemiCercle(
    'E',
    'S',
    20,
    Allure.galop,
    'Demi-cercle de 20 m, transition au trot vers G',
    transitions: [Transition.surLettre('G', Allure.trot.couleur)],
  ),
  const MvtLigne([Repere.lettre('R'), Repere.lettre('B')], Allure.trot,
      'Trot de travail'),
  const MvtLigne(
    [Repere.lettre('B'), Repere.lettre('K'), Repere.lettre('A')],
    Allure.trot,
    'Changement de main au trot de travail',
  ),
  const MvtLigne([Repere.lettre('A'), Repere.lettre('I')], Allure.trot,
      'Doubler, trot de travail'),
  const MvtArret('I', 'Transition au pas moyen puis arrêt - Immobilité - Salut'),
];
