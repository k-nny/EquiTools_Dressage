import 'package:reprise_dressage_app/Figures/transition.dart';
import 'package:reprise_dressage_app/reprise.dart';

/// Les deux présentations possibles du protocole PDF.
///  - entraînement : numéro, repère, mouvement, allure (gratuit) ;
///  - compétition : les mêmes colonnes + coefficient, note /10 et
///    observations à remplir à la main (réservé aux comptes Premium).
enum ModeleProtocole { entrainement, competition }

/// Informations libres saisies au moment de l'export. Rien n'est
/// obligatoire, rien n'est prérempli : on n'invente aucune information.
class InfosProtocole {
  final String reprise;
  final String niveau;
  final String cavalier;
  final String cheval;

  const InfosProtocole({
    this.reprise = '',
    this.niveau = '',
    this.cavalier = '',
    this.cheval = '',
  });

  bool get estVide =>
      reprise.isEmpty && niveau.isEmpty && cavalier.isEmpty && cheval.isEmpty;
}

/// Un changement d'allure en cours de figure (« Galop de travail à X »).
class ChangementAllure {
  final String texte;
  final Allure? allure;

  const ChangementAllure(this.texte, this.allure);
}

/// Une ligne du protocole = UNE figure complète (jamais coupée entre deux
/// pages), avec ses éventuels changements d'allure.
class LigneProtocole {
  final int numero;

  /// Repère affiché : « A » ou « A → X » quand l'arrivée est différente.
  final String repere;

  /// Nom donné par l'utilisateur (jamais le nom technique de la figure).
  final String nom;

  /// Précision issue du tracé (« Cercle de 20 m »), ou null si elle
  /// n'apporte rien par rapport au nom.
  final String? detail;

  final Allure allure;
  final List<ChangementAllure> changements;

  const LigneProtocole({
    required this.numero,
    required this.repere,
    required this.nom,
    required this.detail,
    required this.allure,
    required this.changements,
  });
}

/// Prépare les lignes du protocole à partir de la reprise, sans la
/// modifier. Toutes les informations viennent des mouvements eux-mêmes.
List<LigneProtocole> lignesDuProtocole(List<Mouvement> mouvements) => [
  for (var i = 0; i < mouvements.length; i++)
    _ligne(mouvements[i], i + 1),
];

LigneProtocole _ligne(Mouvement m, int numero) {
  final depart = m.positionDepart;
  final arrivee = m.positionArrivee;
  final String repere;
  if (depart == null) {
    repere = '–';
  } else if (arrivee != null && arrivee != depart) {
    repere = '$depart → $arrivee';
  } else {
    repere = depart;
  }

  final nom = m.nomPersonnalise;
  var detail = _detailFigure(m);
  if (detail != null && _normaliser(detail) == _normaliser(nom)) {
    detail = null;
  }

  return LigneProtocole(
    numero: numero,
    repere: repere,
    nom: nom,
    detail: detail,
    allure: m.allure,
    changements: [for (final t in m.transitions) _changement(t)],
  );
}

String _normaliser(String s) => s.trim().toLowerCase();

ChangementAllure _changement(Transition t) {
  final String lieu;
  if (t.letter != null) {
    lieu = 'à ${t.letter}';
  } else {
    lieu = 'sur la ligne ${t.lineFrom}–${t.lineTo}';
  }
  Allure? allure;
  for (final a in Allure.values) {
    if (a.couleur == t.colorAfter) {
      allure = a;
      break;
    }
  }
  final texte = allure != null
      ? '${allure.label} $lieu'
      : "Changement d'allure $lieu";
  return ChangementAllure(texte, allure);
}

String _metres(Object? v) {
  if (v is num) {
    if (v == v.roundToDouble()) return '${v.round()} m';
    return '${v.toStringAsFixed(1).replaceAll('.', ',')} m';
  }
  return '';
}

/// Description du tracé d'après les paramètres de la figure.
String? _detailFigure(Mouvement m) {
  final p = m.parametres;
  switch (m.typeFigure) {
    case 'Cercle':
    case 'Demi-cercle':
    case 'Demi-volte':
    case 'Demi-volte renversée':
      final d = _metres(p['diametre']);
      return d.isEmpty ? m.typeFigure : '${m.typeFigure} de $d';
    case 'Serpentine':
      final n = p['nbBoucles'];
      if (n is int) return 'Serpentine de $n boucle${n > 1 ? 's' : ''}';
      return 'Serpentine';
    case 'Ligne':
      final pts = p['points'];
      if (pts is List && pts.length > 2) return pts.join(' → ');
      return null;
    default:
      return null;
  }
}
