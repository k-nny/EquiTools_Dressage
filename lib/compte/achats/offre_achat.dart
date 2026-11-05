/// Une formule d'abonnement proposée par le magasin (Google Play / App
/// Store), avec le prix déjà formaté et converti dans la devise locale.
class OffreAchat {
  final String id;
  final String titre;
  final String prix;

  /// Objet interne de la bibliothèque d'achats (non utilisé par l'interface).
  final Object? brut;

  const OffreAchat({
    required this.id,
    required this.titre,
    required this.prix,
    this.brut,
  });
}
