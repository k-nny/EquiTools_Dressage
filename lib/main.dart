import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ecran.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Appli pensée pour le téléphone (portrait) en vue d'une publication sur
  // le Play Store / App Store : on verrouille l'orientation.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EquiTools - Dressage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const Ecran(),
    );
  }
}
