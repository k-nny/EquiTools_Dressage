import 'package:flutter/material.dart';

import 'package:reprise_dressage_app/compte/service_reprises_cloud.dart';
import 'package:reprise_dressage_app/reprise_controller.dart';

/// Liste des reprises sauvegardées dans le compte (3 maximum) : sauvegarder
/// la reprise actuelle, en charger une, la remplacer ou la supprimer.
class MesReprises extends StatefulWidget {
  final ReprisePlayerController controller;

  const MesReprises({super.key, required this.controller});

  @override
  State<MesReprises> createState() => _MesReprisesState();
}

class _MesReprisesState extends State<MesReprises> {
  List<RepriseSauvegardee>? _liste;
  bool _occupe = false;
  String? _erreur;
  String? _info;

  @override
  void initState() {
    super.initState();
    _recharger();
  }

  Future<void> _recharger() async {
    setState(() {
      _occupe = true;
      _erreur = null;
    });
    try {
      final liste = await ServiceReprisesCloud.charger();
      if (mounted) setState(() => _liste = liste);
    } catch (_) {
      if (mounted) {
        setState(() {
          _erreur = 'Impossible de charger vos reprises. Vérifiez votre connexion.';
        });
      }
    } finally {
      if (mounted) setState(() => _occupe = false);
    }
  }

  Future<void> _enregistrer(
    List<RepriseSauvegardee> nouvelle,
    String messageOk,
  ) async {
    setState(() {
      _occupe = true;
      _erreur = null;
      _info = null;
    });
    try {
      await ServiceReprisesCloud.enregistrer(nouvelle);
      if (mounted) {
        setState(() {
          _liste = nouvelle;
          _info = messageOk;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _erreur = 'La sauvegarde a échoué. Réessayez.');
    } finally {
      if (mounted) setState(() => _occupe = false);
    }
  }

  Future<bool> _confirmer(String titre, String texte, String bouton) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titre),
        content: Text(texte),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(bouton),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _sauvegarderNouvelle() async {
    final liste = _liste;
    if (liste == null) return;
    if (widget.controller.estVide) {
      setState(() => _erreur = 'Votre reprise est vide : rien à sauvegarder.');
      return;
    }
    if (liste.length >= ServiceReprisesCloud.maxReprises) return;

    final nom = await showDialog<String>(
      context: context,
      builder: (context) =>
          _DialogNom(defaut: 'Reprise ${liste.length + 1}'),
    );
    if (nom == null || !mounted) return;

    final nouvelle = RepriseSauvegardee.depuis(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      nom: nom,
      mouvements: widget.controller.mouvements,
    );
    await _enregistrer([...liste, nouvelle], 'Reprise « $nom » sauvegardée.');
  }

  Future<void> _remplacer(int i) async {
    final liste = _liste;
    if (liste == null) return;
    if (widget.controller.estVide) {
      setState(() => _erreur = 'Votre reprise est vide : rien à sauvegarder.');
      return;
    }
    final ancienne = liste[i];
    final ok = await _confirmer(
      'Remplacer « ${ancienne.nom} » ?',
      'Le contenu sauvegardé sera remplacé par votre reprise actuelle.',
      'Remplacer',
    );
    if (!ok || !mounted) return;
    final nouvelle = [...liste];
    nouvelle[i] = RepriseSauvegardee.depuis(
      id: ancienne.id,
      nom: ancienne.nom,
      mouvements: widget.controller.mouvements,
    );
    await _enregistrer(nouvelle, 'Reprise « ${ancienne.nom} » mise à jour.');
  }

  Future<void> _charger(int i) async {
    final liste = _liste;
    if (liste == null) return;
    final r = liste[i];
    final ok = await _confirmer(
      'Charger « ${r.nom} » ?',
      'Votre reprise actuelle (sur cet appareil) sera remplacée. '
          'Sauvegardez-la d\'abord si vous voulez la garder.',
      'Charger',
    );
    if (!ok || !mounted) return;
    try {
      widget.controller.remplacerReprise(r.mouvements());
      setState(() {
        _erreur = null;
        _info = 'Reprise « ${r.nom} » chargée.';
      });
    } catch (_) {
      setState(() => _erreur = 'Cette reprise est illisible.');
    }
  }

  Future<void> _supprimer(int i) async {
    final liste = _liste;
    if (liste == null) return;
    final r = liste[i];
    final ok = await _confirmer(
      'Supprimer « ${r.nom} » ?',
      'Cette reprise sauvegardée sera définitivement supprimée de votre compte.',
      'Supprimer',
    );
    if (!ok || !mounted) return;
    final nouvelle = [...liste]..removeAt(i);
    await _enregistrer(nouvelle, 'Reprise « ${r.nom} » supprimée.');
  }

  String _date(DateTime d) {
    String deux(int n) => n.toString().padLeft(2, '0');
    return '${deux(d.day)}/${deux(d.month)}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final liste = _liste;
    final max = ServiceReprisesCloud.maxReprises;
    final plein = liste != null && liste.length >= max;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mes reprises sauvegardées${liste == null ? '' : ' (${liste.length}/$max)'}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (liste == null && _occupe)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (liste != null && liste.isEmpty)
          const Text('Aucune reprise sauvegardée pour le moment.'),
        if (liste != null)
          for (var i = 0; i < liste.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    liste[i].nom,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${liste[i].nbMouvements} mouvements · '
                    '${_date(liste[i].maj)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Wrap(
                    children: [
                      TextButton(
                        onPressed: _occupe ? null : () => _charger(i),
                        child: const Text('Charger'),
                      ),
                      TextButton(
                        onPressed: _occupe ? null : () => _remplacer(i),
                        child: const Text('Remplacer'),
                      ),
                      IconButton(
                        tooltip: 'Supprimer',
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: Colors.red,
                        onPressed: _occupe ? null : () => _supprimer(i),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        const SizedBox(height: 8),
        if (liste != null)
          OutlinedButton.icon(
            onPressed: (_occupe || plein) ? null : _sauvegarderNouvelle,
            icon: const Icon(Icons.add),
            label: const Text('Sauvegarder ma reprise'),
          ),
        if (plein)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Limite de 3 reprises atteinte : remplacez-en une ou '
              'supprimez-en une.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        if (_erreur != null) ...[
          const SizedBox(height: 8),
          Text(_erreur!, style: const TextStyle(color: Colors.red)),
          if (liste == null)
            TextButton(onPressed: _recharger, child: const Text('Réessayer')),
        ],
        if (_info != null) ...[
          const SizedBox(height: 8),
          Text(_info!, style: const TextStyle(color: Colors.green)),
        ],
      ],
    );
  }
}

/// Demande le nom à donner à la reprise sauvegardée.
class _DialogNom extends StatefulWidget {
  final String defaut;

  const _DialogNom({required this.defaut});

  @override
  State<_DialogNom> createState() => _DialogNomState();
}

class _DialogNomState extends State<_DialogNom> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.defaut,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _valider() {
    final nom = _ctrl.text.trim();
    Navigator.of(context).pop(nom.isEmpty ? widget.defaut : nom);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nom de la reprise'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        maxLength: 40,
        decoration: const InputDecoration(labelText: 'Nom'),
        onSubmitted: (_) => _valider(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _valider, child: const Text('Sauvegarder')),
      ],
    );
  }
}
