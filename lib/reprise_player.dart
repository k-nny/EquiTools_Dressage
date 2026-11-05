import 'package:flutter/material.dart';
import 'package:reprise_dressage_app/theme.dart';

import 'package:reprise_dressage_app/carriere.dart';
import 'package:reprise_dressage_app/lettres.dart';
import 'package:reprise_dressage_app/reprise.dart';
import 'package:reprise_dressage_app/reprise_controller.dart';
import 'package:reprise_dressage_app/Figures/path_animation.dart';
import 'package:reprise_dressage_app/Figures/transition.dart';
import 'package:reprise_dressage_app/mouvement_editor.dart';

/// Un segment du tracé (distances de début/fin en pixels, durée en
/// secondes déjà mise à l'échelle) — utilisé pour que le cheval
/// accélère/ralentisse exactement là où la couleur change, sans jamais
/// désynchroniser la durée totale de l'animation et la distance parcourue.
typedef _SegmentTiming = (
  double debut,
  double fin,
  double duree,
  Allure allure,
);

double _clampD(double v, double lo, double hi) {
  if (lo > hi) return (lo + hi) / 2;
  return v < lo ? lo : (v > hi ? hi : v);
}

/// Lecteur de reprise : affiche la carrière avec le tracé complet, anime un
/// cheval le long du mouvement en cours (à une vitesse qui varie selon
/// l'allure, y compris en cours de mouvement si l'allure change), et
/// propose Précédent / Lecture / Suivant pour naviguer dans la reprise.
///
/// La liste de mouvements elle-même vit dans [controller], partagé avec
/// d'éventuels panneaux externes (ex. un panneau "Figures" sur PC qui
/// ajoute des mouvements sans passer par les boutons de ce widget).
class ReprisePlayer extends StatefulWidget {
  final ReprisePlayerController controller;
  final bool afficherBoutonsAjouterSupprimer;

  /// Mise en page "téléphone" : la carrière (très haute et étroite, 20×60)
  /// est placée à gauche et prend toute la hauteur disponible, et le
  /// bandeau + les contrôles sont empilés à sa droite, au lieu d'être
  /// au-dessus et en dessous (ce qui écrasait la carrière).
  final bool controlesALCote;

  const ReprisePlayer({
    super.key,
    required this.controller,
    this.afficherBoutonsAjouterSupprimer = true,
    this.controlesALCote = false,
  });

  @override
  State<ReprisePlayer> createState() => _ReprisePlayerState();
}

