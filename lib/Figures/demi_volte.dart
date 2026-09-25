import 'package:flutter/material.dart';
import 'package:reprise_dressage_app/lettres.dart';
import 'package:reprise_dressage_app/Figures/transition.dart';

class DemiVolte extends CustomPainter {
  final Offset fromLetter;
  final Offset toLetter;
  final double diameter;
  final Color color;
  final double w;
  final double h;
  final List<Transition> transitions;

  DemiVolte(
    this.fromLetter,
    this.toLetter,
    this.diameter,
    this.color,
    this.w,
    this.h, [
    this.transitions = const [],
  ]);

  static Path buildPath(
    Offset fromLetter,
    Offset toLetter,
    double diameter,
    double w,
    double h,
  ) {
    final diameterPx = diameter / Lettres.width * w;
    final radius = diameterPx / 2;

    // L'angle de départ ET le sens doivent dépendre du côté du rail : sinon
    // le rail droit produit un demi-cercle miroir (mauvais sens) par rapport
    // au rail gauche pour la même orientation de trajet.
    double radiusSide;
    double startAngle;
    double sensSiVersLeBas; // sens à utiliser si fromLetter.dy < toLetter.dy
    if (fromLetter.dx == w) {
      radiusSide = -radius;
      startAngle = 0;
      sensSiVersLeBas = -3.14;
    } else {
      radiusSide = radius;
      startAngle = 3.14;
      sensSiVersLeBas = 3.14;
    }
    final sens = (fromLetter.dy < toLetter.dy)
        ? sensSiVersLeBas
        : -sensSiVersLeBas;

    return Path()
      ..arcTo(
        Rect.fromCircle(
          center: Offset(fromLetter.dx + radiusSide, fromLetter.dy),
          radius: radius,
        ),
        startAngle,
        sens,
        false,
      )
      ..lineTo(toLetter.dx, toLetter.dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildPath(fromLetter, toLetter, diameter, w, h);
    Transition.draw(canvas, path, color, transitions, w, h);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
