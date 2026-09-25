import 'package:flutter/material.dart';
import 'transition.dart';

class LigneDroite extends CustomPainter {
  final Offset fromLetter;
  final Offset toLetter;
  final double w;
  final double h;
  final Color color;
  final List<Transition> transitions;

  LigneDroite(
    this.fromLetter,
    this.toLetter,
    this.w,
    this.h,
    this.color, [
    this.transitions = const [],
  ]);

  static Path buildPath(Offset fromLetter, Offset toLetter) {
    return Path()
      ..moveTo(fromLetter.dx, fromLetter.dy)
      ..lineTo(toLetter.dx, toLetter.dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildPath(fromLetter, toLetter);
    Transition.draw(canvas, path, color, transitions, w, h);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
