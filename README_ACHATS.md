# Achats intégrés Google Play / App Store (via RevenueCat)

Dans une appli publiée sur les magasins, l'abonnement DOIT être acheté via
Google Play / l'App Store (pas Stripe). RevenueCat s'occupe de la partie
technique ; sur le site web, Stripe continue de fonctionner. Tant que les clés
`cleRevenueCatAndroid` / `cleRevenueCatIos` valent `A_REMPLACER`, les achats
intégrés sont désactivés et rien ne change.

## Ce qu'il faut avoir
- Un compte **Google Play Console** (frais uniques) et/ou **Apple Developer
  Program** (abonnement annuel).
- Un compte gratuit sur https://www.revenuecat.com
- L'appli publiée au moins en test interne (Google) / TestFlight (Apple).

## 1. Créer les abonnements dans les magasins
**Google Play Console** → ton appli → Monétiser → **Abonnements** → créer
`premium_mensuel` et `premium_annuel` (avec leurs prix et périodes).
**App Store Connect** → ton appli → **Abonnements** → créer un groupe
« Premium » avec les deux abonnements.

## 2. RevenueCat
1. Nouveau projet « EquiTools ».
2. **Apps** : ajoute l'appli Android (nom du paquet = `applicationId` dans
   `android/app/build.gradle`) et l'appli iOS (Bundle ID).
3. Suis les assistants pour relier chaque magasin (identifiants de service
   Google, clé App Store Connect).
4. **Products** : ajoute les 4 produits (2 par magasin).
5. **Entitlements** : crée `premium` et rattache les produits.
6. **Offerings** : dans l'offre « default », crée deux packages :
   **Monthly** (mensuel) et **Annual** (annuel).
7. **API keys** : copie la clé SDK Android (`goog_…`) et iOS (`appl_…`)
   dans `lib/compte/premium_config.dart`.

## 3. Prévenir le serveur (webhook)
RevenueCat → Integrations → **Webhooks** → ajouter :
- URL : `https://equi-tools-dressage.vercel.app/api/revenuecat-webhook`
- **Authorization header** : une phrase secrète de ton choix.
Puis dans Vercel (Settings → Environment Variables) ajoute
`REVENUECAT_WEBHOOK_AUTH` avec exactement la même phrase, et redéploie.

## 4. Côté appli
- iOS : dans Xcode, onglet *Signing & Capabilities* → **+ Capability** →
  *In-App Purchase*.
- `flutter pub get`, puis construis l'appli (Android : `flutter build appbundle`).

## 5. Tester
Utilise un compte de test (Google : « testeurs de licence » ; Apple : compte
Sandbox). Après l'achat, le statut Premium passe tout seul en quelques
secondes (pub supprimée, 10 reprises).

## Obligations des magasins (déjà gérées)
- Bouton « Restaurer mes achats » et prix / renouvellement affichés ✔
- Liens vers conditions de vente et confidentialité sur l'écran Premium ✔
- Suppression du compte depuis l'appli ✔ (et page web
  `suppression-compte.html`, à indiquer dans la fiche Google Play).
