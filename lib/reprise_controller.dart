import 'package:flutter/foundation.dart';

import 'Figures/transition.dart';
import 'reprise.dart';
import 'reprise_storage.dart';

/// Source de vérité pour la reprise en cours d'édition : la liste de
/// mouvements, la position courante, le chargement/sauvegarde locale.
///
/// Partagé entre le panneau "Figures" (qui ajoute) et le lecteur/animation
/// (qui affiche et anime), pour qu'ils restent synchronisés quelle que
/// soit la disposition de l'écran — panneaux séparés sur PC, tout empilé
/// sur mobile.
class ReprisePlayerController extends ChangeNotifier {
  final List<Mouvement> _mouvementsParDefaut;

  late List<Mouvement> mouvements;
  int currentIndex = 0;
  bool chargementTermine = false;

  ReprisePlayerController(List<Mouvement> mouvementsParDefaut)
    : _mouvementsParDefaut = mouvementsParDefaut {
    mouvements = List.of(mouvementsParDefaut);
    _chargerDepuisStockage();
  }

  bool get estVide => mouvements.isEmpty;
  Mouvement get courant => mouvements[currentIndex];
  bool get estPremier => currentIndex == 0;
  bool get estDernier => currentIndex == mouvements.length - 1;

  Future<void> _chargerDepuisStockage() async {
    final sauvegarde = await ReprisesStorage.chargerReprise();
    if (sauvegarde != null) {
      mouvements = sauvegarde;
      currentIndex = 0;
    }
    chargementTermine = true;
    notifyListeners();
  }

  void _sauvegarder() {
    ReprisesStorage.sauvegarderReprise(mouvements);
  }

  /// Déplace la position courante (Précédent/Suivant, ou sélection directe
  /// depuis une liste). Ne notifie pas si l'index ne change pas réellement.
  void allerA(int index) {
    if (estVide) return;
    final clamped = index.clamp(0, mouvements.length - 1).toInt();
    if (clamped == currentIndex) return;
    currentIndex = clamped;
    notifyListeners();
  }

  /// Ajoute un mouvement juste après la position courante, et s'y déplace.
  void ajouter(Mouvement mvt) {
    final insertAt = estVide ? 0 : currentIndex + 1;
    mouvements.insert(insertAt, mvt);
    currentIndex = insertAt;
    _sauvegarder();
    notifyListeners();
  }

  void supprimerCourant() {
    if (estVide) return;
    mouvements.removeAt(currentIndex);
    if (mouvements.isEmpty) {
      currentIndex = 0;
    } else if (currentIndex >= mouvements.length) {
      currentIndex = mouvements.length - 1;
    }
    _sauvegarder();
    notifyListeners();
  }

  /// Remplace le mouvement courant par [nouveau] (même position), puis
  /// sauvegarde. Sert à changer l'allure, le nom ou les transitions.
  void remplacerCourant(Mouvement nouveau) {
    if (estVide) return;
    mouvements[currentIndex] = nouveau;
    _sauvegarder();
    notifyListeners();
  }

  void changerAllureCourant(Allure allure) =>
      remplacerCourant(courant.copyWith(allure: allure));

  void renommerCourant(String nom) {
    final propre = nom.trim();
    if (propre.isEmpty) return;
    remplacerCourant(courant.copyWith(description: propre));
  }

  void ajouterTransitionCourante(String lettre, Allure allure) {
    if (estVide) return;
    remplacerCourant(
      courant.copyWith(
        transitions: [
          ...courant.transitions,
          Transition.surLettre(lettre, allure.couleur),
        ],
      ),
    );
  }

  void supprimerTransitionCourante(int index) {
    if (estVide) return;
    final liste = [...courant.transitions]..removeAt(index);
    remplacerCourant(courant.copyWith(transitions: liste));
  }

  /// Supprime la figure à [index] (et garde la sélection cohérente).
  void supprimerA(int index) {
    if (index < 0 || index >= mouvements.length) return;
    mouvements.removeAt(index);
    if (mouvements.isEmpty) {
      currentIndex = 0;
    } else if (index < currentIndex) {
      currentIndex -= 1;
    } else if (currentIndex >= mouvements.length) {
      currentIndex = mouvements.length - 1;
    }
    _sauvegarder();
    notifyListeners();
  }

  /// Change l'ordre des figures (convention de ReorderableListView).
  void deplacer(int ancien, int nouveau) {
    if (nouveau > ancien) nouveau -= 1;
    if (ancien == nouveau) return;
    final m = mouvements.removeAt(ancien);
    mouvements.insert(nouveau, m);
    if (currentIndex == ancien) {
      currentIndex = nouveau;
    } else if (ancien < currentIndex && nouveau >= currentIndex) {
      currentIndex -= 1;
    } else if (ancien > currentIndex && nouveau <= currentIndex) {
      currentIndex += 1;
    }
    _sauvegarder();
    notifyListeners();
  }

  /// À appeler après un changement de taille de carrière (Lettres.taille) :
  /// redessine tout et arrête l'animation en cours.
  void carriereChangee() => notifyListeners();

  /// Efface la reprise sauvegardée sur cet appareil et revient à l'exemple
  /// par défaut.
  Future<void> reinitialiser() async {
    await ReprisesStorage.effacerReprise();
    mouvements = List.of(_mouvementsParDefaut);
    currentIndex = 0;
    notifyListeners();
  }
}
