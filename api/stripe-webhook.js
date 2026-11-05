// Reçoit les événements Stripe (paiement réussi, abonnement modifié ou
// résilié) et met à jour le statut Premium dans Firestore.
// C'est la SEULE chose qui peut passer un utilisateur en Premium : le
// client (l'appli) n'a pas le droit d'écrire dans « abonnements ».
const { stripe, majAbonnement } = require('./_outils');

function lireCorps(req) {
  return new Promise((ok, ko) => {
    const morceaux = [];
    req.on('data', (d) => morceaux.push(d));
    req.on('end', () => ok(Buffer.concat(morceaux)));
    req.on('error', ko);
  });
}

module.exports = async (req, res) => {
  if (req.method !== 'POST') return res.status(405).end();

  let evenement;
  try {
    const brut = await lireCorps(req);
    evenement = stripe().webhooks.constructEvent(
      brut,
      req.headers['stripe-signature'],
      process.env.STRIPE_WEBHOOK_SECRET
    );
  } catch (e) {
    return res.status(400).send('Signature invalide');
  }

  try {
    switch (evenement.type) {
      case 'checkout.session.completed': {
        const s = evenement.data.object;
        if (s.mode === 'subscription' && s.client_reference_id) {
          await majAbonnement(s.client_reference_id, 'stripe', {
            actifSource: true,
            client: s.customer,
            abonnement: s.subscription,
          });
        }
        break;
      }
      case 'customer.subscription.created':
      case 'customer.subscription.updated':
      case 'customer.subscription.deleted': {
        const sub = evenement.data.object;
        const uid = sub.metadata && sub.metadata.uid;
        if (uid) {
          const actif =
            evenement.type !== 'customer.subscription.deleted' &&
            ['active', 'trialing'].includes(sub.status);
          const fin =
            (sub.items &&
              sub.items.data &&
              sub.items.data[0] &&
              sub.items.data[0].current_period_end) ||
            sub.current_period_end;
          await majAbonnement(uid, 'stripe', {
            actifSource: actif,
            client: sub.customer,
            abonnement: sub.id,
            annulationPrevue: !!sub.cancel_at_period_end,
            jusqua: fin ? fin * 1000 : null,
          });
        }
        break;
      }
      default:
        break;
    }
    return res.status(200).json({ recu: true });
  } catch (e) {
    console.error('stripe-webhook', e);
    return res.status(500).end();
  }
};

// Il faut le corps brut pour vérifier la signature Stripe.
module.exports.config = { api: { bodyParser: false } };
