import 'package:flutter/widgets.dart';

/// Version de [AdBanner] utilisée quand `dart:io` n'est pas disponible —
/// concrètement, le Web. Google Mobile Ads (AdMob) n'y est pas pris en
/// charge : ce stub n'affiche jamais rien et ne réserve aucun espace, pour
/// que le reste de l'écran ne bouge pas.
///
/// Ce fichier garde exactement la même API publique que
/// ad_banner_mobile.dart (même nom de classe, même constructeur) : c'est ce
/// qui permet à ad_banner.dart de basculer de l'un à l'autre selon la
/// plateforme sans que le reste de l'app ait à s'en soucier.
class AdBanner extends StatelessWidget {
  /// Si vrai, aucune publicité n'est affichée (utilisateur Premium).
  /// Conservé ici uniquement pour garder la même API que la version
  /// mobile ; il n'a aucun effet sur le Web puisque rien ne s'affiche de
  /// toute façon.
  final bool isPremium;

  const AdBanner({super.key, required this.isPremium});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
