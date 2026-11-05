import 'dart:io' show Platform;

import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:reprise_dressage_app/compte/achats/offre_achat.dart';
import 'package:reprise_dressage_app/compte/erreur_paiement.dart';
import 'package:reprise_dressage_app/compte/premium_config.dart';

/// Version Android / iOS : abonnements via Google Play / App Store, gérés
/// par RevenueCat. Le statut Premium lui-même est écrit dans Firestore par
/// le serveur (webhook RevenueCat) : ici on ne fait que lancer l'achat.
class AchatsIntegres {
  AchatsIntegres._();

  static bool _pret = false;

  /// true si RevenueCat est configuré (clés renseignées) et démarré.
  static bool get disponible => _pret;

  static Future<void> init() async {
    final cle = Platform.isAndroid
        ? cleRevenueCatAndroid
        : Platform.isIOS
        ? cleRevenueCatIos
        : null;
    if (cle == null || cle == 'A_REMPLACER') return;
    try {
      await Purchases.configure(PurchasesConfiguration(cle));
      _pret = true;
    } catch (_) {
      _pret = false;
    }
  }

  /// Associe les achats au compte (l'identifiant RevenueCat = l'identifiant
  /// Firebase de l'utilisateur, que le serveur retrouve dans le webhook).
  static Future<void> connecter(String uid) async {
    if (!_pret) return;
    try {
      await Purchases.logIn(uid);
    } catch (_) {}
  }

  static Future<void> deconnecter() async {
    if (!_pret) return;
    try {
      await Purchases.logOut();
    } catch (_) {}
  }

  static String _titre(Package p) => switch (p.packageType) {
    PackageType.monthly => 'Mensuel',
    PackageType.annual => 'Annuel',
    PackageType.weekly => 'Hebdomadaire',
    PackageType.twoMonth => '2 mois',
    PackageType.threeMonth => '3 mois',
    PackageType.sixMonth => '6 mois',
    PackageType.lifetime => 'À vie',
    _ => p.storeProduct.title,
  };

  static Future<List<OffreAchat>> offres() async {
    if (!_pret) return const [];
    final offerings = await Purchases.getOfferings();
    final paquets = offerings.current?.availablePackages ?? const <Package>[];
    return [
      for (final p in paquets)
        OffreAchat(
          id: p.identifier,
          titre: _titre(p),
          prix: p.storeProduct.priceString,
          brut: p,
        ),
    ];
  }

  static Future<void> acheter(OffreAchat offre) async {
    final paquet = offre.brut;
    if (paquet is! Package) return;
    try {
      await Purchases.purchasePackage(paquet);
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) return;
      if (code == PurchasesErrorCode.productAlreadyPurchasedError) {
        throw const ErreurPaiement(
          'Cet abonnement est déjà actif sur votre compte de store. '
          'Essayez « Restaurer mes achats ».',
        );
      }
      throw const ErreurPaiement("L'achat n'a pas abouti. Réessayez.");
    }
  }

  static Future<void> restaurer() async {
    if (!_pret) return;
    try {
      await Purchases.restorePurchases();
    } catch (_) {
      throw const ErreurPaiement('Impossible de restaurer les achats.');
    }
  }
}
