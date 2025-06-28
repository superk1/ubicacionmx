// lib/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ubicacionmx_nueva/screens/map_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      // Usamos pushReplacement para que el usuario no pueda volver a la splash screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MapScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(
              image: const AssetImage('assets/logo.png'),
               width: 150,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.map,
                    size: 100,
                    color: Colors.grey,
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                "UbicacionMX",
                style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
               ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
