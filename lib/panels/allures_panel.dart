import 'package:flutter/material.dart';

import 'package:reprise_dressage_app/Figures/transition.dart';
import 'package:reprise_dressage_app/lettres.dart';
import 'package:reprise_dressage_app/reprise.dart';
import 'package:reprise_dressage_app/reprise_controller.dart';

/// Panneau "Allures & transitions" : à droite de la carrière sur grand
/// écran, dans une feuille modale sur téléphone.
///
/// Il agit sur la figure actuellement sélectionnée dans la reprise :
/// choix de son allure (🟢 pas, 🔵 trot, 🔴 galop et leurs variantes) et
/// des changements d'allure en cours de figure (transitions).
class AlluresPanel extends StatefulWidget {
  final ReprisePlayerController controller;

  const AlluresPanel({super.key, required this.controller});

  @override
  State<AlluresPanel> createState() => _AlluresPanelState();
}

class _AlluresPanelState extends State<AlluresPanel> {
  String? _lettreTransition;
  Allure _allureTransition = Allure.galop;

  static const _ordreLettres = [
    'A', 'K', 'V', 'E', 'S', 'H', 'C', 'M', 'R', 'B', 'P', 'F',
    'D', 'L', 'X', 'I', 'G',
  ];

  List<String> get _lettresDisponibles =>
      _ordreLettres.where(Lettres.letters.containsKey).toList();

  String _descriptionTransition(Transition t) {
    final allure = Allure.values.firstWhere(
      (a) => a.couleur == t.colorAfter,
      orElse: () => Allure.trot,
    );
    final ou = t.letter != null
        ? 'À la lettre ${t.letter}'
        : 'Entre ${t.lineFrom} et ${t.lineTo}';
    return '$ou → ${allure.label}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Text('🐎', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text(
                    'Allures',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (controller.estVide)
                const Text(
                  'Ajoutez d\'abord une figure : vous pourrez ensuite choisir '
                  'son allure ici.',
                )
              else
                ..._contenu(context, controller),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _contenu(BuildContext context, ReprisePlayerController c) {
    final mvt = c.courant;
    final estArret = mvt is MvtArret;

    return [
      Text(
        'Figure choisie :',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      Text(
        mvt.description,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 16),

      const Text(
        'Allure de cette figure',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      if (estArret)
        const Text('Un arrêt n\'a pas d\'allure.')
      else
        for (final famille in const [Famille.pas, Famille.trot, Famille.galop])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: famille.couleur,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      famille.label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final allure in famille.allures)
                      ChoiceChip(
                        label: Text(allure.label),
                        selected: mvt.allure == allure,
                        selectedColor: allure.couleur.withValues(alpha: 0.35),
                        side: BorderSide(color: allure.couleur),
                        onSelected: (_) => c.changerAllureCourant(allure),
                      ),
                  ],
                ),
              ],
            ),
          ),

      if (!estArret) ...[
        const Divider(height: 24),
        const Text(
          'Changer d\'allure pendant la figure',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Par exemple : trot, puis galop à la lettre X.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < mvt.transitions.length; i++)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(_descriptionTransition(mvt.transitions[i])),
            trailing: IconButton(
              tooltip: 'Supprimer cette transition',
              icon: const Icon(Icons.close),
              onPressed: () => c.supprimerTransitionCourante(i),
            ),
          ),
        DropdownButtonFormField<String>(
          initialValue: _lettresDisponibles.contains(_lettreTransition)
              ? _lettreTransition
              : null,
          decoration: const InputDecoration(labelText: 'À quelle lettre ?'),
          items: [
            for (final l in _lettresDisponibles)
              DropdownMenuItem(value: l, child: Text(l)),
          ],
          onChanged: (v) => setState(() => _lettreTransition = v),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Allure>(
          initialValue: _allureTransition,
          decoration: const InputDecoration(labelText: 'Vers quelle allure ?'),
          items: [
            for (final a in Allure.values.where((a) => a != Allure.arret))
              DropdownMenuItem(value: a, child: Text(a.label)),
          ],
          onChanged: (v) =>
              setState(() => _allureTransition = v ?? _allureTransition),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _lettreTransition == null
              ? null
              : () => c.ajouterTransitionCourante(
                  _lettreTransition!,
                  _allureTransition,
                ),
          icon: const Icon(Icons.add),
          label: const Text('Ajouter la transition'),
        ),
      ],
    ];
  }
}
