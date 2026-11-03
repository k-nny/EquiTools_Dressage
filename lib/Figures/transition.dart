import 'dart:ui';

import 'package:reprise_dressage_app/lettres.dart';

/// Représente un changement de couleur sur une figure.
/// Deux façons de définir le point de coupure :
///   - [Transition.surLettre] : quand on croise le x ou le y d'une lettre
///   - [Transition.surLigne]  : quand on croise la ligne imaginaire entre deux lettres
class Transition {
  final String? letter;
  final String? lineFrom;
  final String? lineTo;
  final Color colorAfter;

  /// Coupure à hauteur d'une lettre (croise son x OU son y)
  const Transition.surLettre(this.letter, this.colorAfter)
    : lineFrom = null,
      lineTo = null;

  /// Coupure quand on croise la ligne imaginaire entre deux lettres
  const Transition.surLigne(this.lineFrom, this.lineTo, this.colorAfter)
    : letter = null;

  /// Trouve la distance sur le path où la coupure doit se faire.
  /// Retourne null si le point de coupure n'est jamais croisé.
  double? findCutDistance(PathMetric metric, double w, double h) {
    if (letter != null) {
      return _cutByLetter(metric, w, h);
    } else {
      return _cutByLine(metric, w, h);
    }
  }

  /// Parcourt le path et retourne la distance où on croise
  /// le x ou le y de la lettre (tolérance 5m)
  double? _cutByLetter(PathMetric metric, double w, double h) {
    final ref = Lettres.getLetter(letter!);
    final refX = ref.dx / Lettres.width * w;
    final refY = ref.dy / Lettres.length * h;

    // Convertit 5 mètres en pixels
    final meterX = 5 / Lettres.width * w;
    final meterY = 5 / Lettres.length * h;

    double? bestT;
    double bestDist = double.infinity;

    for (double t = 0; t <= metric.length; t += 1.0) {
      final pos = metric.getTangentForOffset(t)?.position;
      if (pos == null) continue;

      if ((pos.dx - refX).abs() < meterX && (pos.dy - refY).abs() < meterY) {
        // Parmi tous les points dans la tolérance, on prend le plus proche de la lettre
        final dist = (pos - Offset(refX, refY)).distance;
        if (dist < bestDist) {
          bestDist = dist;
          bestT = t;
        }
      }
    }
    return bestT;
  }

  /// Parcourt le path et retourne la distance où on croise
  /// la ligne imaginaire entre les deux lettres
  double? _cutByLine(PathMetric metric, double w, double h) {
    final a = Lettres.getLetter(lineFrom!);
    final b = Lettres.getLetter(lineTo!);

    final ax = a.dx / Lettres.width * w;
    final ay = a.dy / Lettres.length * h;
    final bx = b.dx / Lettres.width * w;
    final by = b.dy / Lettres.length * h;

    Offset? prev;
    for (double t = 0; t <= metric.length; t += 1.0) {
      final pos = metric.getTangentForOffset(t)?.position;
      if (pos == null) continue;

      if (prev != null &&
          _segmentsIntersect(prev, pos, Offset(ax, ay), Offset(bx, by))) {
        return t;
      }
      prev = pos;
    }
    return null;
  }

  /// Vérifie si le segment [p1,p2] croise le segment [p3,p4]
  bool _segmentsIntersect(Offset p1, Offset p2, Offset p3, Offset p4) {
    final d1x = p2.dx - p1.dx;
    final d1y = p2.dy - p1.dy;
    final d2x = p4.dx - p3.dx;
    final d2y = p4.dy - p3.dy;

    final denom = d1x * d2y - d1y * d2x;
    if (denom == 0) return false; // segments parallèles, pas d'intersection

    final t = ((p3.dx - p1.dx) * d2y - (p3.dy - p1.dy) * d2x) / denom;
    final u = ((p3.dx - p1.dx) * d1y - (p3.dy - p1.dy) * d1x) / denom;

    return t >= 0 && t <= 1 && u >= 0 && u <= 1;
  }

  /// Calcule les distances de coupure (triées, cumulées sur tout le tracé)
  /// pour une liste de transitions. Réutilisé par [draw] et par le lecteur
  /// (pour faire varier la vitesse du cheval selon la couleur en cours).
  static List<(double, Color)> computeCuts(
    Path path,
    List<Transition> transitions,
    double w,
    double h,
  ) {
    final allMetrics = path.computeMetrics().toList();
    final cuts = <(double, Color)>[];
    for (final t in transitions) {
      double offset = 0;
      for (final metric in allMetrics) {
        double? cutAt;
        try {
          cutAt = t.findCutDistance(metric, w, h);
        } catch (_) {
          // Lettre de la transition absente de la carrière actuelle
          // (ex. 'L' en 20×40) : on ignore simplement cette transition.
          break;
        }
        if (cutAt != null) {
          cuts.add((offset + cutAt, t.colorAfter));
          break;
        }
        offset += metric.length;
      }
    }
    cuts.sort((a, b) => a.$1.compareTo(b.$1));
    return cuts;
  }

  /// Dessine le path en segments colorés selon la liste de transitions.
  /// Les transitions sont triées automatiquement dans l'ordre du tracé.
  ///
  /// Exemple :
  ///   Transition.draw(canvas, path, Colors.blue, [
  ///     Transition.surLettre('X', Colors.red),
  ///     Transition.surLigne('B', 'E', Colors.green),
  ///   ], w, h);
  static void draw(
    Canvas canvas,
    Path path,
    Color color,
    List<Transition> transitions,
    double w,
    double h, {
    double strokeWidth = 4,
  }) {
    if (transitions.isEmpty) {
      canvas.drawPath(path, _paint(color, strokeWidth));
      return;
    }

    final allMetrics = path.computeMetrics().toList();
    final cuts = computeCuts(path, transitions, w, h);

    // Dessine segment par segment sur toutes les métriques
    double globalPos = 0;
    Color current = color;
    int cutIndex = 0;

    for (final metric in allMetrics) {
      double start = 0;

      while (cutIndex < cuts.length) {
        final (cutAt, newColor) = cuts[cutIndex];
        final localCut = cutAt - globalPos;

        if (localCut > metric.length) {
          break; // coupure dans une prochaine métrique
        }

        canvas.drawPath(
          metric.extractPath(start, localCut),
          _paint(current, strokeWidth),
        );
        start = localCut;
        current = newColor;
        cutIndex++;
      }

      canvas.drawPath(
        metric.extractPath(start, metric.length),
        _paint(current, strokeWidth),
      );
      globalPos += metric.length;
    }
  }

  /// Crée un Paint pour tracer un chemin avec la couleur et l'épaisseur données
  static Paint _paint(Color c, [double strokeWidth = 4]) => Paint()
    ..color = c
    ..strokeWidth = strokeWidth
    ..style = PaintingStyle.stroke;
}
