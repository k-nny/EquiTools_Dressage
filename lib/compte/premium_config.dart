/// Réglages du plan Premium. Tout ce qu'il faut modifier pour faire évoluer
/// l'offre est ici.

/// Adresse des fonctions serveur (dossier api/ déployé sur Vercel).
const String urlApi = 'https://equi-tools-dressage.vercel.app/api';

/// Clés « publiques » du SDK RevenueCat (une par magasin), à copier depuis
/// le tableau de bord RevenueCat → Project settings → API keys.
/// Tant qu'elles valent A_REMPLACER, les achats intégrés sont désactivés.
const String cleRevenueCatAndroid = 'A_REMPLACER';
const String cleRevenueCatIos = 'A_REMPLACER';

/// Prix AFFICHÉS sur le web (Stripe). Dans les applications, ce sont les
/// prix des magasins qui s'affichent, automatiquement.
/// Ils doivent être identiques à ceux créés dans Stripe (le paiement réel
/// utilise les prix Stripe).
const String prixMensuel = '2,99 € / mois';
const String prixAnnuel = '24,99 € / an';

/// Ce qui est déjà inclus gratuitement (affiché dans la comparaison).
const List<String> avantagesGratuit = [
  'Visualiser et animer votre reprise sur la carrière',
  'Créer, nommer et organiser vos propres figures',
  'Carrières 20 × 60 m et 20 × 40 m',
  "Protocole PDF d'entraînement généré automatiquement",
  'Avec un compte gratuit : 3 reprises sauvegardées',
];

/// Ce que le plan Premium ajoute par rapport au plan gratuit.
/// ➜ À COMPLÉTER : ajoutez simplement une ligne de texte par avantage, ils
/// s'affichent automatiquement sur l'écran Premium. Tant que la liste est
/// vide, l'écran indique que les avantages arrivent bientôt.
const List<String> avantagesPremium = [
  'Aucune publicité',
  'Protocole PDF de compétition (coefficients, notes /10, observations)',
  'Jusqu\'à 10 reprises sauvegardées dans votre compte (au lieu de 3)',
];
