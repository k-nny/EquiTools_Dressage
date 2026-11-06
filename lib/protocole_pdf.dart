import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:reprise_dressage_app/lettres.dart';
import 'package:reprise_dressage_app/protocole_lignes.dart';
import 'package:reprise_dressage_app/reprise.dart';

// Couleurs du logo EquiTools (les couleurs d'allure, elles, viennent de
// reprise.dart).
final PdfColor _charbon = PdfColor.fromHex('#1D2225');
final PdfColor _or = PdfColor.fromHex('#B38328');
final PdfColor _orFonce = PdfColor.fromHex('#8F6A1D');
final PdfColor _orPale = PdfColor.fromHex('#F3EAD6');
final PdfColor _trait = PdfColor.fromHex('#BFB8A8');
final PdfColor _gris = PdfColor.fromHex('#6B6B66');

PdfColor _couleurAllure(Allure a) {
  final c = a.couleur;
  return PdfColor(c.r, c.g, c.b);
}

/// Génère le protocole de la reprise sous forme de PDF.
///
/// Une ligne par figure (numérotée, jamais coupée entre deux pages) avec
/// son repère, le nom donné par l'utilisateur, son allure et ses
/// changements d'allure. Le modèle « compétition » ajoute les colonnes
/// coefficient, note /10 et observations, laissées vides pour être
/// remplies à la main : aucun barème officiel n'est inventé.
Future<Uint8List> genererProtocolePdf(
  List<Mouvement> mouvements, {
  String titre = 'Protocole de la reprise',
  InfosProtocole infos = const InfosProtocole(),
  ModeleProtocole modele = ModeleProtocole.entrainement,
}) async {
  // Police embarquée : les polices PDF standard n'ont pas la flèche « → ».
  final normale = pw.Font.ttf(
    await rootBundle.load('assets/fonts/DejaVuSans.ttf'),
  );
  final grasse = pw.Font.ttf(
    await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf'),
  );

  // Logo (facultatif : si l'image est introuvable, le PDF se génère sans).
  final logo = await _chargerLogo();

  final lignes = lignesDuProtocole(mouvements);
  final competition = modele == ModeleProtocole.competition;
  final maintenant = DateTime.now();
  String deux(int n) => n.toString().padLeft(2, '0');
  final date =
      '${deux(maintenant.day)}/${deux(maintenant.month)}/${maintenant.year}';

  final titreAffiche = infos.reprise.isNotEmpty ? infos.reprise : titre;
  final nomModele = competition
      ? 'Protocole de compétition'
      : "Protocole d'entraînement";

  final doc = pw.Document(
    title: titreAffiche,
    author: 'EquiTools - Dressage',
    theme: pw.ThemeData.withFont(base: normale, bold: grasse),
  );

  // --- Colonnes ---------------------------------------------------------
  final colonnes = <int, pw.TableColumnWidth>{
    0: const pw.FixedColumnWidth(26),
    1: pw.FixedColumnWidth(competition ? 56 : 74),
    2: const pw.FlexColumnWidth(),
    3: pw.FixedColumnWidth(competition ? 74 : 100),
    if (competition) 4: const pw.FixedColumnWidth(34),
    if (competition) 5: const pw.FixedColumnWidth(40),
    if (competition) 6: const pw.FixedColumnWidth(110),
  };

  pw.Widget pastille(PdfColor couleur) => pw.Container(
    width: 8,
    height: 8,
    margin: const pw.EdgeInsets.only(top: 1.5),
    decoration: pw.BoxDecoration(color: couleur, shape: pw.BoxShape.circle),
  );

  pw.Widget cellule(pw.Widget enfant, {double? hauteurMin}) => pw.Container(
    constraints: hauteurMin == null
        ? null
        : pw.BoxConstraints(minHeight: hauteurMin),
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    child: enfant,
  );

  pw.Widget texteEntete(String t) => cellule(
    pw.Text(
      t,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
    ),
  );

  // Ligne d'en-tête des colonnes, répétée en haut de chaque page.
  pw.Widget enteteColonnes() => pw.Table(
    border: pw.TableBorder.all(color: _charbon, width: 0.5),
    columnWidths: colonnes,
    defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
    children: [
      pw.TableRow(
        decoration: pw.BoxDecoration(color: _charbon),
        children: [
          texteEntete('N°'),
          texteEntete('Repère'),
          texteEntete('Mouvement'),
          texteEntete('Allure'),
          if (competition) texteEntete('Coef.'),
          if (competition) texteEntete('Note /10'),
          if (competition) texteEntete('Observations'),
        ],
      ),
    ],
  );

  // Une figure = une table d'une seule ligne : elle n'est jamais coupée
  // entre deux pages (elle passe en entier sur la page suivante).
  pw.Widget ligneFigure(LigneProtocole l, int index) {
    final mouvementCellule = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          l.nom,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
        if (l.detail != null)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              l.detail!,
              style: pw.TextStyle(fontSize: 8.5, color: _gris),
            ),
          ),
        for (final c in l.changements)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pastille(
                  c.allure != null ? _couleurAllure(c.allure!) : _trait,
                ),
                pw.SizedBox(width: 4),
                pw.Expanded(
                  child: pw.Text(
                    '→ ${c.texte}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    final allureCellule = pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pastille(_couleurAllure(l.allure)),
        pw.SizedBox(width: 4),
        pw.Expanded(
          child: pw.Text(l.allure.label, style: const pw.TextStyle(fontSize: 9.5)),
        ),
      ],
    );

    return pw.Table(
      border: pw.TableBorder.all(color: _trait, width: 0.5),
      columnWidths: colonnes,
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.top,
      children: [
        pw.TableRow(
          decoration: index.isOdd ? pw.BoxDecoration(color: _orPale) : null,
          children: [
            cellule(
              pw.Text(
                '${l.numero}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _orFonce,
                ),
              ),
            ),
            cellule(
              pw.Text(
                l.repere,
                style: pw.TextStyle(
                  fontSize: 10.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            cellule(mouvementCellule),
            cellule(allureCellule),
            if (competition) cellule(pw.SizedBox(), hauteurMin: 34),
            if (competition) cellule(pw.SizedBox()),
            if (competition) cellule(pw.SizedBox()),
          ],
        ),
      ],
    );
  }

  // --- En-têtes ---------------------------------------------------------
  pw.Widget champ(String libelle, String valeur) => pw.Container(
    width: 250,
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          '$libelle : ',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 1),
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: _trait, width: 0.5)),
            ),
            child: pw.Text(valeur, style: const pw.TextStyle(fontSize: 10)),
          ),
        ),
      ],
    ),
  );

  pw.Widget enteteComplete() {
    // En compétition, les champs vides restent affichés (lignes à remplir à
    // la main) ; en entraînement, on n'affiche que ceux qui sont renseignés.
    final champs = <pw.Widget>[
      if (competition || infos.cavalier.isNotEmpty)
        champ('Cavalier', infos.cavalier),
      if (competition || infos.cheval.isNotEmpty) champ('Cheval', infos.cheval),
      if (competition || infos.niveau.isNotEmpty) champ('Niveau', infos.niveau),
      if (competition) champ('Juge', ''),
      champ('Carrière', Lettres.taille.label),
      champ('Date', date),
    ];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logo != null) pw.Image(logo, width: 48, height: 48),
            if (logo != null) pw.SizedBox(width: 10),
            pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: 'Equi',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: _charbon,
                    ),
                  ),
                  pw.TextSpan(
                    text: 'Tools',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: _or,
                    ),
                  ),
                  pw.TextSpan(
                    text: ' Dressage',
                    style: pw.TextStyle(fontSize: 14, color: _charbon),
                  ),
                ],
              ),
            ),
            pw.Spacer(),
            pw.Text(
              nomModele,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _orFonce,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 1.5, color: _or),
        pw.SizedBox(height: 10),
        pw.Text(
          titreAffiche,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: _charbon,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Wrap(spacing: 20, runSpacing: 8, children: champs),
        pw.SizedBox(height: 12),
        enteteColonnes(),
      ],
    );
  }

  pw.Widget enteteCompact() => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        children: [
          if (logo != null) pw.Image(logo, width: 20, height: 20),
          if (logo != null) pw.SizedBox(width: 6),
          pw.Text(
            titreAffiche,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.Spacer(),
          pw.Text(
            nomModele,
            style: pw.TextStyle(fontSize: 9, color: _orFonce),
          ),
        ],
      ),
      pw.SizedBox(height: 4),
      pw.Container(height: 1, color: _or),
      pw.SizedBox(height: 8),
      enteteColonnes(),
    ],
  );

  // --- Bas du document : remarques (et totaux en compétition) -----------
  pw.Widget boiteVide(String titreBoite, double hauteur) => pw.Container(
    height: hauteur,
    padding: const pw.EdgeInsets.all(6),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _trait, width: 0.5),
    ),
    child: pw.Align(
      alignment: pw.Alignment.topLeft,
      child: pw.Text(
        titreBoite,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: _orFonce,
        ),
      ),
    ),
  );

  pw.Widget basDeDocument() => pw.Container(
    margin: const pw.EdgeInsets.only(top: 16),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        if (competition)
          pw.Row(
            children: [
              pw.Expanded(child: boiteVide('Total des points', 32)),
              pw.SizedBox(width: 10),
              pw.Expanded(child: boiteVide('Pourcentage', 32)),
            ],
          ),
        if (competition) pw.SizedBox(height: 10),
        boiteVide('Remarques générales', 90),
      ],
    ),
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(34, 30, 34, 36),
      header: (context) =>
          context.pageNumber == 1 ? enteteComplete() : enteteCompact(),
      footer: (context) => pw.Row(
        children: [
          pw.Text(
            'Généré avec EquiTools - Dressage',
            style: pw.TextStyle(fontSize: 8, color: _gris),
          ),
          pw.Spacer(),
          pw.Text(
            'Page ${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: _gris),
          ),
        ],
      ),
      build: (context) => [
        if (lignes.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 12),
            child: pw.Text('La reprise est vide.'),
          )
        else
          for (var i = 0; i < lignes.length; i++) ligneFigure(lignes[i], i),
        if (lignes.isNotEmpty) basDeDocument(),
      ],
    ),
  );

  return doc.save();
}

