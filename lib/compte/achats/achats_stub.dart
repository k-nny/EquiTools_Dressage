import 'package:reprise_dressage_app/compte/achats/offre_achat.dart';

/// Version web : pas d'achats intégrés.
class AchatsIntegres {
  AchatsIntegres._();

  static bool get disponible => false;

  static Future<void> init() async {}

  static Future<void> connecter(String uid) async {}

  static Future<void> deconnecter() async {}

  static Future<List<OffreAchat>> offres() async => const [];

  static Future<void> acheter(OffreAchat offre) async {}

  static Future<void> restaurer() async {}
}
