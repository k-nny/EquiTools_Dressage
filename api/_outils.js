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

// Met à jour le statut Premium d'un utilisateur. Un utilisateur peut être
// abonné via Stripe (web) ET/OU via un magasin (Google Play / App Store) :
// « actif » vaut vrai si au moins une des deux sources est active.
// champs.actifSource = la source concernée est-elle active ?
async function majAbonnement(uid, source, champs) {
  const db = initAdmin().firestore();
  const ref = db.collection('abonnements').doc(uid);
  await db.runTransaction(async (t) => {
    const snap = await t.get(ref);
    const d = snap.exists ? snap.data() : {};
    const { actifSource, ...reste } = champs;
    const stripeActif = source === 'stripe' ? !!actifSource : !!d.stripeActif;
    const storeActif = source === 'store' ? !!actifSource : !!d.storeActif;
    const autreActive = source === 'stripe' ? storeActif : stripeActif;
    const ecriture = { ...reste, stripeActif, storeActif, actif: stripeActif || storeActif, maj: Date.now() };
    if (actifSource || !autreActive) {
      ecriture.source = source;
    } else {
      // La source qui s'arrête ne doit pas écraser les dates de l'autre.
      delete ecriture.jusqua;
      delete ecriture.annulationPrevue;
    }
    t.set(ref, ecriture, { merge: true });
  });
}

module.exports = { SITE, initAdmin, stripe, utilisateurDepuisRequete, cors, majAbonnement };
