import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ImageClassificationPage extends StatefulWidget {
  const ImageClassificationPage({super.key});

  @override
  State<ImageClassificationPage> createState() => _ImageClassificationPageState();
}

class _ImageClassificationPageState extends State<ImageClassificationPage> {
  dynamic _image; // Peut être File ou XFile selon la plateforme
  List<Map<String, dynamic>>? _outputs;
  bool _loading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkPlatform();
  }

  void _checkPlatform() {
    if (kIsWeb) {
      // Afficher un message que TFLite n'est pas supporté sur Web
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "⚠️ TensorFlow Lite n'est pas supporté sur Web. "
                "Veuillez tester sur Android ou iOS.",
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      setState(() {
        _loading = true;
        _image = kIsWeb ? image : File(image.path);
        _outputs = null;
      });

      // Simuler l'analyse pour démo Web
      if (kIsWeb) {
        await _simulateClassification();
      } else {
        // Sur mobile, vous utiliseriez TFLite ici
        await _simulateClassification();
      }
    } catch (e) {
      print("❌ Erreur image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e")),
        );
        setState(() => _loading = false);
      }
    }
  }

  // Simulation pour démonstration (à remplacer par vraie classification)
  Future<void> _simulateClassification() async {
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _outputs = [
        {'label': 'apple', 'confidence': 0.85},
        {'label': 'banana', 'confidence': 0.10},
        {'label': 'orange', 'confidence': 0.05},
      ];
      _loading = false;
    });
  }

  Widget _buildImageWidget() {
    if (_image == null) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_search, size: 60, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "Aucune image sélectionnée",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      );
    }

    if (kIsWeb) {
      // Sur Web, utiliser Image.network avec le path de XFile
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          (_image as XFile).path,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Text("Erreur de chargement"),
            );
          },
        ),
      );
    } else {
      // Sur mobile, utiliser Image.file
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(_image as File, fit: BoxFit.cover),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reconnaissance de Fruits'),
        backgroundColor: Colors.green,
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Analyse en cours..."),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Bannière d'avertissement pour Web
                  if (kIsWeb)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Mode démo : TFLite ne fonctionne pas sur Web.\n"
                              "Testez sur Android/iOS pour la vraie classification.",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                    child: _buildImageWidget(),
                  ),
                  const SizedBox(height: 20),

                  if (_outputs != null && _outputs!.isNotEmpty)
                    Card(
                      elevation: 4,
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "🍎 Résultats :",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ..._outputs!.map((res) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${res['label']}".toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "${(res['confidence'] * 100).toStringAsFixed(1)}%",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text("Galerie"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      if (!kIsWeb) // Caméra non supportée sur Web
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text("Caméra"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}