class _ReprisePlayerState extends State<ReprisePlayer>
    with SingleTickerProviderStateMixin {
  static const double _horseSize = 28;

  late final AnimationController _controller;

  bool _isPlaying = false;
  double _vitesse = 1;
  int _dureeBaseMs = 1000;

  double _w = 0;
  double _h = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener(_onStatusChanged);
    widget.controller.addListener(_onListeChangee);
  }

  /// La liste ou la position courante a changé (ajout/suppression/
  /// navigation, que ce soit depuis les boutons de ce widget ou depuis un
  /// panneau externe) : on arrête toute animation en cours et on repart du
  /// début du nouveau mouvement courant.
  void _onListeChangee() {
    _controller.stop();
    _controller.value = 0;

    if (_isPlaying) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_isPlaying || widget.controller.estVide) return;
        _playCurrent();
      });
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatusChanged);
    widget.controller.removeListener(_onListeChangee);
    _controller.dispose();
    super.dispose();
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && _isPlaying) {
      _advance();
    }
  }

  /// Découpe le tracé du mouvement en segments (un par allure, coupés
  /// exactement aux points de transition de couleur), avec pour chacun sa
  /// durée. Les durées "physiques" (distance / vitesse) sont mises à
  /// l'échelle pour que leur somme corresponde exactement à la durée totale
  /// bridée (sinon le cheval n'atteint jamais la fin du tracé quand la durée
  /// réelle dépasse la borne haute). Recalculé à la demande (mouvement
  /// court, coût négligeable) pour ne jamais désynchroniser durée et
  /// position.
  (List<_SegmentTiming>, double) _profilVitesse(Mouvement mvt, Path path) {
    final totalLen = PathAnimation.totalLength(path);
    final pixelsParMetre = _h / Lettres.length;
    final cuts = Transition.computeCuts(path, mvt.transitions, _w, _h);

    final bornes = <(double, double, Allure)>[];
    double start = 0;
    Allure allureCourante = mvt.allure;
    for (final (cutAt, color) in cuts) {
      if (cutAt > start) bornes.add((start, cutAt, allureCourante));
      start = cutAt;
      allureCourante = Allure.values.firstWhere(
        (a) => a.couleur == color,
        orElse: () => allureCourante,
      );
    }
    bornes.add((start, totalLen, allureCourante));

    final rawDurations = <double>[];
    double rawTotal = 0;
    for (final (segStart, segEnd, allure) in bornes) {
      final vitessePx = allure.vitesseMetresParSeconde * pixelsParMetre;
      final d = vitessePx > 0 ? (segEnd - segStart) / vitessePx : 0.0;
      rawDurations.add(d);
      rawTotal += d;
    }

    final totalSeconds = _clampD(rawTotal, 0.8, 12.0);
    final scale = rawTotal > 0 ? totalSeconds / rawTotal : 1.0;

    final timings = <_SegmentTiming>[];
    for (var i = 0; i < bornes.length; i++) {
      final (segStart, segEnd, allureSeg) = bornes[i];
      timings.add((segStart, segEnd, rawDurations[i] * scale, allureSeg));
    }

    return (timings, totalSeconds);
  }

  void _advance() {
    final controller = widget.controller;

    if (controller.estVide) return;

    if (controller.estDernier) {
      setState(() => _isPlaying = false);
      return;
    }

    controller.allerA(controller.currentIndex + 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isPlaying || controller.estVide) return;
      _playCurrent();
    });
  }

  void _playCurrent() {
    final controller = widget.controller;
    if (controller.estVide || _w == 0 || _h == 0) return;

    final mvt = controller.courant;
    if (mvt is MvtArret) {
      _dureeBaseMs = 1600;
    } else {
      final path = mvt.buildPathSafe(_w, _h);
      if (path == null) {
        // Mouvement incompatible avec la carrière actuelle : on ne
        // l'anime pas, on passe simplement au suivant après un instant.
        _dureeBaseMs = 800;
      } else {
        final (_, totalSeconds) = _profilVitesse(mvt, path);
        _dureeBaseMs = (totalSeconds * 1000).round();
      }
    }
    _controller.duration = Duration(milliseconds: _dureeAvecVitesse());
    _controller.forward(from: 0);
  }

  /// Durée réelle du mouvement en cours, une fois la vitesse (1×, 2×, 4×)
  /// appliquée : toute l'animation accélère, le cheval ne "saute" pas.
  int _dureeAvecVitesse() {
    final ms = (_dureeBaseMs / _vitesse).round();
    return ms < 40 ? 40 : ms;
  }

  void _changerVitesse(double v) {
    setState(() => _vitesse = v);
    if (_isPlaying) {
      _controller.duration = Duration(milliseconds: _dureeAvecVitesse());
      _controller.forward(); // reprend là où il en est, à la nouvelle vitesse
    }
  }

  void _togglePlay() {
    final controller = widget.controller;
    if (controller.estVide) return;
    if (_isPlaying) {
      _controller.stop();
      setState(() => _isPlaying = false);
      return;
    }

    setState(() => _isPlaying = true);
    if (_controller.value == 0) {
      _playCurrent();
    } else {
      _controller.forward();
    }
  }

  void _goTo(int index) => widget.controller.allerA(index);

  Future<void> _ajouterFigure() async {
    final mvt = await showMouvementEditor(context);
    if (mvt == null || !mounted) return;
    widget.controller.ajouter(mvt);
  }

  void _supprimerCourant() => widget.controller.supprimerCourant();

  PathPoint _horsePosition() {
    final controller = widget.controller;
    if (controller.estVide) return const PathPoint(Offset.zero, 0);
    final mvt = controller.courant;
    if (mvt is MvtArret) {
      final position = Lettres.getLetterOrNull(mvt.letter);
      if (position == null) return const PathPoint(Offset.zero, 0);
      return PathPoint(Lettres.toPixels(position, _w, _h), 0);
    }

    final path = mvt.buildPathSafe(_w, _h);
    if (path == null) return const PathPoint(Offset.zero, 0);
    final (timings, totalSeconds) = _profilVitesse(mvt, path);
    if (timings.isEmpty || totalSeconds == 0) {
      return PathAnimation.pointAtFraction(path, _controller.value) ??
          const PathPoint(Offset.zero, 0);
    }

    final (distance, _) = _distanceEtAllure(timings, totalSeconds);
    return PathAnimation.pointAtDistance(path, distance) ??
        const PathPoint(Offset.zero, 0);
  }

  /// Distance parcourue (en pixels) et allure du segment en cours, selon
  /// l'avancement de l'animation.
  (double, Allure) _distanceEtAllure(
    List<_SegmentTiming> timings,
    double totalSeconds,
  ) {
    final elapsed = _controller.value * totalSeconds;
    double distance = timings.last.$2;
    Allure allure = timings.last.$4;
    double t = 0;
    for (var i = 0; i < timings.length; i++) {
      final (segStart, segEnd, segDuration, segAllure) = timings[i];
      final isLast = i == timings.length - 1;

      if (elapsed <= t + segDuration || isLast) {
        final localElapsed = _clampD(elapsed - t, 0, segDuration);
        final fraction = segDuration > 0 ? localElapsed / segDuration : 0.0;
        distance = segStart + fraction * (segEnd - segStart);
        allure = segAllure;
        break;
      }
      t += segDuration;
    }
    return (distance, allure);
  }

  /// Allure à afficher dans le bandeau : celle du mouvement, ou — pendant
  /// la lecture d'un mouvement qui change d'allure — celle du moment.
  Allure _allureAffichee() {
    final controller = widget.controller;
    if (controller.estVide) return Allure.arret;
    final mvt = controller.courant;
    if (mvt is MvtArret) return Allure.arret;
    if (mvt.transitions.isEmpty || _w == 0 || _h == 0) return mvt.allure;
    final path = mvt.buildPathSafe(_w, _h);
    if (path == null) return mvt.allure;
    final (timings, totalSeconds) = _profilVitesse(mvt, path);
    if (timings.isEmpty || totalSeconds == 0) return mvt.allure;
    return _distanceEtAllure(timings, totalSeconds).$2;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        if (!controller.chargementTermine) {
          return const Center(child: CircularProgressIndicator());
        }
        final compact = widget.controlesALCote;

        final bandeau = AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => _MouvementBandeau(
            index: controller.currentIndex,
            total: controller.mouvements.length,
            mouvement: controller.estVide ? null : controller.courant,
            allure: _allureAffichee(),
            compact: compact,
          ),
        );

        final carriere = Center(
          child: AspectRatio(
            aspectRatio: Lettres.width / Lettres.length,
            child: LayoutBuilder(
              builder: (context, constraints) {
                _w = constraints.maxWidth;
                _h = constraints.maxHeight;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Carriere(
                      mouvements: controller.mouvements,
                      highlightIndex: controller.estVide
                          ? null
                          : controller.currentIndex,
                    ),
                    if (!controller.estVide)
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          final point = _horsePosition();
                          return Positioned(
                            left: point.position.dx - _horseSize / 2,
                            top: point.position.dy - _horseSize / 2,
                            child: const IgnorePointer(
                              child: Text(
                                '🐴',
                                style: TextStyle(fontSize: _horseSize),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        );

        final controles = _Controles(
          isPlaying: _isPlaying,
          vitesse: _vitesse,
          onVitesse: _changerVitesse,
          canPrevious: !controller.estVide && !controller.estPremier,
          canNext: !controller.estVide && !controller.estDernier,
          canPlay: !controller.estVide,
          canDelete: !controller.estVide,
          afficherAjouterSupprimer: widget.afficherBoutonsAjouterSupprimer,
          compact: compact,
          onPrevious: () => _goTo(controller.currentIndex - 1),
          onNext: () => _goTo(controller.currentIndex + 1),
          onPlayPause: _togglePlay,
          onAdd: _ajouterFigure,
          onDelete: _supprimerCourant,
        );

        if (compact) {
          // Carrière à gauche (marges pour les lettres A, C et celles des
          // côtés, qui sont dessinées à l'extérieur du rectangle), bandeau
          // et contrôles à droite.
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 11,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(10, 4, 0, 4),
                  padding: const EdgeInsets.fromLTRB(28, 30, 20, 30),
                  decoration: _decorationPrairie(),
                  child: carriere,
                ),
              ),
              Expanded(
                flex: 9,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(10, 4, 12, 4),
                  child: Column(
                    children: [
                      bandeau,
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
                        decoration: _decorationCarte(),
                        child: controles,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            bandeau,
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 30,
                ),
                decoration: _decorationPrairie(),
                child: carriere,
              ),
            ),
            const SizedBox(height: 10),
            controles,
          ],
        );
      },
    );
  }
}

