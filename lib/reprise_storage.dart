import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reprise_dressage_app/reprise.dart';
import 'package:reprise_dressage_app/Figures/transition.dart';

/// Sauvegarde/charge la reprise de l'utilisateur *localement, sur cet
/// appareil* (SharedPreferences). Aucun compte, aucun serveur : si
/// l'utilisateur change de téléphone ou réinstalle l'app, ses figures ne le
/// suivent pas. Voir la discussion produit pour une vraie synchronisation
/// multi-appareils (comptes + backend).
class ReprisesStorage {
  ReprisesStorage._();

  static const _cleReprise = 'reprise_utilisateur_v1';
  static const _cleTutorielVu = 'tutoriel_vu_v1';

  /// Renvoie la reprise sauvegardée, ou null si rien n'a encore été
  /// sauvegardé (ou si les données sont illisibles/corrompues).
  static Future<List<Mouvement>?> chargerReprise() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cleReprise);
    if (raw == null) return null;
    try {
      final liste = jsonDecode(raw) as List;
      return liste
          .map((e) => _mouvementFromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> sauvegarderReprise(List<Mouvement> mouvements) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(mouvements.map(_mouvementToJson).toList());
    await prefs.setString(_cleReprise, raw);
  }

  /// Efface la reprise sauvegardée sur cet appareil (pour repartir de
  /// l'exemple par défaut).
  static Future<void> effacerReprise() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cleReprise);
  }

  static Future<bool> tutorielDejaVu() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cleTutorielVu) ?? false;
  }

  static Future<void> marquerTutorielVu() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cleTutorielVu, true);
  }
}

// --- Sérialisation ---------------------------------------------------

Map<String, dynamic> _basePartagee(Mouvement m) => {
  'allure': m.allure.name,
  'description': m.description,
  'transitions': m.transitions.map(_transitionToJson).toList(),
};

Map<String, dynamic> _mouvementToJson(Mouvement m) {
  if (m is MvtArret) {
    return {
      'type': 'arret',
      'letter': m.letter,
      'description': m.description,
    };
  }
  final base = _basePartagee(m);
  switch (m) {
    case MvtLigne():
      return {
        ...base,
        'type': 'ligne',
        'points': m.points.map(_repereToJson).toList(),
      };
    case MvtCercle():
      return {
        ...base,
        'type': 'cercle',
        'letter': m.letter,
        'diameter': m.diameter,
        'prevLetter': m.prevLetter,
      };
    case MvtDemiCercle():
      return {
        ...base,
        'type': 'demiCercle',
        'prevLetter': m.prevLetter,
        'fromLetter': m.fromLetter,
        'diameter': m.diameter,
      };
    case MvtDemiVolte():
      return {
        ...base,
        'type': 'demiVolte',
        'fromLetter': m.fromLetter,
        'toLetter': m.toLetter,
        'diameter': m.diameter,
      };
    case MvtDemiVolteRenversee():
      return {
        ...base,
        'type': 'demiVolteRenversee',
        'fromLetter': m.fromLetter,
        'toLetter': m.toLetter,
        'diameter': m.diameter,
      };
    case MvtSerpentine():
      return {
        ...base,
        'type': 'serpentine',
        'fromLetter': m.fromLetter,
        'toLetter': m.toLetter,
        'nbLoop': m.nbLoop,
        'prevLetter': m.prevLetter,
        'premiereBoucleInversee': m.premiereBoucleInversee,
      };
    default:
      throw StateError('Type de mouvement non géré : ${m.runtimeType}');
  }
}

Mouvement _mouvementFromJson(Map<String, dynamic> json) {
  final type = json['type'] as String;

  if (type == 'arret') {
    return MvtArret(json['letter'] as String, json['description'] as String);
  }

  final allure = Allure.values.byName(json['allure'] as String);
  final description = json['description'] as String;
  final transitions = (json['transitions'] as List)
      .map((e) => _transitionFromJson(e as Map<String, dynamic>))
      .toList();

  switch (type) {
    case 'ligne':
      final points = (json['points'] as List)
          .map((e) => _repereFromJson(e as Map<String, dynamic>))
          .toList();
      return MvtLigne(points, allure, description, transitions: transitions);
    case 'cercle':
      return MvtCercle(
        json['letter'] as String,
        (json['diameter'] as num).toDouble(),
        allure,
        description,
        prevLetter: json['prevLetter'] as String?,
        transitions: transitions,
      );
    case 'demiCercle':
      return MvtDemiCercle(
        json['prevLetter'] as String,
        json['fromLetter'] as String,
        (json['diameter'] as num).toDouble(),
        allure,
        description,
        transitions: transitions,
      );
    case 'demiVolte':
      return MvtDemiVolte(
        json['fromLetter'] as String,
        json['toLetter'] as String,
        (json['diameter'] as num).toDouble(),
        allure,
        description,
        transitions: transitions,
      );
    case 'demiVolteRenversee':
      return MvtDemiVolteRenversee(
        json['fromLetter'] as String,
        json['toLetter'] as String,
        (json['diameter'] as num).toDouble(),
        allure,
        description,
        transitions: transitions,
      );
    case 'serpentine':
      return MvtSerpentine(
        json['fromLetter'] as String,
        json['toLetter'] as String,
        (json['nbLoop'] as num).toDouble(),
        allure,
        description,
        prevLetter: json['prevLetter'] as String?,
        premiereBoucleInversee: json['premiereBoucleInversee'] as bool?,
        transitions: transitions,
      );
    default:
      throw StateError('Type de mouvement non géré : $type');
  }
}

Map<String, dynamic> _repereToJson(Repere r) {
  final m = r.metres;
  if (m != null) return {'x': m.dx, 'y': m.dy};
  return {'letter': r.letter};
}

Repere _repereFromJson(Map<String, dynamic> json) {
  if (json.containsKey('letter')) {
    return Repere.lettre(json['letter'] as String);
  }
  return Repere.point(
    Offset((json['x'] as num).toDouble(), (json['y'] as num).toDouble()),
  );
}

Map<String, dynamic> _transitionToJson(Transition t) {
  final color = t.colorAfter.toARGB32();
  if (t.letter != null) return {'letter': t.letter, 'color': color};
  return {'lineFrom': t.lineFrom, 'lineTo': t.lineTo, 'color': color};
}

Transition _transitionFromJson(Map<String, dynamic> json) {
  final color = Color(json['color'] as int);
  if (json.containsKey('letter')) {
    return Transition.surLettre(json['letter'] as String, color);
  }
  return Transition.surLigne(
    json['lineFrom'] as String,
    json['lineTo'] as String,
    color,
  );
}

// --- Accès public à la sérialisation (sauvegarde dans le compte) ---------

/// Convertit une liste de mouvements en JSON (même format que la
/// sauvegarde locale).
List<Map<String, dynamic>> mouvementsVersJson(List<Mouvement> mouvements) =>
    mouvements.map(_mouvementToJson).toList();

/// Opération inverse de [mouvementsVersJson].
List<Mouvement> mouvementsDepuisJson(List liste) => liste
    .map((e) => _mouvementFromJson(Map<String, dynamic>.from(e as Map)))
    .toList();
