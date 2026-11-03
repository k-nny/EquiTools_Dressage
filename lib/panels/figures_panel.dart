import 'package:flutter/material.dart';

import 'package:reprise_dressage_app/mouvement_editor.dart';
import 'package:reprise_dressage_app/panels/reprise_list.dart';
import 'package:reprise_dressage_app/reprise_controller.dart';

/// Panneau "Figures", affiché à gauche de la carrière sur grand écran :
/// le bouton pour ajouter une figure (galerie par catégories avec aperçu),
/// puis la liste de toutes les figures de la reprise.
class FiguresPanel extends StatelessWidget {
  final ReprisePlayerController controller;

  const FiguresPanel({super.key, required this.controller});

  Future<void> _ajouter(BuildContext context) async {
    final mvt = await showMouvementEditor(context);
    if (mvt == null) return;
    controller.ajouter(mvt);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Text('➕', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                'Figures',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _ajouter(context),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une figure'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ma reprise',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: ListeReprise(controller: controller)),
        ],
      ),
    );
  }
}