class _MouvementBandeau extends StatelessWidget {
  static const double _hauteurFixe = 100;

  final int index;
  final int total;
  final Mouvement? mouvement;
  final Allure allure;

  /// Mode "à côté de la carrière" : pas de hauteur fixe (le texte peut
  /// passer sur plusieurs lignes dans la colonne étroite).
  final bool compact;

  const _MouvementBandeau({
    required this.index,
    required this.total,
    required this.mouvement,
    required this.allure,
    this.compact = false,
  });

  double? get _hauteur => compact ? null : _hauteurFixe;
  double get _margeH => compact ? 4 : 16;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: compact ? 0 : 16, vertical: 4),
      padding: EdgeInsets.symmetric(vertical: compact ? 10 : 0),
      decoration: _decorationCarte(),
      child: _contenu(context),
    );
  }

  Widget _contenu(BuildContext context) {
    final mvt = mouvement;
    if (mvt == null) {
      return SizedBox(
        height: _hauteur,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: _margeH),
            child: const Text(
              'Aucune figure — ajoutez-en une avec le bouton "+"',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    if (!mvt.estCompatibleCarriereActuelle) {
      return SizedBox(
        height: _hauteur,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: _margeH),
            child: Text(
              '⚠️ « ${mvt.description} » ne peut pas être tracé dans cette '
              'carrière (lettre absente ou figure trop grande).',
              textAlign: TextAlign.center,
              maxLines: compact ? 8 : 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.deepOrange,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: _hauteur,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: _margeH),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Figure ${index + 1} sur $total',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 2),
            Text(
              mvt.description,
              textAlign: TextAlign.center,
              maxLines: compact ? 6 : 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 15 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: allure.couleur,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    allure == Allure.arret
                        ? 'Arrêt'
                        : 'Allure : ${allure.label}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Controles extends StatelessWidget {
  final bool isPlaying;
  final double vitesse;
  final bool canPrevious;
  final bool canNext;
  final bool canPlay;
  final bool canDelete;
  final bool afficherAjouterSupprimer;

  /// Mode étroit (à droite de la carrière sur téléphone) : boutons
  /// empilés et vitesse sous son libellé.
  final bool compact;
  final ValueChanged<double> onVitesse;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPlayPause;
  final VoidCallback onAdd;
  final VoidCallback onDelete;

  const _Controles({
    required this.isPlaying,
    required this.vitesse,
    required this.canPrevious,
    required this.canNext,
    required this.canPlay,
    required this.canDelete,
    required this.afficherAjouterSupprimer,
    this.compact = false,
    required this.onVitesse,
    required this.onPrevious,
    required this.onNext,
    required this.onPlayPause,
    required this.onAdd,
    required this.onDelete,
  });

  Widget _buildCompact() {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            IconButton(
              iconSize: 32,
              tooltip: 'Figure précédente',
              icon: const Icon(Icons.skip_previous),
              onPressed: canPrevious ? onPrevious : null,
            ),
            IconButton.filled(
              iconSize: 32,
              tooltip: isPlaying ? 'Pause' : 'Lecture',
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: canPlay ? onPlayPause : null,
            ),
            IconButton(
              iconSize: 32,
              tooltip: 'Figure suivante',
              icon: const Icon(Icons.skip_next),
              onPressed: canNext ? onNext : null,
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Vitesse :', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: SegmentedButton<double>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 1.0, label: Text('1×')),
              ButtonSegment(value: 2.0, label: Text('2×')),
              ButtonSegment(value: 4.0, label: Text('4×')),
            ],
            selected: {vitesse},
            onSelectionChanged: (s) => onVitesse(s.first),
          ),
        ),
        if (afficherAjouterSupprimer) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter', overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: canDelete ? onDelete : null,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Supprimer', overflow: TextOverflow.ellipsis),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              iconSize: 36,
              tooltip: 'Figure précédente',
              icon: const Icon(Icons.skip_previous),
              onPressed: canPrevious ? onPrevious : null,
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              iconSize: 36,
              tooltip: isPlaying ? 'Pause' : 'Lecture',
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: canPlay ? onPlayPause : null,
            ),
            const SizedBox(width: 8),
            IconButton(
              iconSize: 36,
              tooltip: 'Figure suivante',
              icon: const Icon(Icons.skip_next),
              onPressed: canNext ? onNext : null,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Vitesse :',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            SegmentedButton<double>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 1.0, label: Text('1×')),
                ButtonSegment(value: 2.0, label: Text('2×')),
                ButtonSegment(value: 4.0, label: Text('4×')),
              ],
              selected: {vitesse},
              onSelectionChanged: (s) => onVitesse(s.first),
            ),
          ],
        ),
        if (afficherAjouterSupprimer) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Ajouter',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canDelete ? onDelete : null,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text(
                      'Supprimer',
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}


/// Fond « prairie » autour de la carrière (purement décoratif).
BoxDecoration _decorationPrairie() => BoxDecoration(
  color: Palette.prairie,
  borderRadius: BorderRadius.circular(22),
);

/// Petite carte blanche arrondie (bandeau de la figure, contrôles).
BoxDecoration _decorationCarte() => BoxDecoration(
  color: Palette.carte,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: Palette.traitFin),
  boxShadow: const [
    BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
  ],
);
