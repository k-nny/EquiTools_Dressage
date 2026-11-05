// Reçoit les événements RevenueCat (achat, renouvellement, résiliation,
// expiration d'un abonnement Google Play / App Store) et met à jour le
// statut Premium dans Firestore.
// RevenueCat → Project settings → Integrations → Webhooks : l'URL de cette
// fonction, et une valeur « Authorization header » identique à la variable
// d'environnement REVENUECAT_WEBHOOK_AUTH.
const { majAbonnement } = require('./_outils');

const TYPES = [
  'INITIAL_PURCHASE',
  'RENEWAL',
  'CANCELLATION',
  'UNCANCELLATION',
  'EXPIRATION',
  'PRODUCT_CHANGE',
  'BILLING_ISSUE',
  'SUBSCRIPTION_EXTENDED',
];

module.exports = async (req, res) => {
  if (req.method !== 'POST') return res.status(405).end();

  const attendu = process.env.REVENUECAT_WEBHOOK_AUTH;
  if (!attendu || req.headers.authorization !== attendu) {
    return res.status(401).end();
  }

  const e = req.body && req.body.event;
  if (!e) return res.status(400).end();

  const uid = e.app_user_id;
  if (!uid || String(uid).startsWith('$RCAnonymousID')) {
    return res.status(200).json({ ignore: true });
  }
  if (!TYPES.includes(e.type)) return res.status(200).json({ ignore: true });

  try {
    const fin = e.expiration_at_ms || null;
    const actif = e.type !== 'EXPIRATION' && fin !== null && fin > Date.now();
    await majAbonnement(uid, 'store', {
      actifSource: actif,
      annulationPrevue: e.type === 'CANCELLATION',
      jusqua: fin,
    });
    return res.status(200).json({ recu: true });
  } catch (err) {
    console.error('revenuecat-webhook', err);
    return res.status(500).end();
  }
};
