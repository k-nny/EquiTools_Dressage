import 'package:flutter/material.dart';

import 'package:reprise_dressage_app/lettres.dart';
import 'package:reprise_dressage_app/Figures/transition.dart';
import 'package:reprise_dressage_app/Figures/cercle.dart';
import 'package:reprise_dressage_app/Figures/demi_cercle.dart';
import 'package:reprise_dressage_app/Figures/demi_volte.dart';
import 'package:reprise_dressage_app/Figures/demi_volte_renversee.dart';
import 'package:reprise_dressage_app/Figures/serpentine.dart';

/// Grandes familles d'allures : c'est elle qui détermine la couleur de base
/// (🟢 pas, 🔵 trot, 🔴 galop) ; chaque variante en est une nuance.
enum Famille { pas, trot, galop, arret }

/// Toutes les allures disponibles. Pour en ajouter une : l'ajouter ici,
/// puis dans les quatre getters ci-dessous (famille, label, couleur,
/// vitesse) — rien d'autre à modifier dans l'application.
///
/// ⚠️ Les noms existants (pas, pasAllonge, trot, galop, arret) sont
/// enregistrés tels quels dans les reprises sauvegardées : ne pas les
/// renommer.
enum Allure {
  // Pas
  pas,
  pasLibre,
  pasMoyen,
  pasAllonge,
  pasRassemble,
  // Trot
  trot,
  trotMoyen,
  trotAllonge,
  trotRassemble,
  passage,
  piaffer,
  // Galop
  galop,
  galopMoyen,
  galopAllonge,
  galopRassemble,
  // Arrêt
  arret,
}

extension AllureStyle on Allure {
  Famille get famille => switch (this) {
    Allure.pas ||
    Allure.pasLibre ||
    Allure.pasMoyen ||
    Allure.pasAllonge ||
    Allure.pasRassemble => Famille.pas,
    Allure.trot ||
    Allure.trotMoyen ||
    Allure.trotAllonge ||
    Allure.trotRassemble ||
    Allure.passage ||
    Allure.piaffer => Famille.trot,
    Allure.galop ||
    Allure.galopMoyen ||
    Allure.galopAllonge ||
    Allure.galopRassemble => Famille.galop,
    Allure.arret => Famille.arret,
  };

  /// Chaque allure a une couleur UNIQUE (l'animation retrouve l'allure à
  /// partir de la couleur d'une transition) : nuances de vert, de bleu ou
  /// de rouge selon la famille.
  Color get couleur => switch (this) {
    Allure.pas => const Color(0xFFE57373),
    Allure.pasLibre => const Color(0xFFFF8A65),
    Allure.pasMoyen => const Color(0xFFFFB74D),
    Allure.pasAllonge => const Color(0xFFFFD54F),
    Allure.pasRassemble => const Color(0xFFFBC02D),
    Allure.trot => const Color(0xFFC0CA33),
    Allure.trotMoyen => const Color(0xFF8BC34A),
    Allure.trotAllonge => const Color(0xFF4CAF50),
    Allure.trotRassemble => const Color(0xFF26A69A),
    Allure.passage => const Color(0xFF00ACC1),
    Allure.piaffer => const Color(0xFF00838F),
    Allure.galop => const Color(0xFF42A5F5),
    Allure.galopMoyen => const Color(0xFF1E88E5),
    Allure.galopAllonge => const Color(0xFF1565C0),
    Allure.galopRassemble => const Color(0xFF3949AB),
    Allure.arret => const Color(0xFFF44336),
  };

  String get label => switch (this) {
    Allure.pas => 'Pas',
    Allure.pasLibre => 'Pas libre',
    Allure.pasMoyen => 'Pas moyen',
    Allure.pasAllonge => 'Pas allongé',
    Allure.pasRassemble => 'Pas rassemblé',
    Allure.trot => 'Trot de travail',
    Allure.trotMoyen => 'Trot moyen',
    Allure.trotAllonge => 'Trot allongé',
    Allure.trotRassemble => 'Trot rassemblé',
    Allure.passage => 'Passage',
    Allure.piaffer => 'Piaffer',
    Allure.galop => 'Galop de travail',
    Allure.galopMoyen => 'Galop moyen',
    Allure.galopAllonge => 'Galop allongé',
    Allure.galopRassemble => 'Galop rassemblé',
    Allure.arret => 'Arrêt',
  };

