import 'package:flutter/material.dart';

import 'ads/ad_banner.dart';
import 'premium_status.dart';
import 'reprise_player.dart';
import 'reprise.dart';
import 'reprise_storage.dart';

class Ecran extends StatefulWidget {
  const Ecran({super.key});

  @override
  State<Ecran> createState() => _EcranState();
}

class _EcranState extends State<Ecran> {
  // Change à chaque réinitialisation pour forcer ReprisePlayer à se
  // reconstruire entièrement (et donc recharger depuis le stockage, qui
  // vient d'être vidé).
  int _versionLecteur = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verifierTutoriel());
  }

  Future<void> _verifierTutoriel() async {
    final dejaVu = await ReprisesStorage.tutorielDejaVu();
    if (dejaVu || !mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _TutorielDialog(),
    );
    ReprisesStorage.marquerTutorielVu();
  }

  Future<void> _reinitialiser() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser'),
        content: const Text(
          'Vos figures actuelles (sur cet appareil) seront remplacées par '
          "la reprise d'exemple. Cette action est irréversible.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
    if (confirme != true || !mounted) return;
    await ReprisesStorage.effacerReprise();
    if (!mounted) return;
    setState(() => _versionLecteur++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reprise de dressage'),
        actions: [
          IconButton(
            tooltip: "Réinitialiser à l'exemple",
            icon: const Icon(Icons.refresh),
            onPressed: _reinitialiser,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 🔵 légende des allures
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                children: Allure.values.map((allure) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: allure.couleur,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        allure.label,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),

            // 🐴 carrière + lecteur de reprise
            Expanded(
              child: ReprisePlayer(
                key: ValueKey(_versionLecteur),
                mouvements: repriseClub3GrandPrix,
              ),
            ),

            // Petit espace pour ne pas coller la pub aux boutons du
            // lecteur juste au-dessus (cf. contrainte n°10).
            const SizedBox(height: 12),

            // 📢 zone publicitaire dédiée, sous le contenu — jamais par
            // dessus (pas de Stack/Positioned ici). N'affiche rien pour
            // les utilisateurs Premium, ni tant que la pub n'a pas fini
            // de charger : la hauteur de cette zone est donc 0 par
            // défaut, et ne prend la hauteur réelle de la bannière que
            // lorsqu'elle est effectivement chargée.
            AdBanner(isPremium: estUtilisateurPremium),
          ],
        ),
      ),
    );
  }
}

class _TutorielDialog extends StatelessWidget {
  const _TutorielDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bienvenue 👋'),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Point(
              icon: Icons.play_arrow,
              texte:
                  'Lisez la reprise avec ▶️, ou naviguez mouvement par '
                  'mouvement avec ⏮ et ⏭.',
            ),
            SizedBox(height: 12),
            _Point(
              icon: Icons.add,
              texte:
                  'Ajoutez vos propres figures avec le bouton "Ajouter" : '
                  'ligne, cercle, demi-cercle, demi-volte, serpentine...',
            ),
            SizedBox(height: 12),
            _Point(
              icon: Icons.delete_outline,
              texte:
                  'Supprimez le mouvement affiché avec "Supprimer".',
            ),
            SizedBox(height: 16),
            _Point(
              icon: Icons.smartphone,
              texte:
                  'Vos figures sont sauvegardées automatiquement, mais '
                  'uniquement sur cet appareil : elles ne vous suivront pas '
                  'si vous changez de téléphone ou désinstallez l\'app.',
              gras: true,
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Compris, commencer'),
        ),
      ],
    );
  }
}

class _Point extends StatelessWidget {
  final IconData icon;
  final String texte;
  final bool gras;

  const _Point({required this.icon, required this.texte, this.gras = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texte,
            style: TextStyle(
              fontWeight: gras ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
