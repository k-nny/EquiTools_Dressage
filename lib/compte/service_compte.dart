import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:reprise_dressage_app/compte/erreur_paiement.dart';
import 'package:reprise_dressage_app/compte/firebase_options.dart';
import 'package:reprise_dressage_app/compte/premium_config.dart';

/// Gestion du compte utilisateur (e-mail + mot de passe, via Firebase
/// Authentication). Si Firebase n'est pas configuré ou ne démarre pas,
/// [disponible] reste à false et le reste de l'application ignore
/// simplement les comptes : rien ne change pour l'utilisateur.
class ServiceCompte extends ChangeNotifier {
  ServiceCompte._();

  static final ServiceCompte instance = ServiceCompte._();

  bool _disponible = false;
  User? _utilisateur;

  /// true si Firebase est configuré et initialisé.
  bool get disponible => _disponible;

  User? get utilisateur => _utilisateur;
  bool get estConnecte => _utilisateur != null;
  String? get email => _utilisateur?.email;

  /// À appeler une fois, avant runApp. Ne lève jamais d'exception.
  Future<void> init() async {
    final options = optionsFirebase();
    if (options == null) return;
    try {
      await Firebase.initializeApp(options: options);
      _disponible = true;
      _utilisateur = FirebaseAuth.instance.currentUser;
      FirebaseAuth.instance.authStateChanges().listen((u) {
        _utilisateur = u;
        notifyListeners();
      });
    } catch (e) {
      _disponible = false;
      debugPrint('Firebase indisponible : $e');
    }
  }

  Future<void> inscrire(String email, String motDePasse) async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: motDePasse,
    );
  }

  Future<void> connecter(String email, String motDePasse) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: motDePasse,
    );
  }

  Future<void> deconnecter() => FirebaseAuth.instance.signOut();

  /// Supprime définitivement le compte et ses données (obligatoire dans les
  /// applications des magasins). Demande le mot de passe pour confirmer
  /// l'identité, puis appelle le serveur.
  Future<void> supprimerCompte(String motDePasse) async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw const ErreurPaiement('Connexion requise.');
    }
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: motDePasse),
      );
    } on FirebaseAuthException catch (e) {
      throw ErreurPaiement(messageErreur(e));
    }
    final jeton = await user.getIdToken(true);
    final http.Response r;
    try {
      r = await http
          .post(
            Uri.parse('$urlApi/supprimer-compte'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $jeton',
            },
            body: '{}',
          )
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw const ErreurPaiement(
        'Impossible de joindre le serveur. Vérifiez votre connexion.',
      );
    }
    if (r.statusCode != 200) {
      String message = 'La suppression a échoué. Réessayez.';
      try {
        final d = jsonDecode(r.body) as Map<String, dynamic>;
        message = (d['erreur'] as String?) ?? message;
      } catch (_) {}
      throw ErreurPaiement(message);
    }
    await FirebaseAuth.instance.signOut();
  }

  Future<void> motDePasseOublie(String email) =>
      FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());

  /// Message d'erreur lisible, en français.
  static String messageErreur(Object erreur) {
    if (erreur is FirebaseAuthException) {
      switch (erreur.code) {
        case 'invalid-email':
          return "L'adresse e-mail n'est pas valide.";
        case 'user-disabled':
          return 'Ce compte a été désactivé.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'E-mail ou mot de passe incorrect.';
        case 'email-already-in-use':
          return 'Un compte existe déjà avec cette adresse e-mail.';
        case 'weak-password':
          return 'Mot de passe trop faible (6 caractères minimum).';
        case 'too-many-requests':
          return 'Trop de tentatives. Réessayez dans quelques minutes.';
        case 'network-request-failed':
          return 'Pas de connexion. Vérifiez votre réseau.';
        case 'operation-not-allowed':
          return "La connexion par e-mail n'est pas activée.";
      }
    }
    return 'Une erreur est survenue. Réessayez.';
  }
}
