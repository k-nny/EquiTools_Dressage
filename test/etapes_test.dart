import 'package:flutter_test/flutter_test.dart';
import 'package:reprise_dressage_app/reprise.dart';
import 'package:reprise_dressage_app/reprise_etape.dart';

void main() {
  test('le protocole utilise le nom donné par l\'utilisateur', () {
    final etapes = etapesDeLaReprise([
      const MvtCercle('E', 20, Allure.galop, 'Cercle de détente'),
    ]);
    expect(etapes.single.ligneProtocole, 'E → Cercle de détente');
    expect(etapes.single.figure, 'Cercle');
    expect(etapes.single.parametres['diametre'], 20.0);
  });

  test('les étapes gardent l\'ordre, les départs et arrivées', () {
    final etapes = etapesDeLaReprise(repriseClub3GrandPrix);
    expect(etapes.length, repriseClub3GrandPrix.length);
    expect(etapes.first.ordre, 1);
    expect(etapes.first.positionDepart, 'A');
    expect(etapes.first.positionArrivee, 'X');
    expect(etapes.first.nomPersonnalise, 'Entrée au trot de travail');
  });
}
