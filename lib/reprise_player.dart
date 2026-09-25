import 'package:flutter/material.dart';

import 'package:reprise_dressage_app/carriere.dart';
import 'package:reprise_dressage_app/lettres.dart';
import 'package:reprise_dressage_app/reprise.dart';
import 'package:reprise_dressage_app/Figures/path_animation.dart';
import 'package:reprise_dressage_app/Figures/transition.dart';
import 'package:reprise_dressage_app/mouvement_editor.dart';
import 'package:reprise_dressage_app/reprise_storage.dart';

/// Un segment du tracé (distances de début/fin en pixels, durée en
/// secondes déjà mise à l'échelle) — utilisé pour que le cheval
/// accélère/ralentisse exactement là où la couleur change, sans jamais
/// désynchroniser la durée totale de l'animation et la distance parcourue.
typedef _SegmentTiming = (double debut, double fin, double duree);

double _clampD(double v, double lo, double hi) {
  if (lo > hi) return (lo + hi) / 2;
  return v < lo ? lo : (v > hi ? hi : v);
}

/// Lecteur de reprise : affiche la carrière avec le tracé complet, anime un
/// cheval le long du mouvement en cours (à une vitesse qui varie selon
/// l'allure, y compris en cours de mouvement si l'allure change), et
/// propose Précédent / Lecture / Suivant pour naviguer dans la reprise.
class ReprisePlayer extends StatefulWidget {
  final List<Mouvement> mouvements;

  const ReprisePlayer({super.key, required this.mouvements});

  @override
  State<ReprisePlayer> createState() => _ReprisePlayerState();
}

