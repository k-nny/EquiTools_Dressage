// Démarre un paiement Stripe pour passer Premium. Appelée par l'appli, qui
// envoie le jeton de connexion Firebase de l'utilisateur.
const { SITE, initAdmin, stripe, utilisateurDepuisRequete, cors } = require('./_outils');

module.exports = async (req, res) => {
  if (cors(req, res)) return;
  if (req.method !== 'POST') {
    return res.status(405).json({ erreur: 'Méthode non autorisée' });
  }

  const user = await utilisateurDepuisRequete(req);
  if (!user) return res.status(401).json({ erreur: 'Connexion requise' });

  const plan = req.body && req.body.plan === 'annuel' ? 'annuel' : 'mensuel';
  const prix =
    plan === 'annuel'
      ? process.env.STRIPE_PRICE_ANNUEL
      : process.env.STRIPE_PRICE_MENSUEL;
  if (!prix) return res.status(500).json({ erreur: 'Paiement non configuré' });

  try {
    const db = initAdmin().firestore();
    const doc = await db.collection('abonnements').doc(user.uid).get();
    const donnees = doc.exists ? doc.data() : {};
    if (donnees.actif) {
      return res.status(409).json({ erreur: 'Vous êtes déjà Premium.' });
    }

    const session = await stripe().checkout.sessions.create({
      mode: 'subscription',
      line_items: [{ price: prix, quantity: 1 }],
      client_reference_id: user.uid,
      ...(donnees.client
        ? { customer: donnees.client }
        : { customer_email: user.email }),
      subscription_data: { metadata: { uid: user.uid } },
      allow_promotion_codes: true,
      locale: 'fr',
      success_url: `${SITE}/?paiement=ok`,
      cancel_url: `${SITE}/?paiement=annule`,
    });
    return res.status(200).json({ url: session.url });
  } catch (e) {
    console.error('creer-checkout', e);
    return res.status(500).json({ erreur: 'Impossible de démarrer le paiement' });
  }
};
