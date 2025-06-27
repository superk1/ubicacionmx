// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ubicacionmx_nueva/screens/splash_screen.dart';

Future<void> main() async {
  // Asegura que Flutter esté inicializado antes de usar plugins.
  WidgetsFlutterBinding.ensureInitialized();
  
  // Carga las variables de entorno (.env) que contienen la API Key
  await dotenv.load(fileName: ".env");
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UbicacionMX',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
