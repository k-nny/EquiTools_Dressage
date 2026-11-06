import 'package:flutter_test/flutter_test.dart';
import 'package:reprise_dressage_app/Figures/transition.dart';
import 'package:reprise_dressage_app/protocole_lignes.dart';
import 'package:reprise_dressage_app/reprise.dart';

void main() {
  test('les figures sont numérotées dans l\'ordre, avec départ → arrivée', () {
    final lignes = lignesDuProtocole(repriseClub3GrandPrix);
    expect(lignes.length, repriseClub3GrandPrix.length);
    expect([for (final l in lignes) l.numero], [
      for (var i = 1; i <= lignes.length; i++) i,
    ]);
    expect(lignes.first.repere, 'A → X');
    expect(lignes.first.nom, 'Entrée au trot de travail');
  });

  test('un cercle garde son nom et affiche son diamètre', () {
    final l = lignesDuProtocole([
      const MvtCercle('E', 20, Allure.galop, 'Cercle de détente'),
    ]).single;
    expect(l.repere, 'E');
    expect(l.nom, 'Cercle de détente');
    expect(l.detail, 'Cercle de 20 m');
    expect(l.allure, Allure.galop);
  });

  test('le détail est omis quand il répète le nom', () {
    final l = lignesDuProtocole([
      const MvtCercle('E', 20, Allure.trot, 'Cercle de 20 m'),
    ]).single;
    expect(l.detail, isNull);
  });

  test('un changement d\'allure est décrit avec son allure et son lieu', () {
    final l = lignesDuProtocole([
      MvtLigne(
        const [Repere.lettre('A'), Repere.lettre('X'), Repere.lettre('C')],
        Allure.trot,
        'Grande ligne',
        transitions: [Transition.surLettre('X', Allure.galop.couleur)],
      ),
    ]).single;
    expect(l.repere, 'A → C');
    expect(l.detail, 'A → X → C');
    expect(l.changements.single.texte, 'Galop de travail à X');
    expect(l.changements.single.allure, Allure.galop);
  });

  test('une serpentine indique son nombre de boucles', () {
    final l = lignesDuProtocole([
      const MvtSerpentine('A', 'C', 3, Allure.trot, 'Serpentine'),
    ]).single;
    expect(l.detail, 'Serpentine de 3 boucles');
  });

  test('un arrêt n\'a ni détail ni changement d\'allure', () {
    final l = lignesDuProtocole([const MvtArret('X', 'Arrêt – salut')]).single;
    expect(l.repere, 'X');
    expect(l.allure, Allure.arret);
    expect(l.detail, isNull);
    expect(l.changements, isEmpty);
  });

  test('la préparation du protocole ne modifie pas la reprise', () {
    final avant = List<Mouvement>.of(repriseClub3GrandPrix);
    lignesDuProtocole(repriseClub3GrandPrix);
    expect(repriseClub3GrandPrix, avant);
  });
}
