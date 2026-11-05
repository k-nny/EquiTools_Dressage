import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Adresse du site : les pages d'information (guide, confidentialité...)
/// y sont hébergées en HTML (dossier web/).
const String _urlSite = 'https://equi-tools-dressage.vercel.app';

const List<(String, String)> _pages = [
  ('guide.html', "Guide d'utilisation"),
  ('a-propos.html', 'À propos'),
  ('confidentialite.html', 'Confidentialité'),
  ('mentions-legales.html', 'Mentions légales'),
  ('conditions-de-vente.html', 'Conditions de vente'),
  ('contact.html', 'Contact'),
];

/// Menu « ⋮ » de la barre du haut : ouvre les pages d'information dans le
/// navigateur. N'a aucun effet sur le fonctionnement de l'appli.
class MenuInfos extends StatelessWidget {
  const MenuInfos({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Informations',
      onSelected: (fichier) => launchUrl(
        Uri.parse('$_urlSite/$fichier'),
        mode: LaunchMode.externalApplication,
      ),
      itemBuilder: (context) => [
        for (final (fichier, titre) in _pages)
          PopupMenuItem<String>(value: fichier, child: Text(titre)),
      ],
    );
  }
}
