import 'package:flutter/material.dart';

import 'package:reprise_dressage_app/figure_preview.dart';
import 'package:reprise_dressage_app/lettres.dart';
import 'package:reprise_dressage_app/reprise.dart';
import 'package:reprise_dressage_app/Figures/transition.dart';

/// Lettres dans un ordre lisible pour les menus déroulants (tour de piste
/// puis lettres de l'axe central), plutôt que l'ordre alphabétique.
const List<String> _lettresOrdre = [
  'A', 'K', 'V', 'E', 'S', 'H', 'C', 'M', 'R', 'B', 'P', 'F',
  'D', 'L', 'X', 'I', 'G',
];

enum _TypeFigure {
  ligne,
  cercle,
  demiCercle,
  demiVolte,
  demiVolteRenversee,
  serpentine,
  arret,
}

extension on _TypeFigure {
  String get label => switch (this) {
    _TypeFigure.ligne => 'Doublés / Diagonales / Déplacement sur la piste',
    _TypeFigure.cercle => 'Cercle',
    _TypeFigure.demiCercle => 'Demi-cercle',
    _TypeFigure.demiVolte => 'Demi-volte',
    _TypeFigure.demiVolteRenversee => 'Demi-volte renversée',
    _TypeFigure.serpentine => 'Serpentine',
    _TypeFigure.arret => 'Arrêt',
  };

  String get emoji => switch (this) {
    _TypeFigure.ligne => '',
    _TypeFigure.cercle => '',
    _TypeFigure.demiCercle => '',
    _TypeFigure.demiVolte => '',
    _TypeFigure.demiVolteRenversee => '',
    _TypeFigure.serpentine => '',
    _TypeFigure.arret => '',
  };

  String get categorie => switch (this) {
    _TypeFigure.ligne => 'Lignes',
    _TypeFigure.cercle => 'Cercles',
    _TypeFigure.demiCercle ||
    _TypeFigure.demiVolte ||
    _TypeFigure.demiVolteRenversee => 'Demi-tours',
    _TypeFigure.serpentine => 'Serpentines',
    _TypeFigure.arret => 'Arrêts',
  };

  /// Explication courte, volontairement sans jargon.
  String get explication => switch (this) {
    _TypeFigure.ligne => "Le cheval trace une ligne droite d'une lettre à une autre.",
    _TypeFigure.cercle =>
      'Le cheval fait un tour complet en rond et revient au même endroit.',
    _TypeFigure.demiCercle =>
      "Le cheval fait un demi-tour et finit de l'autre côté de la "
          'carrière.',
    _TypeFigure.demiVolte =>
      'Un demi-tour, puis le cheval revient en diagonale sur la '
          'piste.',
    _TypeFigure.demiVolteRenversee =>
      "Comme la demi-volte, mais à l'envers : d'abord la diagonale, "
          'ensuite le demi-tour.',
    _TypeFigure.serpentine =>
      "Le cheval enchaine des demi-cercles reliés par des doublés",
    _TypeFigure.arret =>
      "Le cheval s'arrête, ne bouge plus, et le cavalier salue.",
  };
}

/// Ouvre un formulaire (en feuille modale) pour construire un nouveau
/// [Mouvement]. Renvoie le mouvement construit, ou null si l'utilisateur
/// annule.
Future<Mouvement?> showMouvementEditor(BuildContext context) {
  return showModalBottomSheet<Mouvement>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 820),
    builder: (context) => const _MouvementEditorSheet(),
  );
}

class _MouvementEditorSheet extends StatefulWidget {
  const _MouvementEditorSheet();

  @override
  State<_MouvementEditorSheet> createState() => _MouvementEditorSheetState();
}

class _MouvementEditorSheetState extends State<_MouvementEditorSheet> {
  _TypeFigure _type = _TypeFigure.ligne;
  bool _typeChoisi = false;
  Allure _allure = Allure.trot;

  String _from = 'A';
  String _to = 'C';
  String _prevLetter = 'A';
  String _letter = 'X';

  double _diametre = 15;
  double _nbBoucles = 3;
  bool? _premiereBoucleInverseeOverride; // null = automatique (via _prevLetter)

  /// Transitions de couleur/allure en cours de figure : (lettre, allure).
  final List<(String, Allure)> _transitions = [];

