/// Erreur lisible (message en français) liée au paiement ou au compte.
class ErreurPaiement implements Exception {
  final String message;
  const ErreurPaiement(this.message);

  @override
  String toString() => message;
}
