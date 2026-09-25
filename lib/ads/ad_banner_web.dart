import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Identifiant client AdSense — PLACEHOLDER. Remplacez par votre vrai
/// "ca-pub-XXXXXXXXXXXXXXXX" (compte AdSense approuvé) avant publication,
/// ET mettez à jour la même valeur dans le <script> de web/index.html.
const String _idClientAdSense = 'ca-pub-0000000000000000';

/// Emplacement ("ad slot") AdSense — PLACEHOLDER. Remplacez par un vrai
/// numéro d'emplacement créé dans votre compte AdSense.
const String _idEmplacementAdSense = '0000000000';

const String _viewType = 'reprise-dressage-adsense-banner';
bool _factoryEnregistree = false;

/// Enregistre (une seule fois par session) la fabrique qui crée l'élément
/// HTML <ins class="adsbygoogle"> utilisé par AdSense. Doit être appelé en
/// dehors d'un build (ici : dans initState).
void _enregistrerFactorySiBesoin() {
  if (_factoryEnregistree) return;
  _factoryEnregistree = true;

  ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
    final ins = html.Element.tag('ins')
      ..className = 'adsbygoogle'
      ..style.display = 'block'
      ..style.width = '100%'
      ..style.height = '100%'
      ..setAttribute('data-ad-client', _idClientAdSense)
      ..setAttribute('data-ad-slot', _idEmplacementAdSense)
      ..setAttribute('data-ad-format', 'auto')
      ..setAttribute('data-full-width-responsive', 'true')
      // ⚠️ Mode test AdSense : affiche une pub factice sans compte réel.
      // À RETIRER avant publication, une fois vos vrais identifiants
      // ci-dessus renseignés.
      ..setAttribute('data-adtest', 'on');

    // On laisse le temps à Flutter d'insérer l'élément dans le DOM avant
    // de demander à AdSense de le remplir.
    html.window.requestAnimationFrame((_) => _demanderChargementPub());

    return ins;
  });
}

void _demanderChargementPub() {
  try {
    final existant = js.context['adsbygoogle'];
    final tableau = existant is js.JsArray
        ? existant
        : js.JsArray.from(const []);
    tableau.add(js.JsObject.jsify(const {}));
    js.context['adsbygoogle'] = tableau;
  } catch (_) {
    // Le script AdSense (web/index.html) n'est pas encore chargé, ou le
    // compte n'est pas configuré : on ne fait rien de plus, la zone reste
    // simplement vide plutôt que de planter l'app.
  }
}

/// Bannière publicitaire pour le Web, via Google AdSense (et non AdMob,
/// qui ne prend pas en charge le Web). Voir ad_banner.dart pour la façon
/// dont ce widget doit être placé dans l'écran, et ad_banner_mobile.dart /
/// ad_banner_stub.dart pour les équivalents Android/iOS, qui partagent la
/// même API.
///
/// Contrairement à AdMob, AdSense ne renvoie pas de taille exacte une fois
/// la pub chargée : la zone réservée ici a donc une hauteur fixe et
/// raisonnable (format "banner" standard du Web), plutôt qu'une taille
/// recalculée dynamiquement.
class AdBanner extends StatefulWidget {
  /// Si vrai, aucune publicité n'est affichée (utilisateur Premium).
  final bool isPremium;

  const AdBanner({super.key, required this.isPremium});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  static const double _hauteurZone = 90;

  @override
  void initState() {
    super.initState();
    if (!widget.isPremium) {
      _enregistrerFactorySiBesoin();
    }
  }

  @override
  void didUpdateWidget(covariant AdBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isPremium && oldWidget.isPremium) {
      _enregistrerFactorySiBesoin();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPremium) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: SizedBox(
        width: double.infinity,
        height: _hauteurZone,
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }
}