  late final TextEditingController _descriptionCtrl = TextEditingController(
    text: _descriptionParDefaut(),
  );
  bool _descriptionModifieeManuel = false;

  String _descriptionParDefaut() {
    switch (_type) {
      case _TypeFigure.ligne:
        return '$_from → $_to, ${_allure.label.toLowerCase()}';
      case _TypeFigure.cercle:
        return 'Cercle de ${_diametre.round()} m en $_letter';
      case _TypeFigure.demiCercle:
        return 'Demi-cercle de ${_diametre.round()} m';
      case _TypeFigure.demiVolte:
        return 'Demi-volte de ${_diametre.round()} m en $_from';
      case _TypeFigure.demiVolteRenversee:
        return 'Demi-volte renversée de ${_diametre.round()} m';
      case _TypeFigure.serpentine:
        return 'Serpentine de ${_nbBoucles.round()} boucles';
      case _TypeFigure.arret:
        return 'Arrêt - immobilité - salut';
    }
  }

  void _rafraichirDescription() {
    if (_descriptionModifieeManuel) return;
    _descriptionCtrl.text = _descriptionParDefaut();
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Mouvement _construire() {
    final description = _descriptionCtrl.text.trim().isEmpty
        ? _descriptionParDefaut()
        : _descriptionCtrl.text.trim();

    final transitions = _transitions
        .map((t) => Transition.surLettre(t.$1, t.$2.couleur))
        .toList();

    switch (_type) {
      case _TypeFigure.ligne:
        return MvtLigne(
          [Repere.lettre(_from), Repere.lettre(_to)],
          _allure,
          description,
          transitions: transitions,
        );
      case _TypeFigure.cercle:
        return MvtCercle(
          _letter,
          _diametre,
          _allure,
          description,
          prevLetter: _prevLetter,
          transitions: transitions,
        );
      case _TypeFigure.demiCercle:
        return MvtDemiCercle(
          _prevLetter,
          _from,
          _diametre,
          _allure,
          description,
          transitions: transitions,
        );
      case _TypeFigure.demiVolte:
        return MvtDemiVolte(
          _from,
          _to,
          _diametre,
          _allure,
          description,
          transitions: transitions,
        );
      case _TypeFigure.demiVolteRenversee:
        return MvtDemiVolteRenversee(
          _from,
          _to,
          _diametre,
          _allure,
          description,
          transitions: transitions,
        );
      case _TypeFigure.serpentine:
        return MvtSerpentine(
          _from,
          _to,
          _nbBoucles,
          _allure,
          description,
          prevLetter: _prevLetter,
          premiereBoucleInversee: _premiereBoucleInverseeOverride,
          transitions: transitions,
        );
      case _TypeFigure.arret:
        return MvtArret(_letter, description);
    }
  }

  /// Résumé d'une phrase de ce que fait la figure avec les réglages actuels.
  String _resume() {
    switch (_type) {
      case _TypeFigure.ligne:
        return 'Départ : $_from  →  Arrivée : $_to';
      case _TypeFigure.cercle:
        return 'Cercle de ${_diametre.round()} m en $_letter '
            '(en venant de $_prevLetter)';
      case _TypeFigure.demiCercle:
        return 'Départ : $_from (en venant de $_prevLetter), arrivée de '
            "l'autre côté de la carrière";
      case _TypeFigure.demiVolte:
      case _TypeFigure.demiVolteRenversee:
        return 'Départ : $_from  →  Retour sur la piste : $_to';
      case _TypeFigure.serpentine:
        return 'De $_from à $_to, ${_nbBoucles.round()} boucles';
      case _TypeFigure.arret:
        return 'Arrêt en $_letter';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: _typeChoisi ? _formulaire(context) : _galerie(context),
      ),
    );
  }

  /// Étape 1 : choisir une figure parmi des catégories, avec une explication
  /// simple pour chacune.
  Widget _galerie(BuildContext context) {
    final categories = <String, List<_TypeFigure>>{};
    for (final t in _TypeFigure.values) {
      categories.putIfAbsent(t.categorie, () => []).add(t);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '➕ Quelle figure veux-tu ajouter ?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          "Touche une figure pour la voir en action avant de l'ajouter.",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        for (final entree in categories.entries) ...[
          const SizedBox(height: 16),
          Text(
            entree.key,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          for (final t in entree.value)
            Card(
              child: ListTile(
                minVerticalPadding: 12,
                leading: Text(t.emoji, style: const TextStyle(fontSize: 30)),
                title: Text(
                  t.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(t.explication),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => setState(() {
                  _type = t;
                  _typeChoisi = true;
                  _rafraichirDescription();
                }),
              ),
            ),
        ],
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
      ],
    );
  }

