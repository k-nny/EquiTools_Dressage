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
