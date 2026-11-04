import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:reprise_dressage_app/lettres.dart';
import 'package:reprise_dressage_app/reprise.dart';
import 'package:reprise_dressage_app/reprise_etape.dart';

/// Génère le protocole de la reprise sous forme de PDF : un tableau
/// « Repère → Mouvement », construit automatiquement à partir des étapes de
/// la reprise (voir [etapesDeLaReprise]). Le mouvement affiché est
/// toujours le nom donné par l'utilisateur, pas le nom technique de la
/// figure.
Future<Uint8List> genererProtocolePdf(
  List<Mouvement> mouvements, {
  String titre = 'Protocole de la reprise',
}) async {
  // Police embarquée : les polices PDF standard n'ont pas la flèche « → ».
  final normale = pw.Font.ttf(
    await rootBundle.load('assets/fonts/DejaVuSans.ttf'),
  );
  final grasse = pw.Font.ttf(
    await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf'),
  );

  final etapes = etapesDeLaReprise(mouvements);
  final maintenant = DateTime.now();
  String deux(int n) => n.toString().padLeft(2, '0');
  final date =
      '${deux(maintenant.day)}/${deux(maintenant.month)}/${maintenant.year}';

  final doc = pw.Document(
    title: titre,
    author: 'EquiTools - Dressage',
    theme: pw.ThemeData.withFont(base: normale, bold: grasse),
  );

  pw.Widget cellule(
    String texte, {
    bool entete = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        texte,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: entete ? 11 : 12,
          fontWeight: entete ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Page ${context.pageNumber} / ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ),
      build: (context) => [
        pw.Text(
          titre,
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Carrière ${Lettres.taille.label} · ${etapes.length} mouvement(s) '
          '· $date',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 14),
        if (etapes.isEmpty)
          pw.Text('La reprise est vide.')
        else
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
            columnWidths: const {
              0: pw.FixedColumnWidth(56),
              1: pw.FixedColumnWidth(26),
              2: pw.FlexColumnWidth(),
            },
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  cellule('Repère', entete: true),
                  cellule('', entete: true),
                  cellule('Mouvement', entete: true),
                ],
              ),
              for (final e in etapes)
                pw.TableRow(
                  children: [
                    cellule(e.repere, entete: true),
                    cellule('→', align: pw.TextAlign.center),
                    cellule(e.nomPersonnalise),
                  ],
                ),
            ],
          ),
      ],
    ),
  );

  return doc.save();
}

/// Génère le PDF puis le télécharge (web) ou ouvre la feuille de partage
/// (Android/iOS).
Future<void> partagerProtocolePdf(
  BuildContext context,
  List<Mouvement> mouvements,
) async {
  final messager = ScaffoldMessenger.of(context);
  if (mouvements.isEmpty) {
    messager.showSnackBar(
      const SnackBar(content: Text('Ta reprise est vide : rien à exporter.')),
    );
    return;
  }
  try {
    final octets = await genererProtocolePdf(mouvements);
    await Printing.sharePdf(bytes: octets, filename: 'protocole-reprise.pdf');
  } catch (_) {
    messager.showSnackBar(
      const SnackBar(
        content: Text("Impossible de générer le PDF. Réessaie dans un instant."),
      ),
    );
  }
}
