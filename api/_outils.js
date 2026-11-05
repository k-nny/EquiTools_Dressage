// Outils partagés par les fonctions serveur. Le préfixe « _ » empêche
// Vercel d'en faire une route publique.
const admin = require('firebase-admin');
const Stripe = require('stripe');

const SITE = process.env.SITE_URL || 'https://equi-tools-dressage.vercel.app';

function initAdmin() {
  if (!admin.apps.length) {
    const cle = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    admin.initializeApp({ credential: admin.credential.cert(cle) });
  }
  return admin;
}

function stripe() {
  return new Stripe(process.env.STRIPE_SECRET_KEY);
}

// Vérifie le jeton de connexion Firebase envoyé par l'appli
// (en-tête « Authorization: Bearer <jeton> »). Renvoie l'utilisateur ou null.
async function utilisateurDepuisRequete(req) {
  const entete = req.headers.authorization || '';
  const jeton = entete.startsWith('Bearer ') ? entete.slice(7) : null;
  if (!jeton) return null;
  try {
    return await initAdmin().auth().verifyIdToken(jeton);
  } catch (e) {
    return null;
  }
}

// CORS : le site (même domaine) n'en a pas besoin ; on autorise seulement
// le site lui-même et localhost (tests avec « flutter run »).
// Renvoie true si la requête était une pré-vérification (OPTIONS) déjà traitée.
function cors(req, res) {
  const origine = req.headers.origin || '';
  if (origine === SITE || origine.startsWith('http://localhost')) {
    res.setHeader('Access-Control-Allow-Origin', origine);
    res.setHeader('Vary', 'Origin');
  }
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return true;
  }
  return false;
}

module.exports = { SITE, initAdmin, stripe, utilisateurDepuisRequete, cors };
