import 'package:flutter/material.dart';
import 'package:reprise_dressage_app/theme.dart';

import 'package:reprise_dressage_app/Figures/path_animation.dart';
import 'package:reprise_dressage_app/lettres.dart';
import 'package:reprise_dressage_app/reprise.dart';

/// Mini-carrière qui montre ce que fait une figure AVANT de l'ajouter :
/// le tracé (coloré selon l'allure), le point de départ (rond vert), la
/// direction (flèche) et un petit cheval qui la parcourt en boucle.
class FigurePreview extends StatefulWidget {
  final Mouvement mouvement;

  /// Largeur de la mini-carrière, en pixels (la hauteur en découle).
  final double largeur;

  const FigurePreview({super.key, required this.mouvement, this.largeur = 140});

  @override
  State<FigurePreview> createState() => _FigurePreviewState();
}

class _FigurePreviewState extends State<FigurePreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.largeur;
    final h = w * Lettres.length / Lettres.width;
    final path = widget.mouvement.buildPathSafe(w, h);
    final hors = path == null || !widget.mouvement.estCompatibleCarriereActuelle;

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(width: 2, color: Palette.charbon),
              color: Palette.sol,
            ),
          ),
          CustomPaint(
            size: Size(w, h),
            painter: _PreviewPainter(widget.mouvement, hors ? null : path),
          ),
          if (hors)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  '⚠️ Cette figure ne rentre pas dans la carrière avec ces '
                  'réglages',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepOrange,
                  ),
                ),
              ),
            )
          else
            AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                final p = PathAnimation.pointAtFraction(path, _anim.value);
                if (p == null) return const SizedBox.shrink();
                return Positioned(
                  left: p.position.dx - 9,
                  top: p.position.dy - 9,
                  child: const IgnorePointer(
                    child: Text('🐴', style: TextStyle(fontSize: 18)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  final Mouvement mouvement;
  final Path? path;
  final TailleCarriere taille = Lettres.taille;

  _PreviewPainter(this.mouvement, this.path);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Les lettres, discrètes, un peu à l'intérieur des bords.
    for (final e in Lettres.letters.entries) {
      final tp = TextPainter(
        text: TextSpan(
          text: e.key,
          style: const TextStyle(fontSize: 9, color: Colors.black45),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final pos = Lettres.toPixels(e.value, w, h);
      var x = pos.dx;
      var y = pos.dy;
      if (pos.dx <= 0) x += 7;
      if (pos.dx >= w) x -= 7;
      if (pos.dy <= 0) y += 7;
      if (pos.dy >= h) y -= 7;
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }

    final p = path;
    if (p == null) return;

    mouvement.paintOn(canvas, w, h, strokeWidth: 3);
    if (mouvement is MvtArret) return;

    final debut = PathAnimation.pointAtFraction(p, 0);
    if (debut != null) {
      canvas.drawCircle(debut.position, 4, Paint()..color = Colors.green);
    }

    // Flèche à l'arrivée, orientée dans le sens du déplacement.
    final fin = PathAnimation.pointAtFraction(p, 1);
    if (fin != null) {
      canvas.save();
      canvas.translate(fin.position.dx, fin.position.dy);
      canvas.rotate(fin.angle);
      final fleche = Path()
        ..moveTo(7, 0)
        ..lineTo(-4, -5)
        ..lineTo(-4, 5)
        ..close();
      canvas.drawPath(fleche, Paint()..color = mouvement.allure.couleur);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter old) => true;
}