/// Charge le logo pour le PDF ; renvoie null s'il est introuvable (le PDF
/// se génère alors sans logo).
Future<pw.MemoryImage?> _chargerLogo() async {
  try {
    final octets = await rootBundle.load('assets/images/logo_cercle.png');
    return pw.MemoryImage(octets.buffer.asUint8List());
  } catch (_) {
    return null;
  }
}

/// Nom de fichier du PDF : « protocole-<nom de la reprise>.pdf » (lettres
/// et chiffres seulement), ou « protocole-reprise.pdf » sans nom.
String _nomFichier(String reprise) {
  const accents = {
    'à': 'a', 'â': 'a', 'ä': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'î': 'i', 'ï': 'i', 'ô': 'o', 'ö': 'o', 'ù': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c',
  };
  final b = StringBuffer();
  for (final c in reprise.toLowerCase().split('')) {
    b.write(accents[c] ?? c);
  }
  final slug = b
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'protocole-reprise.pdf' : 'protocole-$slug.pdf';
}

/// Génère le PDF puis le télécharge (web) ou ouvre la feuille de partage
/// (Android/iOS).
Future<void> partagerProtocolePdf(
  BuildContext context,
  List<Mouvement> mouvements, {
  InfosProtocole infos = const InfosProtocole(),
  ModeleProtocole modele = ModeleProtocole.entrainement,
}) async {
  final messager = ScaffoldMessenger.of(context);
  if (mouvements.isEmpty) {
    messager.showSnackBar(
      const SnackBar(content: Text('Ta reprise est vide : rien à exporter.')),
    );
    return;
  }
  try {
    final octets = await genererProtocolePdf(
      mouvements,
      infos: infos,
      modele: modele,
    );
    await Printing.sharePdf(
      bytes: octets,
      filename: _nomFichier(infos.reprise),
    );
  } catch (_) {
    messager.showSnackBar(
      const SnackBar(
        content: Text("Impossible de générer le PDF. Réessaie dans un instant."),
      ),
    );
  }
}
