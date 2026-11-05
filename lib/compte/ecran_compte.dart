import 'package:flutter/material.dart';

import 'package:reprise_dressage_app/compte/ecran_premium.dart';
import 'package:reprise_dressage_app/compte/mes_reprises.dart';
import 'package:reprise_dressage_app/compte/service_premium.dart';
import 'package:reprise_dressage_app/compte/service_compte.dart';
import 'package:reprise_dressage_app/reprise_controller.dart';

/// Ouvre la fenêtre « Mon compte » : connexion / création de compte si
/// l'utilisateur n'est pas connecté, sinon son e-mail et la déconnexion.
Future<void> ouvrirCompte(
  BuildContext context,
  ReprisePlayerController controller,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => _DialogCompte(controller: controller),
  );
}

class _DialogCompte extends StatefulWidget {
  final ReprisePlayerController controller;

  const _DialogCompte({required this.controller});

  @override
  State<_DialogCompte> createState() => _DialogCompteState();
}

class _DialogCompteState extends State<_DialogCompte> {
  final _email = TextEditingController();
  final _mdp = TextEditingController();
  bool _inscription = false;
  bool _occupe = false;
  String? _erreur;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _mdp.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    final email = _email.text.trim();
    final mdp = _mdp.text;
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _erreur = "Saisissez une adresse e-mail valide.");
      return;
    }
    if (mdp.length < 6) {
      setState(() => _erreur = 'Le mot de passe doit faire 6 caractères minimum.');
      return;
    }
    setState(() {
      _occupe = true;
      _erreur = null;
      _info = null;
    });
    try {
      if (_inscription) {
        await ServiceCompte.instance.inscrire(email, mdp);
      } else {
        await ServiceCompte.instance.connecter(email, mdp);
      }
    } catch (e) {
      if (mounted) setState(() => _erreur = ServiceCompte.messageErreur(e));
    } finally {
      if (mounted) setState(() => _occupe = false);
    }
  }

  Future<void> _oublie() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() {
        _erreur = "Saisissez d'abord votre adresse e-mail.";
        _info = null;
      });
      return;
    }
    setState(() {
      _occupe = true;
      _erreur = null;
      _info = null;
    });
    try {
      await ServiceCompte.instance.motDePasseOublie(email);
      if (mounted) {
        setState(() => _info = 'E-mail de réinitialisation envoyé à $email.');
      }
    } catch (e) {
      if (mounted) setState(() => _erreur = ServiceCompte.messageErreur(e));
    } finally {
      if (mounted) setState(() => _occupe = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ServiceCompte.instance,
      builder: (context, _) {
        final compte = ServiceCompte.instance;
        if (compte.estConnecte) return _vueConnecte(context, compte);
        return _vueFormulaire(context);
      },
    );
  }

  Widget _vueConnecte(BuildContext context, ServiceCompte compte) {
    return AlertDialog(
      title: const Text('👋 Mon compte'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Connecté en tant que :'),
            const SizedBox(height: 4),
            Text(
              compte.email ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            ListenableBuilder(
              listenable: ServicePremium.instance,
              builder: (context, _) {
                final premium = ServicePremium.instance.estPremium;
                return FilledButton.tonalIcon(
                  icon: const Text('✨'),
                  label: Text(premium ? 'Mon abonnement Premium' : 'Passer Premium'),
                  onPressed: () {
                    final nav = Navigator.of(context);
                    nav.pop();
                    nav.push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            EcranPremium(controller: widget.controller),
                      ),
                    );
                  },
                );
              },
            ),
            const Divider(height: 28),
            MesReprises(controller: widget.controller),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
        FilledButton(
          onPressed: () async {
            await compte.deconnecter();
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Se déconnecter'),
        ),
      ],
    );
  }

  Widget _vueFormulaire(BuildContext context) {
    return AlertDialog(
      title: Text(_inscription ? 'Créer un compte' : 'Se connecter'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Créez un compte gratuit pour sauvegarder jusqu\'à 3 reprises '
              'et les retrouver sur tous vos appareils.',
              style: TextStyle(fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _email,
              enabled: !_occupe,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Adresse e-mail'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _mdp,
              enabled: !_occupe,
              obscureText: true,
              autofillHints: [
                _inscription
                    ? AutofillHints.newPassword
                    : AutofillHints.password,
              ],
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              onSubmitted: (_) => _valider(),
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 10),
              Text(_erreur!, style: const TextStyle(color: Colors.red)),
            ],
            if (_info != null) ...[
              const SizedBox(height: 10),
              Text(_info!, style: const TextStyle(color: Colors.green)),
            ],
            const SizedBox(height: 8),
            if (!_inscription)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _occupe ? null : _oublie,
                  child: const Text('Mot de passe oublié ?'),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _occupe
                    ? null
                    : () => setState(() {
                        _inscription = !_inscription;
                        _erreur = null;
                        _info = null;
                      }),
                child: Text(
                  _inscription
                      ? 'J\'ai déjà un compte : me connecter'
                      : 'Pas de compte ? En créer un',
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _occupe ? null : _valider,
          child: _occupe
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_inscription ? 'Créer mon compte' : 'Me connecter'),
        ),
      ],
    );
  }
}