  /// Étape 2 : voir la figure en action, régler ses paramètres, la nommer,
  /// puis l'ajouter à la reprise.
  Widget _formulaire(BuildContext context) {
    final large = MediaQuery.of(context).size.width >= 700;

    final apercu = Column(
      children: [
        FigurePreview(mouvement: _construire(), largeur: large ? 140 : 110),
        const SizedBox(height: 8),
        SizedBox(
          width: large ? 160 : 200,
          child: Text(
            _resume(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );

    final champs = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._champsPourType(),
        if (_type != _TypeFigure.arret) ...[
          const SizedBox(height: 12),
          const Divider(),
          _sectionTransitions(),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionCtrl,
          decoration: const InputDecoration(
            labelText: 'Nom de la figure (il apparaîtra dans le PDF)',
          ),
          onChanged: (_) => _descriptionModifieeManuel = true,
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Choisir une autre figure',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _typeChoisi = false),
            ),
            Expanded(
              child: Text(
                '${_type.emoji} ${_type.label}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Text(
          _type.explication,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        if (large)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [apercu, const SizedBox(width: 24), Expanded(child: champs)],
          )
        else ...[
          Center(child: apercu),
          const SizedBox(height: 12),
          champs,
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(_construire()),
                icon: const Icon(Icons.check),
                label: const Text('Ajouter à ma reprise'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _champsPourType() {
    switch (_type) {
      case _TypeFigure.ligne:
        return [
          Row(
            children: [
              Expanded(
                child: _lettreDropdown(
                  label: 'De',
                  value: _from,
                  onChanged: (v) => setState(() {
                    _from = v!;
                    _rafraichirDescription();
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _lettreDropdown(
                  label: 'À',
                  value: _to,
                  onChanged: (v) => setState(() {
                    _to = v!;
                    _rafraichirDescription();
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _allureDropdown(),
        ];

      case _TypeFigure.cercle:
        return [
          Row(
            children: [
              Expanded(
                child: _lettreDropdown(
                  label: 'Lettre',
                  value: _letter,
                  onChanged: (v) => setState(() {
                    _letter = v!;
                    _rafraichirDescription();
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _lettreDropdown(
                  label: 'En venant de',
                  value: _prevLetter,
                  onChanged: (v) => setState(() => _prevLetter = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _diametreField(),
          const SizedBox(height: 12),
          _allureDropdown(),
        ];

      case _TypeFigure.demiCercle:
        return [
          Row(
            children: [
              Expanded(
                child: _lettreDropdown(
                  label: 'En venant de',
                  value: _prevLetter,
                  onChanged: (v) => setState(() => _prevLetter = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _lettreDropdown(
                  label: 'Départ (sur la piste)',
                  value: _from,
                  onChanged: (v) => setState(() {
                    _from = v!;
                    _rafraichirDescription();
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Arrivée automatique à l'opposé (même hauteur, autre grand côté).",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          _diametreField(),
          const SizedBox(height: 12),
          _allureDropdown(),
        ];

      case _TypeFigure.demiVolte:
        return [
          Row(
            children: [
              Expanded(
                child: _lettreDropdown(
                  label: 'De',
                  value: _from,
                  onChanged: (v) => setState(() {
                    _from = v!;
                    _rafraichirDescription();
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _lettreDropdown(
                  label: 'Retour piste en',
                  value: _to,
                  onChanged: (v) => setState(() => _to = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Demi-cercle depuis "De", puis diagonale jusqu\'à "Retour piste en".',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          _diametreField(),
          const SizedBox(height: 12),
          _allureDropdown(),
        ];

      case _TypeFigure.demiVolteRenversee:
        return [
          Row(
            children: [
              Expanded(
                child: _lettreDropdown(
                  label: 'De',
                  value: _from,
                  onChanged: (v) => setState(() {
                    _from = v!;
                    _rafraichirDescription();
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _lettreDropdown(
                  label: 'Retour piste en',
                  value: _to,
                  onChanged: (v) => setState(() => _to = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Diagonale depuis "De", puis demi-cercle jusqu\'à "Retour piste en".',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          _diametreField(),
          const SizedBox(height: 12),
          _allureDropdown(),
        ];

      case _TypeFigure.serpentine:
        return [
          Row(
            children: [
              Expanded(
                child: _lettreDropdown(
                  label: 'De',
                  value: _from,
                  onChanged: (v) => setState(() {
                    _from = v!;
                    _rafraichirDescription();
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _lettreDropdown(
                  label: 'À',
                  value: _to,
                  onChanged: (v) => setState(() => _to = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _lettreDropdown(
            label: 'En venant de',
            value: _prevLetter,
            onChanged: (v) => setState(() => _prevLetter = v!),
          ),
          const SizedBox(height: 4),
          Text(
            'La 1ère boucle part automatiquement du côté opposé à "en '
            'venant de".',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          _nbBouclesField(),
          const SizedBox(height: 8),
          DropdownButtonFormField<bool?>(
            initialValue: _premiereBoucleInverseeOverride,
            decoration: const InputDecoration(
              labelText: 'Sens de la 1ère boucle',
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Automatique')),
              DropdownMenuItem(value: false, child: Text('Forcer un sens')),
              DropdownMenuItem(
                value: true,
                child: Text("Forcer le sens inverse"),
              ),
            ],
            onChanged: (v) =>
                setState(() => _premiereBoucleInverseeOverride = v),
          ),
          const SizedBox(height: 4),
          _allureDropdown(),
        ];

      case _TypeFigure.arret:
        return [
          _lettreDropdown(
            label: 'Lettre',
            value: _letter,
            onChanged: (v) => setState(() {
              _letter = v!;
              _rafraichirDescription();
            }),
          ),
        ];
    }
  }

  Widget _sectionTransitions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Transitions en cours de figure (changement d'allure à une lettre)",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        for (var i = 0; i < _transitions.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: _lettreDropdown(
                    label: 'À la lettre',
                    value: _transitions[i].$1,
                    onChanged: (v) => setState(() {
                      _transitions[i] = (v!, _transitions[i].$2);
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<Allure>(
                    initialValue: _transitions[i].$2,
                    decoration: const InputDecoration(
                      labelText: 'Nouvelle allure',
                    ),
                    items: Allure.values
                        .where((a) => a != Allure.arret)
                        .map(
                          (a) => DropdownMenuItem(
                            value: a,
                            child: Text(a.label),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() {
                      _transitions[i] = (_transitions[i].$1, v!);
                    }),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _transitions.removeAt(i)),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () =>
                setState(() => _transitions.add(('X', _allure))),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une transition'),
          ),
        ),
      ],
    );
  }

  Widget _lettreDropdown({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: _lettresOrdre
          .where(Lettres.letters.containsKey)
          .map((l) => DropdownMenuItem(value: l, child: Text(l)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _allureDropdown() {
    final options = Allure.values.where((a) => a != Allure.arret).toList();
    return DropdownButtonFormField<Allure>(
      initialValue: _allure,
      decoration: const InputDecoration(labelText: 'Allure'),
      items: options
          .map((a) => DropdownMenuItem(value: a, child: Text(a.label)))
          .toList(),
      onChanged: (v) => setState(() {
        _allure = v!;
        _rafraichirDescription();
      }),
    );
  }

  Widget _diametreField() {
    return TextFormField(
      initialValue: _diametre.round().toString(),
      decoration: const InputDecoration(labelText: 'Diamètre (m)'),
      keyboardType: TextInputType.number,
      onChanged: (v) {
        final n = double.tryParse(v);
        if (n != null && n > 0) {
          setState(() {
            _diametre = n;
            _rafraichirDescription();
          });
        }
      },
    );
  }

  Widget _nbBouclesField() {
    return TextFormField(
      initialValue: _nbBoucles.round().toString(),
      decoration: const InputDecoration(labelText: 'Nombre de boucles'),
      keyboardType: TextInputType.number,
      onChanged: (v) {
        final n = double.tryParse(v);
        if (n != null && n >= 2) {
          setState(() {
            _nbBoucles = n;
            _rafraichirDescription();
          });
        }
      },
    );
  }
}
