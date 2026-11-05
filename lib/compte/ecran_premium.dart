import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:reprise_dressage_app/compte/achats/achats.dart';
import 'package:reprise_dressage_app/compte/ecran_compte.dart';
import 'package:reprise_dressage_app/compte/premium_config.dart';
import 'package:reprise_dressage_app/compte/service_compte.dart';
import 'package:reprise_dressage_app/compte/service_premium.dart';
import 'package:reprise_dressage_app/reprise_controller.dart';
import 'package:reprise_dressage_app/theme.dart';

/// Écran « Premium » : comparaison gratuit / Premium, puis souscription
/// (ou gestion de l'abonnement si l'utilisateur est déjà Premium).
class EcranPremium extends StatefulWidget {
  final ReprisePlayerController controller;

  const EcranPremium({super.key, required this.controller});

  @override
  State<EcranPremium> createState() => _EcranPremiumState();
}

class _EcranPremiumState extends State<EcranPremium> {
  bool _occupe = false;
  String? _erreur;
  String? _info;
  Future<List<OffreAchat>>? _offres;

  Future<void> _lancer(Future<void> Function() action) async {
    setState(() {
      _occupe = true;
      _erreur = null;
      _info = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _erreur = e.toString());
    } finally {
      if (mounted) setState(() => _occupe = false);
    }
  }

  String _date(DateTime d) {
    String deux(int n) => n.toString().padLeft(2, '0');
    return '${deux(d.day)}/${deux(d.month)}/${d.year}';
  }

  Widget _carte({required Widget child, Color? couleur}) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: couleur ?? Palette.carte,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Palette.traitFin),
    ),
    child: child,
  );

  Widget _ligne(String texte, {String puce = '✓'}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          puce,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Palette.cuir,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(texte)),
      ],
    ),
  );

  Widget _formule({
    required String titre,
    required String prix,
    required String plan,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Palette.creme,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Palette.cuir.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Text(titre, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(prix, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _occupe
                    ? null
                    : () => _lancer(
                        () => ServicePremium.instance.ouvrirPaiement(plan),
                      ),
                child: const Text('Choisir'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Version Android / iOS : formules et prix fournis par le magasin.
  Widget _offresMagasin() {
    return _carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choisissez votre formule',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<OffreAchat>>(
            future: _offres ??= ServicePremium.instance.offresIntegrees(),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final offres = snap.data ?? const <OffreAchat>[];
              if (snap.hasError || offres.isEmpty) {
                return const Text(
                  'Les abonnements ne sont pas disponibles pour le moment. '
                  'Réessayez plus tard.',
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final o in offres)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Palette.creme,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Palette.cuir.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              o.titre,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(o.prix, textAlign: TextAlign.center),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _occupe
                                    ? null
                                    : () => _lancer(() async {
                                        await ServicePremium.instance
                                            .acheterIntegre(o);
                                        if (mounted) {
                                          setState(
                                            () => _info =
                                                'Merci ! Activation en cours…',
                                          );
                                        }
                                      }),
                                child: const Text('Choisir'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _occupe
                  ? null
                  : () => _lancer(() async {
                      await ServicePremium.instance.restaurerAchats();
                      if (mounted) {
                        setState(
                          () => _info = 'Achats restaurés (si un abonnement existe).',
                        );
                      }
                    }),
              child: const Text('Restaurer mes achats'),
            ),
          ),
          const Text(
            'L\'abonnement est facturé via votre compte Google Play / '
            'App Store et se renouvelle automatiquement à la fin de chaque '
            'période, sauf résiliation au moins 24 h avant, depuis les '
            'réglages d\'abonnements de votre compte de store.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ServiceCompte.instance,
        ServicePremium.instance,
      ]),
      builder: (context, _) {
        final compte = ServiceCompte.instance;
        final premium = ServicePremium.instance;

        if (!compte.estConnecte) {
          return _carte(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connectez-vous pour passer Premium : l\'abonnement est '
                  'rattaché à votre compte.',
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ouvrirCompte(context, widget.controller),
                  child: const Text('Me connecter'),
                ),
              ],
            ),
          );
        }

        if (premium.estPremium) {
          final fin = premium.jusqua;
          return _carte(
            couleur: Palette.sable,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✨ Vous êtes Premium. Merci !',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                if (fin != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    premium.annulationPrevue
                        ? 'Abonnement résilié : actif jusqu\'au ${_date(fin)}.'
                        : 'Prochain renouvellement le ${_date(fin)}.',
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _occupe
                      ? null
                      : () => _lancer(ServicePremium.instance.ouvrirGestion),
                  child: const Text('Gérer mon abonnement'),
                ),
              ],
            ),
          );
        }

        if (premium.achatIntegre) return _offresMagasin();

        return _carte(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choisissez votre formule',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _formule(
                    titre: 'Mensuel',
                    prix: prixMensuel,
                    plan: 'mensuel',
                  ),
                  _formule(titre: 'Annuel', prix: prixAnnuel, plan: 'annuel'),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Paiement sécurisé par Stripe. Résiliable à tout moment '
                'depuis « Gérer mon abonnement ».',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('✨ Premium')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            _carte(
              couleur: Palette.cuir,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Passez au niveau supérieur',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Soutenez EquiTools et débloquez les avantages Premium.',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            _carte(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Plan gratuit — déjà inclus',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  for (final a in avantagesGratuit) _ligne(a),
                ],
              ),
            ),
            _carte(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'En plus avec Premium',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  if (avantagesPremium.isEmpty)
                    const Text(
                      'Les avantages Premium seront détaillés ici très '
                      'bientôt.',
                    )
                  else
                    for (final a in avantagesPremium) _ligne(a, puce: '✨'),
                ],
              ),
            ),
            _actions(),
            if (_erreur != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(_erreur!, style: const TextStyle(color: Colors.red)),
              ),
            if (_info != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(_info!, style: const TextStyle(color: Colors.green)),
              ),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse(
                      '${urlApi.replaceFirst('/api', '')}/conditions-de-vente.html',
                    ),
                    webOnlyWindowName: '_blank',
                  ),
                  child: const Text('Conditions de vente'),
                ),
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse(
                      '${urlApi.replaceFirst('/api', '')}/confidentialite.html',
                    ),
                    webOnlyWindowName: '_blank',
                  ),
                  child: const Text('Confidentialité'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
