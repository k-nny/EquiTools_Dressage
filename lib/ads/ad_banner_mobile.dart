import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Identifiants de TEST officiels Google — sans danger à laisser dans le
/// dépôt, ils ne génèrent jamais de vrais revenus/impressions facturées.
/// Documentation : https://developers.google.com/admob/flutter/test-ads
///
/// ⚠️ Avant publication : remplacez [_idBanniereTestAndroid] et
/// [_idBanniereTestIOS] par vos identifiants de production réels (créés
/// dans votre compte AdMob), et pensez aussi à mettre à jour l'App ID dans
/// android/app/src/main/AndroidManifest.xml et ios/Runner/Info.plist.
const String _idBanniereTestAndroid = 'ca-app-pub-3940256099942544/6300978111';
const String _idBanniereTestIOS = 'ca-app-pub-3940256099942544/2934735716';

enum _EtatBanniere { chargement, chargee, erreur }

/// Bannière publicitaire AdMob (Android/iOS). Voir ad_banner.dart pour la
/// façon dont ce widget doit être placé dans l'écran, et
/// ad_banner_stub.dart pour l'équivalent Web (qui partage la même API).
class AdBanner extends StatefulWidget {
  /// Si vrai, aucune publicité n'est chargée ni affichée (utilisateur
  /// Premium).
  final bool isPremium;

  const AdBanner({super.key, required this.isPremium});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  // Le SDK ne doit être initialisé qu'une seule fois par process, même si
  // plusieurs AdBanner apparaissent sur plusieurs écrans.
  static bool _sdkInitialise = false;

  BannerAd? _bannerAd;
  _EtatBanniere _etat = _EtatBanniere.chargement;
  bool _demandeEnCours = false;

  String get _adUnitId =>
      Platform.isAndroid ? _idBanniereTestAndroid : _idBanniereTestIOS;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery (nécessaire pour la taille adaptative de la bannière)
    // n'est disponible de façon fiable qu'à partir d'ici, pas d'initState.
    if (!widget.isPremium && !_demandeEnCours && _bannerAd == null) {
      _demandeEnCours = true;
      _chargerBanniere();
    }
  }

  @override
  void didUpdateWidget(covariant AdBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPremium && !oldWidget.isPremium) {
      // Passage gratuit -> Premium en cours de session : on libère la pub.
      _bannerAd?.dispose();
      _bannerAd = null;
      _demandeEnCours = false;
      setState(() => _etat = _EtatBanniere.chargement);
    } else if (!widget.isPremium && oldWidget.isPremium) {
      _demandeEnCours = true;
      _chargerBanniere();
    }
  }

  Future<void> _chargerBanniere() async {
    if (!_sdkInitialise) {
      await MobileAds.instance.initialize();
      _sdkInitialise = true;
    }
    if (!mounted) return;

    // Taille adaptative : la bannière s'ajuste à la largeur réelle de
    // l'écran (téléphone comme tablette), avec la hauteur optimale que
    // Google calcule pour cette largeur.
    final largeur = MediaQuery.sizeOf(context).width.truncate();
    final taille = await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      largeur,
    );

    if (!mounted) return;
    if (taille == null) {
      setState(() => _etat = _EtatBanniere.erreur);
      return;
    }

    final banniere = BannerAd(
      adUnitId: _adUnitId,
      size: taille,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _etat = _EtatBanniere.chargee;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() => _etat = _EtatBanniere.erreur);
        },
      ),
    );

    banniere.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPremium) return const SizedBox.shrink();

    final ad = _bannerAd;
    // Chargement en cours, ou échec : on ne réserve aucun espace, pour ne
    // jamais laisser une zone vide pousser le contenu au-dessus.
    if (_etat != _EtatBanniere.chargee || ad == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: ad.size.height.toDouble(),
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
