import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:reprise_dressage_app/lettres.dart';
import 'package:reprise_dressage_app/Figures/transition.dart';

/// La demi-volte "renversée" : contrairement à la demi-volte classique
/// (demi-cercle puis diagonale), elle commence par la diagonale (ligne
/// droite depuis la piste) puis rejoint la piste par un demi-cercle.
class DemiVolteRenversee extends CustomPainter {
  final Offset fromLetter;
  final Offset toLetter;
  final double diameter;
  final Color color;
  final double w;
  final double h;
  final List<Transition> transitions;

  DemiVolteRenversee(
    this.fromLetter,
    this.toLetter,
    this.diameter,
    this.color,
    this.w,
    this.h, [
    this.transitions = const [],
  ]);

  /// [fromLetter] et [toLetter] sont tous deux sur la piste (même grand
  /// côté). Le tracé part de [fromLetter] en ligne droite jusqu'au point
  /// diamétralement opposé à [toLetter] (symétrique de la demi-volte
  /// classique), puis rejoint [toLetter] par un demi-cercle.
  static Path buildPath(
    Offset fromLetter,
    Offset toLetter,
    double diameter,
    double w,
    double h,
  ) {
    final diameterPx = diameter / Lettres.width * w;
    final radius = diameterPx / 2;

    double radiusSide;
    double startAngle; // angle de toLetter sur le cercle
    if (toLetter.dx == w) {
      radiusSide = -radius;
      startAngle = 0;
    } else {
      radiusSide = radius;
      startAngle = 3.14;
    }
    final sens = (fromLetter.dy < toLetter.dy) ? 3.14 : -3.14;

    final center = Offset(toLetter.dx + radiusSide, toLetter.dy);
    final pAngle = startAngle + 3.14; // point diamétralement opposé à toLetter
    final p = Offset(
      center.dx + radius * math.cos(pAngle),
      center.dy + radius * math.sin(pAngle),
    );

    return Path()
      ..moveTo(fromLetter.dx, fromLetter.dy)
      ..lineTo(p.dx, p.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        pAngle,
        sens,
        false,
      );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildPath(fromLetter, toLetter, diameter, w, h);
    Transition.draw(canvas, path, color, transitions, w, h);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
