import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reprise_dressage_app/compte/ecran_compte.dart';
import 'package:reprise_dressage_app/compte/service_premium.dart';
import 'package:reprise_dressage_app/protocole_lignes.dart';
import 'package:reprise_dressage_app/protocole_pdf.dart';
import 'package:reprise_dressage_app/reprise_controller.dart';

/// Point d'entrée du bouton « Protocole PDF » : demande le modèle et les
/// informations facultatives (nom de la reprise, niveau, cavalier, cheval),
/// puis génère le PDF. Le modèle « compétition » est réservé aux Premium.
Future<void> exporterProtocole(
  BuildContext context,
  ReprisePlayerController controller,
) async {
  if (controller.mouvements.isEmpty) {
    // Même message que l'export direct (reprise vide).
    await partagerProtocolePdf(context, controller.mouvements);
    return;
  }

  final choix = await showDialog<_ChoixExport>(
    context: context,
    builder: (context) => const _DialogExport(),
  );
  if (choix == null || !context.mounted) return;

  if (choix.versPremium) {
    await ouvrirCompte(context, controller);
    return;
  }

  await partagerProtocolePdf(
    context,
    controller.mouvements,
    infos: choix.infos,
    modele: choix.modele,
  );
}

class _ChoixExport {
  final InfosProtocole infos;
  final ModeleProtocole modele;
  final bool versPremium;

  const _ChoixExport({
    required this.infos,
    required this.modele,
    this.versPremium = false,
  });
}

/// Mémorisation locale (sur cet appareil) des informations saisies, pour ne
/// pas les retaper à chaque export. Le modèle choisi n'est pas mémorisé.
class _ReglagesExport {
  _ReglagesExport._();

  static const _cle = 'protocole_infos_v1';

  static Future<InfosProtocole> charger() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cle);
      if (raw == null) return const InfosProtocole();
      final m = jsonDecode(raw) as Map<String, dynamic>;
      String lire(String k) => (m[k] as String?) ?? '';
      return InfosProtocole(
        reprise: lire('reprise'),
        niveau: lire('niveau'),
        cavalier: lire('cavalier'),
        cheval: lire('cheval'),
      );
    } catch (_) {
      return const InfosProtocole();
    }
  }

  static Future<void> enregistrer(InfosProtocole i) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cle,
        jsonEncode({
          'reprise': i.reprise,
          'niveau': i.niveau,
          'cavalier': i.cavalier,
          'cheval': i.cheval,
        }),
      );
    } catch (_) {
      // Mémorisation facultative : on ignore l'erreur.
    }
  }
}

class _DialogExport extends StatefulWidget {
  const _DialogExport();

  @override
  State<_DialogExport> createState() => _DialogExportState();
}

class _DialogExportState extends State<_DialogExport> {
  final _reprise = TextEditingController();
  final _niveau = TextEditingController();
  final _cavalier = TextEditingController();
  final _cheval = TextEditingController();
  ModeleProtocole _modele = ModeleProtocole.entrainement;

  @override
  void initState() {
    super.initState();
    _ReglagesExport.charger().then((i) {
      if (!mounted) return;
      // On ne remplace pas ce que l'utilisateur a déjà commencé à taper.
      if (_reprise.text.isEmpty) _reprise.text = i.reprise;
      if (_niveau.text.isEmpty) _niveau.text = i.niveau;
      if (_cavalier.text.isEmpty) _cavalier.text = i.cavalier;
      if (_cheval.text.isEmpty) _cheval.text = i.cheval;
    });
  }

  @override
  void dispose() {
    _reprise.dispose();
    _niveau.dispose();
    _cavalier.dispose();
    _cheval.dispose();
    super.dispose();
  }

  InfosProtocole _infos() => InfosProtocole(
    reprise: _reprise.text.trim(),
    niveau: _niveau.text.trim(),
    cavalier: _cavalier.text.trim(),
    cheval: _cheval.text.trim(),
  );

  Widget _champ(TextEditingController c, String libelle) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: c,
      maxLength: 60,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(labelText: libelle, counterText: ''),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ServicePremium.instance,
      builder: (context, _) {
        final premium = ServicePremium.instance.estPremium;
        final verrouille = _modele == ModeleProtocole.competition && !premium;

        return AlertDialog(
          title: const Text('Protocole PDF'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<ModeleProtocole>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ModeleProtocole.entrainement,
                        label: Text('Entraînement'),
                      ),
                      ButtonSegment(
                        value: ModeleProtocole.competition,
                        label: Text('Compétition ✨'),
                      ),
                    ],
                    selected: {_modele},
                    onSelectionChanged: (s) =>
                        setState(() => _modele = s.first),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _modele == ModeleProtocole.entrainement
                        ? 'Numéro, repère, mouvement et allure de chaque figure.'
                        : 'Ajoute les colonnes coefficient, note /10 et '
                              'observations, à remplir à la main.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (verrouille)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Le protocole de compétition est réservé aux '
                        'comptes Premium.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _champ(_reprise, 'Nom de la reprise (facultatif)'),
                  _champ(_niveau, 'Niveau (facultatif)'),
                  _champ(_cavalier, 'Cavalier (facultatif)'),
                  _champ(_cheval, 'Cheval (facultatif)'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                final infos = _infos();
                if (verrouille) {
                  Navigator.of(context).pop(
                    _ChoixExport(
                      infos: infos,
                      modele: _modele,
                      versPremium: true,
                    ),
                  );
                  return;
                }
                await _ReglagesExport.enregistrer(infos);
                if (!context.mounted) return;
                Navigator.of(context).pop(
                  _ChoixExport(infos: infos, modele: _modele),
                );
              },
              child: Text(verrouille ? 'Découvrir Premium' : 'Générer le PDF'),
            ),
          ],
        );
      },
    );
  }
}
