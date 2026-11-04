import 'package:flutter/material.dart';

import 'ads/ad_banner.dart';
import 'compte/ecran_compte.dart';
import 'compte/service_compte.dart';
import 'pages_info.dart';
import 'panels/allures_panel.dart';
import 'panels/figures_panel.dart';
import 'panels/reprise_list.dart';
import 'lettres.dart';
import 'premium_status.dart';
import 'reprise.dart';
import 'reprise_controller.dart';
import 'reprise_player.dart';
import 'protocole_pdf.dart';
import 'reprise_storage.dart';

/// Largeur à partir de laquelle on bascule sur la mise en page "ordinateur"
/// à trois colonnes (Figures | Carrière | Allures) plutôt que la mise en
/// page "téléphone" empilée.
const double _seuilGrandEcran = 900;

class Ecran extends StatefulWidget {
  const Ecran({super.key});

  @override
  State<Ecran> createState() => _EcranState();
}

class _EcranState extends State<Ecran> {
  late final ReprisePlayerController _controller = ReprisePlayerController(
    repriseClub3GrandPrix,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verifierTutoriel());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
    await _controller.reinitialiser();
  }

  /// Change la taille de la carrière (20×60 ↔ 20×40). Les lettres, les
  /// positions et le tracé de toutes les figures sont recalculés. Rien
  /// n'est supprimé : une figure qui ne rentre pas dans la nouvelle
  /// carrière est simplement signalée ⚠️ et non tracée.
  Future<void> _changerTaille(TailleCarriere nouvelle) async {
    final ancienne = Lettres.taille;
    if (nouvelle == ancienne) return;

    Lettres.taille = nouvelle;
    final incompatibles = _controller.mouvements
        .where((m) => !m.estCompatibleCarriereActuelle)
        .length;
    Lettres.taille = ancienne;

    if (incompatibles > 0) {
      if (!mounted) return;
      final continuer = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Passer en ${nouvelle.label} ?'),
          content: Text(
            '$incompatibles mouvement(s) de votre reprise ne rentrent pas '
            'dans cette carrière (lettre absente ou figure trop grande). '
            'Ils restent dans votre reprise — rien n\'est supprimé — mais '
            'seront signalés ⚠️ et non tracés. Vous pouvez revenir à '
            'l\'ancienne taille quand vous voulez.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Changer quand même'),
            ),
          ],
        ),
      );
      if (continuer != true || !mounted) return;
    }

    Lettres.taille = nouvelle;
    _controller.carriereChangee();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text('EquiTools - Dressage'),
        ),
        actions: [
          // 👤 compte (affiché seulement si Firebase est configuré)
          ListenableBuilder(
            listenable: ServiceCompte.instance,
            builder: (context, _) {
              final compte = ServiceCompte.instance;
              if (!compte.disponible) return const SizedBox.shrink();
              return IconButton(
                tooltip: compte.estConnecte ? 'Mon compte' : 'Se connecter',
                icon: Icon(
                  compte.estConnecte
                      ? Icons.account_circle
                      : Icons.account_circle_outlined,
                ),
                onPressed: () => ouvrirCompte(context, _controller),
              );
            },
          ),
          IconButton(
            tooltip: 'Protocole PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () =>
                partagerProtocolePdf(context, _controller.mouvements),
          ),
          IconButton(
            tooltip: "Réinitialiser à l'exemple",
            icon: const Icon(Icons.refresh),
            onPressed: _reinitialiser,
          ),
          const MenuInfos(),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 📏 choix de la taille de la carrière
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Text(
                    'Carrière :',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SegmentedButton<TailleCarriere>(
                      showSelectedIcon: false,
                      segments: [
                        for (final t in TailleCarriere.values)
                          ButtonSegment(value: t, label: Text(t.label)),
                      ],
                      selected: {Lettres.taille},
                      onSelectionChanged: (s) => _changerTaille(s.first),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final grandEcran = constraints.maxWidth >= _seuilGrandEcran;
                  return grandEcran
                      ? _MiseEnPageOrdinateur(controller: _controller)
                      : _MiseEnPageTelephone(controller: _controller);
                },
              ),
            ),

            // Petit espace pour ne pas coller la pub aux boutons du
            // lecteur juste au-dessus (cf. contrainte n°10).
            const SizedBox(height: 20),

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

/// Mise en page "ordinateur" : Figures | Carrière | Allures, trois
/// colonnes côte à côte (cf. étape 1 du cahier des charges).
class _MiseEnPageOrdinateur extends StatelessWidget {
  final ReprisePlayerController controller;

  const _MiseEnPageOrdinateur({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 260,
          child: FiguresPanel(controller: controller),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: ReprisePlayer(
            controller: controller,
            // Le panneau de gauche s'occupe déjà d'ajouter des figures ;
            // on garde "Supprimer" dans les contrôles, mais pas un second
            // bouton "Ajouter" en double.
            afficherBoutonsAjouterSupprimer: false,
          ),
        ),
        const VerticalDivider(width: 1),
        SizedBox(width: 280, child: AlluresPanel(controller: controller)),
      ],
    );
  }
}

/// Mise en page "téléphone" : tout empilé verticalement, comme avant.
class _MiseEnPageTelephone extends StatelessWidget {
  final ReprisePlayerController controller;

  const _MiseEnPageTelephone({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔵 légende des allures
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            children: Famille.values.map((allure) {
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
                  Text(allure.label, style: const TextStyle(fontSize: 12)),
                ],
              );
            }).toList(),
          ),
        ),

        // 🐴 carrière + lecteur de reprise
        Expanded(
          child: ReprisePlayer(controller: controller, controlesALCote: true),
        ),

        // 📋 liste de la reprise  ·  🐎 allures de la figure choisie
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _ouvrirFeuille(
                    context,
                    ListeReprise(controller: controller),
                  ),
                  icon: const Text('📋'),
                  label: const Text('Ma reprise'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _ouvrirFeuille(
                    context,
                    AlluresPanel(controller: controller),
                  ),
                  icon: const Text('🐎'),
                  label: const Text('Allures'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void _ouvrirFeuille(BuildContext context, Widget contenu) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: contenu,
    ),
  );
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
            _Point(icon: Icons.delete_outline, texte: 'Supprimez le mouvement affiché avec "Supprimer".'),
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