  /// Vitesse approximative, en mètres par seconde, utilisée pour la durée
  /// de l'animation du cheval (valeurs indicatives, pas des mesures réelles).
  double get vitesseMetresParSeconde => switch (this) {
    Allure.pas => 1.6,
    Allure.pasLibre => 1.6,
    Allure.pasMoyen => 1.6,
    Allure.pasAllonge => 1.9,
    Allure.pasRassemble => 1.4,
    Allure.trot => 3.2,
    Allure.trotMoyen => 3.8,
    Allure.trotAllonge => 4.5,
    Allure.trotRassemble => 2.6,
    Allure.passage => 1.8,
    Allure.piaffer => 0.6,
    Allure.galop => 5.5,
    Allure.galopMoyen => 6.2,
    Allure.galopAllonge => 7.0,
    Allure.galopRassemble => 4.5,
    Allure.arret => 0,
  };
}

extension FamilleStyle on Famille {
  String get label => switch (this) {
    Famille.pas => 'Pas',
    Famille.trot => 'Trot',
    Famille.galop => 'Galop',
    Famille.arret => 'Arrêt',
  };

  /// Couleur de base de la famille (celle de l'allure "standard").
  Color get couleur => switch (this) {
    Famille.pas => Allure.pas.couleur,
    Famille.trot => Allure.trot.couleur,
    Famille.galop => Allure.galop.couleur,
    Famille.arret => Allure.arret.couleur,
  };

  List<Allure> get allures =>
      Allure.values.where((a) => a.famille == this).toList();
}

/// Un repère sur la carrière : soit une lettre officielle, soit un point
/// donné directement en mètres (utile pour les coins, qui n'ont pas de
/// lettre attitrée).
class Repere {
  final String? letter;
  final Offset? metres;

  const Repere.lettre(String this.letter) : metres = null;
  const Repere.point(Offset this.metres) : letter = null;

