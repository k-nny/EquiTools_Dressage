import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:reprise_dressage_app/lettres.dart';
import 'package:reprise_dressage_app/Figures/transition.dart';

class Cercle extends CustomPainter {
  final Offset center;
  final double diameter;
  final Color color;
  final double w;
  final double h;
  final List<Transition> transitions;
  final Offset? prevLetter;

  Cercle(
    this.center,
    this.diameter,
    this.color,
    this.w,
    this.h, [
    this.transitions = const [],
    this.prevLetter,
  ]);

  /// Construit le tracé du cercle (en pixels). Recale le centre si le point
  /// de référence est sur un bord, pour que le cercle reste tangent à la
  /// piste plutôt que de la déborder, et démarre le tracé exactement sur ce
  /// point de contact (utile pour que l'animation du cheval commence bien
  /// sur la lettre).
  ///
  /// [prevLetter], si fourni, donne le point d'où l'on vient : le sens du
  /// cercle (main droite / main gauche) est alors choisi pour prolonger en
  /// douceur la direction d'arrivée, comme pour [DemiCercle]. Sans
  /// [prevLetter], le cercle est tracé dans le sens par défaut (horaire).
  static Path buildPath(
    Offset center,
    double diameter,
    double w,
    double h, [
    Offset? prevLetter,
  ]) {
    final diameterPx = diameter / Lettres.width * w;
    final radius = diameterPx / 2;

    double cx = center.dx;
    double cy = center.dy;
    double startAngle = 0;
    double sens = 3.14; // sens par défaut si aucune direction n'est précisée

    if (center.dx == 0) {
      cx = radius;
      startAngle = math.pi; // point de contact à gauche du centre
      if (prevLetter != null) {
        sens = (prevLetter.dy > center.dy) ? 3.14 : -3.14;
      }
    } else if (center.dx == w) {
      cx = center.dx - radius;
      startAngle = 0; // point de contact à droite du centre
      if (prevLetter != null) {
        sens = (prevLetter.dy < center.dy) ? 3.14 : -3.14;
      }
    } else if (center.dy == 0) {
      cy = radius;
      startAngle = -math.pi / 2; // point de contact au-dessus du centre
      if (prevLetter != null) {
        sens = (prevLetter.dx < center.dx) ? 3.14 : -3.14;
      }
    } else if (center.dy == h) {
      cy = center.dy - radius;
      startAngle = math.pi / 2; // point de contact en dessous du centre
      if (prevLetter != null) {
        sens = (prevLetter.dx < center.dx) ? -3.14 : 3.14;
      }
    }

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    // Un balayage de 2π pile est un cas dégénéré pour arcTo (angle de départ
    // = angle d'arrivée modulo 2π) : certains moteurs ne tracent rien. On
    // trace donc le cercle en deux demi-tours (dans le [sens] choisi), ce
    // qui est toujours net et respecte la direction demandée.
    return Path()
      ..arcTo(rect, startAngle, sens, true)
      ..arcTo(rect, startAngle + sens, sens, false);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildPath(center, diameter, w, h, prevLetter);
    Transition.draw(canvas, path, color, transitions, w, h);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
