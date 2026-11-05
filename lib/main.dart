import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'compte/achats/achats.dart';
import 'compte/service_compte.dart';
import 'compte/service_premium.dart';
import 'ecran.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Appli pensée pour le téléphone (portrait) en vue d'une publication sur
  // le Play Store / App Store : on verrouille l'orientation.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Comptes (Firebase) : sans configuration, ils restent désactivés et
  // l'appli fonctionne comme avant.
  await ServiceCompte.instance.init();
  await AchatsIntegres.init();
  ServicePremium.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EquiTools - Dressage',
      debugShowCheckedModeBanner: false,
      theme: construireTheme(),
      home: const Ecran(),
    );
  }
}