  /// Texte lisible du repère : la lettre, ou les coordonnées en mètres
  /// pour un point libre (ex. un coin de la carrière).
  String get libelle {
    final l = letter;
    if (l != null) return l;
    final m = metres!;
    String n(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return '${n(m.dx)} m ; ${n(m.dy)} m';
  }

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

  // --- Informations conservées pour générer le protocole (PDF) ----------
  // Ces getters ne changent rien au tracé ni à la sauvegarde : ils exposent
  // seulement ce que chaque mouvement sait déjà de lui-même.

  /// Nom donné par l'utilisateur (c'est ce nom qui doit apparaître dans le
  /// protocole, jamais le nom technique de la figure).
  String get nomPersonnalise => description;

  /// Nom technique interne de la figure ("Ligne", "Cercle"...).
  String get typeFigure;

  /// Repère (lettre) de départ du mouvement.
  String? get positionDepart;

  /// Repère (lettre) d'arrivée, ou null s'il n'a pas de lettre (ex. fin
  /// d'un demi-cercle).
  String? get positionArrivee;

  /// Paramètres propres à la figure (diamètre, nombre de boucles...).
  Map<String, Object?> get parametres => const {};

  /// Copie de ce mouvement avec une allure, un nom ou des transitions
  /// différents (les mouvements sont immuables). Pour [MvtArret], l'allure
  /// et les transitions sont ignorées (un arrêt n'en a pas).
  Mouvement copyWith({
    Allure? allure,
    String? description,
    List<Transition>? transitions,
  });

  Path buildPath(double w, double h);

  /// true si ce mouvement peut être tracé dans la carrière actuelle : toutes
  /// ses lettres existent (une reprise créée en 20×60 peut référencer des
  /// lettres absentes en 20×40 : L, I, R, S, P, V) ET son tracé reste
  /// entièrement à l'intérieur de la carrière.
  bool get estCompatibleCarriereActuelle {
    try {
      // Échelle identique sur les deux axes (10 px par mètre), pour que la
      // vérification géométrique ci-dessous soit juste.
      final w = 10 * Lettres.width;
      final h = 10 * Lettres.length;
      final bounds = buildPath(w, h).getBounds();
      const marge = 1.0;
      return bounds.left >= -marge &&
          bounds.top >= -marge &&
          bounds.right <= w + marge &&
          bounds.bottom <= h + marge;
    } catch (_) {
      return false;
    }
  }

  /// Comme [buildPath], mais ne lève jamais d'exception : renvoie null si
  /// ce mouvement n'est pas compatible avec la carrière actuelle, plutôt
  /// que de faire planter l'app.
  Path? buildPathSafe(double w, double h) {
    try {
      return buildPath(w, h);
    } catch (_) {
      return null;
    }
  }

  void paintOn(Canvas canvas, double w, double h, {double strokeWidth = 4}) {
    final path = buildPathSafe(w, h);
    if (path == null) return; // indiqué dans le bandeau du mouvement
    Transition.draw(
      canvas,
      path,
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
  String get typeFigure => 'Ligne';

  @override
  String? get positionDepart => points.first.libelle;

  @override
  String? get positionArrivee => points.last.libelle;

  @override
  Map<String, Object?> get parametres => {
    'points': points.map((p) => p.libelle).toList(),
  };

  @override
  Mouvement copyWith({
    Allure? allure,
    String? description,
    List<Transition>? transitions,
  }) => MvtLigne(
    points,
    allure ?? this.allure,
    description ?? this.description,
    transitions: transitions ?? this.transitions,
  );

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
  String get typeFigure => 'Cercle';

  @override
  String? get positionDepart => letter;

  @override
  String? get positionArrivee => letter;

  @override
  Map<String, Object?> get parametres => {
    'diametre': diameter,
    'prevLetter': prevLetter,
  };

  @override
  Mouvement copyWith({
    Allure? allure,
    String? description,
    List<Transition>? transitions,
  }) => MvtCercle(
    letter,
    diameter,
    allure ?? this.allure,
    description ?? this.description,
    prevLetter: prevLetter,
    transitions: transitions ?? this.transitions,
  );

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
  String get typeFigure => 'Demi-cercle';

  @override
  String? get positionDepart => fromLetter;

  @override
  String? get positionArrivee => null;

  @override
  Map<String, Object?> get parametres => {
    'diametre': diameter,
    'prevLetter': prevLetter,
  };

  @override
  Mouvement copyWith({
    Allure? allure,
    String? description,
    List<Transition>? transitions,
  }) => MvtDemiCercle(
    prevLetter,
    fromLetter,
    diameter,
    allure ?? this.allure,
    description ?? this.description,
    transitions: transitions ?? this.transitions,
  );

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
  String get typeFigure => 'Demi-volte';

  @override
  String? get positionDepart => fromLetter;

  @override
  String? get positionArrivee => toLetter;

  @override
  Map<String, Object?> get parametres => {'diametre': diameter};

  @override
  Mouvement copyWith({
    Allure? allure,
    String? description,
    List<Transition>? transitions,
  }) => MvtDemiVolte(
    fromLetter,
    toLetter,
    diameter,
    allure ?? this.allure,
    description ?? this.description,
    transitions: transitions ?? this.transitions,
  );

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
  String get typeFigure => 'Demi-volte renversée';

  @override
  String? get positionDepart => fromLetter;

  @override
  String? get positionArrivee => toLetter;

  @override
  Map<String, Object?> get parametres => {'diametre': diameter};

  @override
  Mouvement copyWith({
    Allure? allure,
    String? description,
    List<Transition>? transitions,
  }) => MvtDemiVolteRenversee(
    fromLetter,
    toLetter,
    diameter,
    allure ?? this.allure,
    description ?? this.description,
    transitions: transitions ?? this.transitions,
  );

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
  String get typeFigure => 'Serpentine';

  @override
  String? get positionDepart => fromLetter;

  @override
  String? get positionArrivee => toLetter;

  @override
  Map<String, Object?> get parametres => {
    'nbBoucles': nbLoop,
    'prevLetter': prevLetter,
    'premiereBoucleInversee': premiereBoucleInversee,
    'rayonBoucle': rayonBoucle,
  };

  @override
  Mouvement copyWith({
    Allure? allure,
    String? description,
    List<Transition>? transitions,
  }) => MvtSerpentine(
    fromLetter,
    toLetter,
    nbLoop,
    allure ?? this.allure,
    description ?? this.description,
    prevLetter: prevLetter,
    premiereBoucleInversee: premiereBoucleInversee,
    rayonBoucle: rayonBoucle,
    transitions: transitions ?? this.transitions,
  );

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
  String get typeFigure => 'Arrêt';

  @override
  String? get positionDepart => letter;

  @override
  String? get positionArrivee => letter;

  @override
  Mouvement copyWith({
    Allure? allure,
    String? description,
    List<Transition>? transitions,
  }) => MvtArret(letter, description ?? this.description);

  @override
  Path buildPath(double w, double h) {
    final c = Lettres.letterToPixels(letter, w, h);
    return Path()..addOval(Rect.fromCircle(center: c, radius: 1));
  }

  @override
  void paintOn(Canvas canvas, double w, double h, {double strokeWidth = 4}) {
    final position = Lettres.getLetterOrNull(letter);
    if (position == null) return; // lettre absente de cette carrière
    final c = Lettres.toPixels(position, w, h);
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
