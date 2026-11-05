// Supprime définitivement le compte de l'utilisateur et ses données
// (obligatoire dans les applications Google Play / App Store).
// L'utilisateur doit s'être connecté il y a moins de 5 minutes.
const { initAdmin, stripe, utilisateurDepuisRequete, cors } = require('./_outils');

module.exports = async (req, res) => {
  if (cors(req, res)) return;
  if (req.method !== 'POST') {
    return res.status(405).json({ erreur: 'Méthode non autorisée' });
  }

  const user = await utilisateurDepuisRequete(req);
  if (!user) return res.status(401).json({ erreur: 'Connexion requise' });

  const maintenant = Math.floor(Date.now() / 1000);
  if (!user.auth_time || maintenant - user.auth_time > 300) {
    return res.status(401).json({ erreur: 'Veuillez vous reconnecter puis réessayer.' });
  }

  try {
    const admin = initAdmin();
    const db = admin.firestore();
    const abo = await db.collection('abonnements').doc(user.uid).get();
    const d = abo.exists ? abo.data() : {};

    // Un abonnement de magasin ne peut pas être résilié par le serveur :
    // on demande à l'utilisateur de le faire d'abord (sinon il continuerait
    // à être facturé sans service).
    if (d.storeActif) {
      return res.status(409).json({
        erreur:
          'Résiliez d\'abord votre abonnement Premium depuis les abonnements de Google Play / App Store, puis supprimez votre compte.',
      });
    }

    // Abonnement Stripe : résilié immédiatement.
    if (d.stripeActif && d.abonnement) {
      try {
        await stripe().subscriptions.cancel(d.abonnement);
      } catch (e) {
        if (!(e && e.code === 'resource_missing')) throw e;
      }
    }

    await Promise.all([
      db.collection('users').doc(user.uid).delete(),
      db.collection('abonnements').doc(user.uid).delete(),
      db.collection('usages').doc(user.uid).delete(),
    ]);
    await admin.auth().deleteUser(user.uid);
    return res.status(200).json({ ok: true });
  } catch (e) {
    console.error('supprimer-compte', e);
    return res.status(500).json({ erreur: 'La suppression a échoué. Réessayez.' });
  }
};
