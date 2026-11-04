import 'package:reprise_dressage_app/Figures/transition.dart';
import 'package:reprise_dressage_app/reprise.dart';

/// Une étape de la reprise telle qu'elle doit apparaître dans le protocole
/// (PDF) : toutes les informations nécessaires sont conservées ici, pour
/// que le protocole soit généré automatiquement — l'utilisateur n'a jamais
/// à le recopier à la main.
class EtapeReprise {
  /// Position dans la reprise (1 = premier mouvement).
  final int ordre;

  /// Repère de départ et d'arrivée (lettres). L'arrivée peut être null.
  final String? positionDepart;
  final String? positionArrivee;

  final Allure allure;

  /// Nom technique interne de la figure ("Cercle", "Serpentine"...).
  final String figure;

  /// Nom donné par l'utilisateur : c'est celui-ci qui est affiché dans le
  /// protocole (ex. "E → Cercle de détente").
  final String nomPersonnalise;

  /// Paramètres éventuels (diamètre, nombre de boucles...).
  final Map<String, Object?> parametres;

  /// Changements d'allure en cours de mouvement.
  final List<Transition> transitions;

  const EtapeReprise({
    required this.ordre,
    required this.positionDepart,
    required this.positionArrivee,
    required this.allure,
    required this.figure,
    required this.nomPersonnalise,
    this.parametres = const {},
    this.transitions = const [],
  });

  factory EtapeReprise.depuis(Mouvement m, int ordre) => EtapeReprise(
    ordre: ordre,
    positionDepart: m.positionDepart,
    positionArrivee: m.positionArrivee,
    allure: m.allure,
    figure: m.typeFigure,
    nomPersonnalise: m.nomPersonnalise,
    parametres: m.parametres,
    transitions: m.transitions,
  );

  /// Repère affiché dans la colonne de gauche du protocole.
  String get repere => positionDepart ?? '–';

  /// Ligne du protocole : « lettre → nom donné par l'utilisateur ».
  String get ligneProtocole => '$repere → $nomPersonnalise';
}

/// Convertit la reprise en cours en étapes de protocole, dans l'ordre.
List<EtapeReprise> etapesDeLaReprise(List<Mouvement> mouvements) => [
  for (var i = 0; i < mouvements.length; i++)
    EtapeReprise.depuis(mouvements[i], i + 1),
];
