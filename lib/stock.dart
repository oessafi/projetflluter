import 'package:flutter/material.dart';

class StockPage extends StatelessWidget {
  const StockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bourse (Stock)')),
      body: const Center(
        child: Text('Page de prédiction boursière (À implémenter)'),
      ),
    );
  }
}