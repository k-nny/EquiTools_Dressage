import 'package:flutter/material.dart';

import 'package:reprise_dressage_app/lettres.dart';
import 'package:reprise_dressage_app/reprise.dart';

/// Dessine l'ensemble des mouvements de la reprise sur la carrière.
/// Le mouvement à l'index [highlightIndex] (s'il est fourni) est tracé
/// plus épais, pour repérer facilement où on en est.
class _ReprisePainter extends CustomPainter {
  final List<Mouvement> mouvements;
  final int? highlightIndex;

  final TailleCarriere taille = Lettres.taille;

  _ReprisePainter(this.mouvements, this.highlightIndex);

  @override
  void paint(Canvas canvas, Size size) {
    final int dernierMouvementVisible = highlightIndex ?? mouvements.length - 1;

    for (var i = 0; i <= dernierMouvementVisible; i++) {
      mouvements[i].paintOn(
        canvas,
        size.width,
        size.height,
        strokeWidth: i == highlightIndex ? 6 : 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ReprisePainter oldDelegate) {
    return oldDelegate.highlightIndex != highlightIndex ||
        oldDelegate.mouvements != mouvements ||
        oldDelegate.taille != taille;
  }
}

/// La carrière : le rectangle balisé, ses lettres, et le tracé complet
/// (statique) de la reprise passée en paramètre.
class Carriere extends StatelessWidget {
  final List<Mouvement> mouvements;
  final int? highlightIndex;

  const Carriere({super.key, required this.mouvements, this.highlightIndex});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(width: 2),
                color: Colors.amber[100],
              ),
            ),
            CustomPaint(
              size: Size(w, h),
              painter: _ReprisePainter(mouvements, highlightIndex),
            ),
            ...Lettres.letters.entries.map(
              (entry) => _lettre(entry.key, entry.value, w, h),
            ),
          ],
        );
      },
    );
  }

  Widget _lettre(String letter, Offset positionMeters, double w, double h) {
    const fontSize = 14.0;
    const charW = fontSize * 0.5;

    final x = positionMeters.dx / Lettres.width * w;
    final y = positionMeters.dy / Lettres.length * h;

    double left = x - charW / 2;
    double top = y - fontSize / 2;
    Color color = Colors.grey;

    // lettres extérieures
    if (letter == 'A') {
      top = -fontSize * 1.5;
      color = Colors.black;
    } else if (letter == 'C') {
      top = h + fontSize * 0.5;
      color = Colors.black;
    } else if (positionMeters.dx == 0) {
      left = -charW * 2;
      color = Colors.black;
    } else if (positionMeters.dx == Lettres.width) {
      left = w + charW;
      color = Colors.black;
    }

    return Positioned(
      left: left,
      top: top,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
