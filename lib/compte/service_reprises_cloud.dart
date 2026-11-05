import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:reprise_dressage_app/reprise.dart';
import 'package:reprise_dressage_app/reprise_storage.dart';

/// Une reprise sauvegardée dans le compte de l'utilisateur.
class RepriseSauvegardee {
  final String id;
  final String nom;
  final DateTime maj;

  /// Les mouvements, au format JSON de la sauvegarde locale (stockés sous
  /// forme de texte : simple, et sans limite de structure côté Firestore).
  final String mouvementsJson;

  const RepriseSauvegardee({
    required this.id,
    required this.nom,
    required this.maj,
    required this.mouvementsJson,
  });

  factory RepriseSauvegardee.depuis({
    required String id,
    required String nom,
    required List<Mouvement> mouvements,
  }) => RepriseSauvegardee(
    id: id,
    nom: nom,
    maj: DateTime.now(),
    mouvementsJson: jsonEncode(mouvementsVersJson(mouvements)),
  );

  factory RepriseSauvegardee.fromMap(Map<String, dynamic> m) =>
      RepriseSauvegardee(
        id: m['id'] as String,
        nom: m['nom'] as String,
        maj: DateTime.fromMillisecondsSinceEpoch((m['maj'] as num).toInt()),
        mouvementsJson: m['mouvements'] as String,
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'nom': nom,
    'maj': maj.millisecondsSinceEpoch,
    'mouvements': mouvementsJson,
  };

  List<Mouvement> mouvements() =>
      mouvementsDepuisJson(jsonDecode(mouvementsJson) as List);

  int get nbMouvements => (jsonDecode(mouvementsJson) as List).length;
}

/// Lecture / écriture des reprises du compte dans Firestore.
///
/// Toutes les reprises d'un utilisateur (3 au maximum) tiennent dans UN
/// seul document `users/{uid}` : charger = 1 lecture, sauvegarder =
/// 1 écriture, ce qui garde l'usage très en dessous des quotas gratuits.
/// La limite de 3 est aussi imposée côté serveur (voir firestore.rules).
class ServiceReprisesCloud {
  ServiceReprisesCloud._();

  /// Nombre maximum de reprises sauvegardées : 3 en gratuit, 10 en Premium
  /// (limite aussi imposée côté serveur, voir firestore.rules).
  static const int maxGratuit = 3;
  static const int maxPremium = 10;

  static int maxPour({required bool premium}) =>
      premium ? maxPremium : maxGratuit;

  static DocumentReference<Map<String, dynamic>> _document() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Utilisateur non connecté');
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  static Future<List<RepriseSauvegardee>> charger() async {
    final snap = await _document().get();
    final brut = snap.data()?['reprises'];
    if (brut is! List) return [];
    final resultat = <RepriseSauvegardee>[];
    for (final e in brut) {
      try {
        resultat.add(
          RepriseSauvegardee.fromMap(Map<String, dynamic>.from(e as Map)),
        );
      } catch (_) {
        // entrée illisible : ignorée plutôt que de tout bloquer
      }
    }
    return resultat;
  }

  static Future<void> enregistrer(List<RepriseSauvegardee> liste) async {
    if (liste.length > maxPremium) {
      throw StateError('Maximum $maxPremium reprises');
    }
    await _document().set({'reprises': liste.map((r) => r.toMap()).toList()});
  }
}
