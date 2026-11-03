import 'package:flutter/material.dart';
import 'package:reprise_dressage_app/Figures/transition.dart';
import 'package:reprise_dressage_app/lettres.dart';

class DemiCercle extends CustomPainter {
  final Offset prevLetter;
  final Offset fromLetter;
  final double diameter;
  final Color color;
  final double w;
  final double h;
  final List<Transition> transitions;

  DemiCercle(
    this.prevLetter,
    this.fromLetter,
    this.diameter,
    this.color,
    this.w,
    this.h, [
    this.transitions = const [],
  ]);

  static Path buildPath(
    Offset prevLetter,
    Offset fromLetter,
    double diameter,
    double w,
    double h,
  ) {
    final diameterPx = diameter / Lettres.width * w;
    final radius = diameterPx / 2;

    // Lettre sur un petit côté (A ou C) : le demi-cercle part du centre du
    // petit côté, dans le sens d'où l'on vient, et rentre dans la carrière
    // (diamètre perpendiculaire au petit côté, bombé sur le côté).
    if (fromLetter.dy == 0 || fromLetter.dy == h) {
      final enHaut = fromLetter.dy == 0;
      final versGauche = prevLetter.dx > fromLetter.dx; // on vient de la droite
      final centre = Offset(
        fromLetter.dx,
        enHaut ? fromLetter.dy + radius : fromLetter.dy - radius,
      );
      final angleDepart = enHaut ? -3.14 / 2 : 3.14 / 2;
      // En haut : sens négatif = vers la gauche ; en bas : l'inverse.
      final sensCourt = (enHaut == versGauche) ? -3.14 : 3.14;
      return Path()
        ..arcTo(
          Rect.fromCircle(center: centre, radius: radius),
          angleDepart,
          sensCourt,
          false,
        );
    }

    double radiusSide;
    double startAngle;
    double sens;

    if (fromLetter.dx == w) {
      radiusSide = -radius;
      startAngle = 0;
      sens = (prevLetter.dy > fromLetter.dy) ? -3.14 : 3.14;
    } else {
      radiusSide = radius;
      startAngle = 3.14;
      sens = (prevLetter.dy > fromLetter.dy) ? 3.14 : -3.14;
    }

    final rect = Rect.fromCircle(
      center: Offset(fromLetter.dx + radiusSide, fromLetter.dy),
      radius: radius,
    );

    return Path()..arcTo(rect, startAngle, sens, false);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildPath(prevLetter, fromLetter, diameter, w, h);
    Transition.draw(canvas, path, color, transitions, w, h);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
