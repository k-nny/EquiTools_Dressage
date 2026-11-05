// Achats intégrés (Google Play / App Store) via RevenueCat.
//
// Sur le web, la version « stub » est utilisée (aucune dépendance native) :
// le paiement passe alors par Stripe. Sur Android / iOS, la version native
// est utilisée.
export 'achats_stub.dart' if (dart.library.io) 'achats_natif.dart';
export 'offre_achat.dart';
