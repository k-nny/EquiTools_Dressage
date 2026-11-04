import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Valeur par défaut : tant qu'elle n'est pas remplacée par les vraies
/// valeurs de votre projet Firebase, les comptes sont désactivés et
/// l'application fonctionne exactement comme avant (aucun bouton de compte
/// n'est affiché). Voir README_COMPTE.md.
const String _aRemplacer = 'A_REMPLACER';

/// Application Web (console Firebase → Paramètres du projet → Vos
/// applications → Web → « Configuration du SDK »).
const FirebaseOptions _web = FirebaseOptions(
  apiKey: "AIzaSyBsSj1yJix68WceZs2YD25mPi3s8pmgxnc",
  appId: "equitools---dressage-4e247.firebaseapp.com",
  messagingSenderId: "equitools---dressage-4e247",
  projectId: "equitools---dressage-4e247.firebasestorage.app",
  authDomain: "909299718058",
  storageBucket: "1:909299718058:web:576caa217cdaf2f7cf3dd3",
);

/// Application Android (optionnel tant que l'appli n'est pas publiée).
const FirebaseOptions _android = FirebaseOptions(
  apiKey: _aRemplacer,
  appId: _aRemplacer,
  messagingSenderId: _aRemplacer,
  projectId: _aRemplacer,
  storageBucket: _aRemplacer,
);

/// Application iOS (optionnel tant que l'appli n'est pas publiée).
const FirebaseOptions _ios = FirebaseOptions(
  apiKey: _aRemplacer,
  appId: _aRemplacer,
  messagingSenderId: _aRemplacer,
  projectId: _aRemplacer,
  storageBucket: _aRemplacer,
  iosBundleId: _aRemplacer,
);

/// Options Firebase de la plateforme actuelle, ou null si elles ne sont pas
/// (encore) renseignées — dans ce cas les comptes sont simplement
/// indisponibles.
FirebaseOptions? optionsFirebase() {
  final options = kIsWeb
      ? _web
      : switch (defaultTargetPlatform) {
          TargetPlatform.android => _android,
          TargetPlatform.iOS => _ios,
          _ => null,
        };
  if (options == null || options.apiKey == _aRemplacer) return null;
  return options;
}
