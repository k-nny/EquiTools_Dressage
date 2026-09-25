import 'package:flutter/material.dart';

/// Position + orientation d'un point situé à une fraction donnée d'un [Path],
/// utilisé pour animer un repère (ex. le cheval) le long d'un tracé.
class PathPoint {
  final Offset position;
  final double angle; // radians, direction du déplacement (pour orienter le repère)

  const PathPoint(this.position, this.angle);
}

/// Petits utilitaires pour parcourir un [Path] composé d'un ou plusieurs
/// contours (ex. la serpentine, qui peut en avoir plusieurs) comme une seule
/// trajectoire continue.
class PathAnimation {
  PathAnimation._();

  /// Longueur totale du tracé, tous contours confondus.
  static double totalLength(Path path) {
    return path
        .computeMetrics()
        .fold(0.0, (sum, metric) => sum + metric.length);
  }

  /// Position (et orientation) sur le tracé à la distance [distance] (en
  /// pixels, depuis le départ). Retourne null si le tracé est vide.
  static PathPoint? pointAtDistance(Path path, double distance) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return null;

    double target = distance < 0 ? 0 : distance;

    for (final metric in metrics) {
      if (target <= metric.length || metric == metrics.last) {
        final double localTarget = target < 0
            ? 0
            : (target > metric.length ? metric.length : target);
        final tangent = metric.getTangentForOffset(localTarget);
        if (tangent != null) {
          return PathPoint(tangent.position, tangent.angle);
        }
        return null;
      }
      target -= metric.length;
    }
    return null;
  }

  /// Position (et orientation) sur le tracé à la fraction [t] (0 = départ,
  /// 1 = arrivée). Retourne null si le tracé est vide.
  static PathPoint? pointAtFraction(Path path, double t) {
    final total = totalLength(path);
    if (total == 0) return null;
    final double clamped = t < 0 ? 0 : (t > 1 ? 1 : t);
    return pointAtDistance(path, clamped * total);
  }
}