class _ReprisePlayerState extends State<ReprisePlayer>
    with SingleTickerProviderStateMixin {
  static const double _horseSize = 28;

  late final AnimationController _controller;
  late List<Mouvement> _mouvements;

  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _chargementTermine = false;

  double _w = 0;
  double _h = 0;

  @override
  void initState() {
    super.initState();
    _mouvements = List.of(widget.mouvements);
    _controller = AnimationController(vsync: this)
      ..addStatusListener(_onStatusChanged);
    _chargerDepuisStockage();
  }

  /// Reprend la reprise sauvegardée sur cet appareil, si elle existe.
  /// Sinon, garde celle passée en paramètre (l'exemple par défaut).
  Future<void> _chargerDepuisStockage() async {
    final sauvegarde = await ReprisesStorage.chargerReprise();
    if (!mounted) return;
    setState(() {
      if (sauvegarde != null) {
        _mouvements = sauvegarde;
        _currentIndex = 0;
      }
      _chargementTermine = true;
    });
  }

  void _sauvegarder() {
    ReprisesStorage.sauvegarderReprise(_mouvements);
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatusChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && _isPlaying) {
      _advance();
    }
  }

  bool get _estVide => _mouvements.isEmpty;
  Mouvement get _current => _mouvements[_currentIndex];

  bool get _isLast => _currentIndex == _mouvements.length - 1;
  bool get _isFirst => _currentIndex == 0;

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
      final (segStart, segEnd, _) = bornes[i];
      timings.add((segStart, segEnd, rawDurations[i] * scale));
    }

    return (timings, totalSeconds);
  }

  void _advance() {
    if (_estVide) return;
    if (_isLast) {
      setState(() => _isPlaying = false);
      return;
    }
    setState(() => _currentIndex++);
    _playCurrent();
  }

  void _playCurrent() {
    if (_estVide || _w == 0 || _h == 0) return;

    final mvt = _current;
    if (mvt is MvtArret) {
      _controller.duration = const Duration(milliseconds: 1600);
    } else {
      final (_, totalSeconds) = _profilVitesse(mvt, mvt.buildPath(_w, _h));
      _controller.duration = Duration(
        milliseconds: (totalSeconds * 1000).round(),
      );
    }
    _controller.forward(from: 0);
  }

  void _togglePlay() {
    if (_estVide) return;
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

  void _goTo(int index) {
    if (_estVide) return;
    _controller.stop();
    setState(() {
      _isPlaying = false;
      _currentIndex = index.clamp(0, _mouvements.length - 1).toInt();
    });
    _controller.value = 0;
  }

  Future<void> _ajouterFigure() async {
    final mvt = await showMouvementEditor(context);
    if (mvt == null || !mounted) return;
    _controller.stop();
    setState(() {
      _isPlaying = false;
      final insertAt = _estVide ? 0 : _currentIndex + 1;
      _mouvements.insert(insertAt, mvt);
      _currentIndex = insertAt;
    });
    _controller.value = 0;
    _sauvegarder();
  }

  void _supprimerCourant() {
    if (_estVide) return;
    _controller.stop();
    setState(() {
      _isPlaying = false;
      _mouvements.removeAt(_currentIndex);
      if (_mouvements.isEmpty) {
        _currentIndex = 0;
      } else if (_currentIndex >= _mouvements.length) {
        _currentIndex = _mouvements.length - 1;
      }
    });
    _controller.value = 0;
    _sauvegarder();
  }

  PathPoint _horsePosition() {
    if (_estVide) return const PathPoint(Offset.zero, 0);
    final mvt = _current;
    if (mvt is MvtArret) {
      return PathPoint(Lettres.letterToPixels(mvt.letter, _w, _h), 0);
    }

    final path = mvt.buildPath(_w, _h);
    final (timings, totalSeconds) = _profilVitesse(mvt, path);
    if (timings.isEmpty || totalSeconds == 0) {
      return PathAnimation.pointAtFraction(path, _controller.value) ??
          const PathPoint(Offset.zero, 0);
    }

    final elapsed = _controller.value * totalSeconds;

    double distance = timings.last.$2;
    double t = 0;
    for (var i = 0; i < timings.length; i++) {
      final (segStart, segEnd, segDuration) = timings[i];
      final isLast = i == timings.length - 1;

      if (elapsed <= t + segDuration || isLast) {
        final localElapsed = _clampD(elapsed - t, 0, segDuration);
        final fraction = segDuration > 0 ? localElapsed / segDuration : 0.0;
        distance = segStart + fraction * (segEnd - segStart);
        break;
      }
      t += segDuration;
    }

    return PathAnimation.pointAtDistance(path, distance) ??
        const PathPoint(Offset.zero, 0);
  }

  @override
  Widget build(BuildContext context) {
    if (!_chargementTermine) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        _MouvementBandeau(
          index: _currentIndex,
          total: _mouvements.length,
          mouvement: _estVide ? null : _current,
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1 / 3,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _w = constraints.maxWidth;
                  _h = constraints.maxHeight;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Carriere(
                        mouvements: _mouvements,
                        highlightIndex: _estVide ? null : _currentIndex,
                      ),
                      if (!_estVide)
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
          ),
        ),
        const SizedBox(height: 10),
        _Controles(
          isPlaying: _isPlaying,
          canPrevious: !_estVide && !_isFirst,
          canNext: !_estVide && !_isLast,
          canPlay: !_estVide,
          canDelete: !_estVide,
          onPrevious: () => _goTo(_currentIndex - 1),
          onNext: () => _goTo(_currentIndex + 1),
          onPlayPause: _togglePlay,
          onAdd: _ajouterFigure,
          onDelete: _supprimerCourant,
        ),
      ],
    );
  }
}

class _MouvementBandeau extends StatelessWidget {
  static const double _hauteur = 76;

  final int index;
  final int total;
  final Mouvement? mouvement;

  const _MouvementBandeau({
    required this.index,
    required this.total,
    required this.mouvement,
  });

  @override
  Widget build(BuildContext context) {
    final mvt = mouvement;
    if (mvt == null) {
      return const SizedBox(
        height: _hauteur,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Aucune figure — ajoutez-en une avec le bouton "+"',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: _hauteur,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Mouvement ${index + 1} / $total',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: mvt.allure.couleur,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    mvt.description,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
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
  final bool canPrevious;
  final bool canNext;
  final bool canPlay;
  final bool canDelete;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPlayPause;
  final VoidCallback onAdd;
  final VoidCallback onDelete;

  const _Controles({
    required this.isPlaying,
    required this.canPrevious,
    required this.canNext,
    required this.canPlay,
    required this.canDelete,
    required this.onPrevious,
    required this.onNext,
    required this.onPlayPause,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              iconSize: 32,
              icon: const Icon(Icons.skip_previous),
              onPressed: canPrevious ? onPrevious : null,
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              iconSize: 32,
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: canPlay ? onPlayPause : null,
            ),
            const SizedBox(width: 8),
            IconButton(
              iconSize: 32,
              icon: const Icon(Icons.skip_next),
              onPressed: canNext ? onNext : null,
            ),
          ],
        ),
        const SizedBox(height: 4),
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
    );
  }
}
