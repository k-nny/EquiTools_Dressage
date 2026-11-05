import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'package:reprise_dressage_app/compte/achats/achats.dart';
import 'package:reprise_dressage_app/compte/erreur_paiement.dart';
import 'package:reprise_dressage_app/compte/premium_config.dart';
import 'package:reprise_dressage_app/compte/service_compte.dart';

export 'package:reprise_dressage_app/compte/erreur_paiement.dart';

/// Statut Premium de l'utilisateur connecté.
///
/// Le statut est écrit UNIQUEMENT par le serveur (webhook Stripe) dans
/// `abonnements/{uid}` ; l'appli ne fait que le lire, en direct : dès que
/// le paiement est validé, l'écran passe tout seul en Premium.
class ServicePremium extends ChangeNotifier {
  ServicePremium._();

  static final ServicePremium instance = ServicePremium._();

  bool _premium = false;
  bool _annulationPrevue = false;
  DateTime? _jusqua;
  String? _source; // 'stripe' (web) ou 'store' (Google Play / App Store)
  String? _uid;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _abonnement;

  bool get estPremium => _premium;

  /// true si l'abonnement a été résilié mais court encore jusqu'à sa fin.
  bool get annulationPrevue => _annulationPrevue;

  /// Fin de la période en cours (si connue).
  DateTime? get jusqua => _jusqua;

  /// true sur Android / iOS : l'achat passe par le magasin (obligatoire
  /// dans les applications publiées). Sur le web, c'est Stripe.
  bool get achatIntegre => AchatsIntegres.disponible;

  /// À appeler une fois, après ServiceCompte.init().
  void init() {
    ServiceCompte.instance.addListener(_surChangementCompte);
    _surChangementCompte();
  }

  void _surChangementCompte() {
    final compte = ServiceCompte.instance;
    final uid = compte.disponible ? compte.utilisateur?.uid : null;
    if (uid == _uid) return;
    _uid = uid;

    _abonnement?.cancel();
    _abonnement = null;
    _premium = false;
    _annulationPrevue = false;
    _jusqua = null;
    _source = null;
    notifyListeners();

    if (uid == null) {
      AchatsIntegres.deconnecter();
      return;
    }
    AchatsIntegres.connecter(uid);
    _abonnement = FirebaseFirestore.instance
        .collection('abonnements')
        .doc(uid)
        .snapshots()
        .listen(
          (snap) {
            final d = snap.data();
            _premium = d?['actif'] == true;
            _annulationPrevue = d?['annulationPrevue'] == true;
            final j = d?['jusqua'];
            _jusqua = j is num
                ? DateTime.fromMillisecondsSinceEpoch(j.toInt())
                : null;
            _source = d?['source'] as String?;
            notifyListeners();
          },
          onError: (_) {
            _premium = false;
            notifyListeners();
          },
        );
  }

  Future<String> _appeler(String chemin, Map<String, Object?> corps) async {
    final jeton = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (jeton == null) throw const ErreurPaiement('Connexion requise.');
    final http.Response r;
    try {
      r = await http
          .post(
            Uri.parse('$urlApi/$chemin'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $jeton',
            },
            body: jsonEncode(corps),
          )
          .timeout(const Duration(seconds: 25));
    } catch (_) {
      throw const ErreurPaiement(
        'Impossible de joindre le service de paiement. Vérifiez votre connexion.',
      );
    }
    Map<String, dynamic> donnees = {};
    try {
      donnees = jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {}
    if (r.statusCode != 200) {
      throw ErreurPaiement(
        (donnees['erreur'] as String?) ??
            "Le paiement n'est pas disponible pour le moment.",
      );
    }
    final url = donnees['url'];
    if (url is! String) {
      throw const ErreurPaiement('Réponse inattendue du service de paiement.');
    }
    return url;
  }

  /// Ouvre la page de paiement sécurisée Stripe. [plan] : 'mensuel' ou
  /// 'annuel'. Sur le web, la page remplace l'onglet courant ; l'utilisateur
  /// revient sur l'appli après le paiement.
  Future<void> ouvrirPaiement(String plan) async {
    final url = await _appeler('creer-checkout', {'plan': plan});
    await launchUrl(Uri.parse(url), webOnlyWindowName: '_self');
  }

  /// Ouvre la gestion de l'abonnement (carte, factures, résiliation) : le
  /// portail Stripe, ou les abonnements du magasin si l'achat vient du
  /// magasin.
  Future<void> ouvrirGestion() async {
    if (_source == 'store') {
      final url = defaultTargetPlatform == TargetPlatform.iOS
          ? 'https://apps.apple.com/account/subscriptions'
          : 'https://play.google.com/store/account/subscriptions';
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return;
    }
    final url = await _appeler('portail', {});
    await launchUrl(Uri.parse(url), webOnlyWindowName: '_self');
  }

  // --- Achats intégrés (Android / iOS) -----------------------------------

  Future<List<OffreAchat>> offresIntegrees() => AchatsIntegres.offres();

  /// Lance l'achat dans le magasin. Le statut Premium se met à jour tout
  /// seul quelques secondes plus tard (confirmation du serveur).
  Future<void> acheterIntegre(OffreAchat offre) => AchatsIntegres.acheter(offre);

  Future<void> restaurerAchats() => AchatsIntegres.restaurer();
}
