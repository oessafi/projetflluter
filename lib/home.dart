import 'package:flutter/material.dart';
import 'im.dart'; // Importe le menu drawer

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accueil')),
      drawer: const Mymenu(), // Le menu latéral
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home, size: 80, color: Colors.deepPurple),
            SizedBox(height: 20),
            Text(
              'Bienvenue sur Chouchou !',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Ouvrez le menu en haut à gauche pour naviguer.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}