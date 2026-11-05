// Ouvre le portail client Stripe : changer de carte, voir les factures,
// résilier l'abonnement.
const { SITE, initAdmin, stripe, utilisateurDepuisRequete, cors } = require('./_outils');

module.exports = async (req, res) => {
  if (cors(req, res)) return;
  if (req.method !== 'POST') {
    return res.status(405).json({ erreur: 'Méthode non autorisée' });
  }

  const user = await utilisateurDepuisRequete(req);
  if (!user) return res.status(401).json({ erreur: 'Connexion requise' });

  try {
    const doc = await initAdmin()
      .firestore()
      .collection('abonnements')
      .doc(user.uid)
      .get();
    const client = doc.exists ? doc.data().client : null;
    if (!client) return res.status(404).json({ erreur: 'Aucun abonnement trouvé' });

    const session = await stripe().billingPortal.sessions.create({
      customer: client,
      return_url: `${SITE}/`,
    });
    return res.status(200).json({ url: session.url });
  } catch (e) {
    console.error('portail', e);
    return res.status(500).json({ erreur: "Impossible d'ouvrir la gestion de l'abonnement" });
  }
};
