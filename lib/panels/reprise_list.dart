import 'package:flutter/material.dart';

import 'package:reprise_dressage_app/reprise.dart';
import 'package:reprise_dressage_app/reprise_controller.dart';

/// Liste de toutes les figures de la reprise, dans l'ordre. La figure
/// actuellement sélectionnée (ou en cours de lecture) est mise en
/// évidence ; toucher une figure la sélectionne, glisser-déposer change
/// l'ordre, et la croix la supprime.
class ListeReprise extends StatelessWidget {
  final ReprisePlayerController controller;

  const ListeReprise({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final liste = controller.mouvements;
        if (liste.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Ta reprise est vide. Ajoute ta première figure !'),
          );
        }
        return ReorderableListView.builder(
          buildDefaultDragHandles: true,
          itemCount: liste.length,
          onReorder: controller.deplacer,
          itemBuilder: (context, i) {
            final m = liste[i];
            final courant = i == controller.currentIndex;
            return ListTile(
              key: ValueKey('figure-$i'),
              dense: true,
              selected: courant,
              selectedTileColor: m.allure.couleur.withValues(alpha: 0.15),
              leading: CircleAvatar(
                radius: 12,
                backgroundColor: m.allure.couleur,
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
              title: Text(
                m.estCompatibleCarriereActuelle
                    ? m.description
                    : '⚠️ ${m.description}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: courant ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(m.allure.label),
              trailing: IconButton(
                tooltip: 'Supprimer cette figure',
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => controller.supprimerA(i),
              ),
              onTap: () => controller.allerA(i),
            );
          },
        );
      },
    );
  }
}
