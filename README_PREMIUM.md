# Plan Premium (paiement Stripe) — mise en route

Le paiement utilise **Stripe** (pas d'abonnement mensuel à payer : Stripe
prend une commission sur chaque paiement). Le statut Premium est écrit dans
Firestore uniquement par le serveur (dossier `api/`, déployé par Vercel).

⚠️ Commence en **mode test** : aucun vrai argent n'est débité.

## 1. Règles Firestore
Console Firebase → Firestore Database → **Règles** : remplace tout par le
contenu de `firestore.rules` (nouveau : le bloc `abonnements` et la limite de 10 reprises pour les Premium), puis **Publier**.

## 2. Stripe
1. Crée un compte sur https://dashboard.stripe.com (reste en **mode test**,
   interrupteur « Mode test » en haut à droite).
2. **Catalogue de produits → Ajouter un produit** : nom « EquiTools Premium ».
   Ajoute **deux prix récurrents** : mensuel (ex. 2,99 €) et annuel
   (ex. 24,99 €). Ces prix doivent correspondre à ceux de
   `lib/compte/premium_config.dart`.
3. Sur chaque prix, copie son identifiant (`price_…`).
4. **Développeurs → Clés API** : copie la **clé secrète** de test (`sk_test_…`).
5. **Paramètres → Facturation → Portail client** : active-le (autorise
   l'annulation de l'abonnement).

## 3. Clé du serveur Firebase
Console Firebase → ⚙️ Paramètres du projet → **Comptes de service** →
**Générer une nouvelle clé privée** : un fichier `.json` est téléchargé.
Ne le mets JAMAIS dans le projet ni sur Git.

## 4. Variables d'environnement Vercel
Vercel → ton projet → **Settings → Environment Variables**, ajoute :

| Nom | Valeur |
|---|---|
| `STRIPE_SECRET_KEY` | `sk_test_…` |
| `STRIPE_PRICE_MENSUEL` | `price_…` du prix mensuel |
| `STRIPE_PRICE_ANNUEL` | `price_…` du prix annuel |
| `FIREBASE_SERVICE_ACCOUNT` | tout le contenu du fichier `.json` |
| `STRIPE_WEBHOOK_SECRET` | `whsec_…` (étape 5) |

## 5. Webhook Stripe
1. Stripe → **Développeurs → Webhooks → Ajouter un point de terminaison**.
2. URL : `https://equi-tools-dressage.vercel.app/api/stripe-webhook`
3. Événements : `checkout.session.completed`,
   `customer.subscription.created`, `customer.subscription.updated`,
   `customer.subscription.deleted`.
4. Copie la **clé de signature** (`whsec_…`) dans `STRIPE_WEBHOOK_SECRET`
   (Vercel), puis **redéploie** le projet.

## 6. Test
Connecte-toi, ouvre « Mon compte » → « Passer Premium » → choisis une
formule. Carte de test : `4242 4242 4242 4242`, date future, code au choix.
Au retour sur le site, l'écran Premium affiche « Vous êtes Premium ».

## 7. Passer en vrai
Active ton compte Stripe (identité + compte bancaire), repasse en mode
production, recrée les deux prix et le webhook, remplace les 4 variables
Stripe dans Vercel, redéploie.

## Ajouter les avantages Premium
Dans `lib/compte/premium_config.dart`, ajoute une ligne de texte par
avantage dans `avantagesPremium` : ils s'affichent sur l'écran Premium.
Déjà actifs pour les Premium : plus de publicité, et jusqu'à 10 reprises
sauvegardées.

## Limite importante
Ce paiement Stripe est prévu pour le **site web**. Dans une appli publiée sur
Google Play / App Store, les abonnements doivent passer par l'achat intégré
du magasin (règles des stores).
