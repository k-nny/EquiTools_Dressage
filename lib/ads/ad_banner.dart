/// Bannière publicitaire AdMob réutilisable, à placer en bas d'un écran :
///
/// ```dart
/// Scaffold(
///   body: Column(
///     children: [
///       Expanded(child: contenu),
///       AdBanner(isPremium: estUtilisateurPremium),
///     ],
///   ),
/// )
/// ```
///
/// N'affiche rien si [AdBanner.isPremium] est vrai, ni si la pub échoue à
/// charger. Trois implémentations selon la plateforme, qui partagent
/// toutes la même API publique :
///  - Android/iOS (ad_banner_mobile.dart) : AdMob, via google_mobile_ads.
///  - Web (ad_banner_web.dart) : AdSense, via un <ins class="adsbygoogle">
///    intégré au DOM.
///  - autres plateformes (ad_banner_stub.dart, ex. desktop) : rien.
library;

export 'ad_banner_stub.dart'
    if (dart.library.html) 'ad_banner_web.dart'
    if (dart.library.io) 'ad_banner_mobile.dart';
