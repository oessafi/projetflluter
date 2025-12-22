import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ImageClassificationPage extends StatefulWidget {
  const ImageClassificationPage({super.key});

  @override
  State<ImageClassificationPage> createState() => _ImageClassificationPageState();
}

class _ImageClassificationPageState extends State<ImageClassificationPage> {
  XFile? _pickedFile;
  Map<String, dynamic>? _result;
  bool _loading = false;
  Interpreter? _interpreter;
  List<String>? _labels;
  
  // Choix du modèle - ADAPTEZ VOS NOMS ICI
  String _currentModel = 'CNN_best_quantized.tflite'; 
  // OU si vous renommez: 'smartfruit_cnn.tflite'

  // ============================================================================
  // CONFIGURATION DE VOS MODÈLES
  // ============================================================================
  
  // IMPORTANT: Vos modèles utilisent des images 100x100 (pas 224 ou 128!)
  static const int INPUT_SIZE = 100; // Taille définie dans votre code Python
  
  // Liste des classes de fruits (même ordre que dans votre code Python)
  static const List<String> FRUIT_CLASSES = [
    'apple',
    'avocado', 
    'banana',
    'cherry',
    'kiwi',
    'mango',
    'orange',
    'pineapple',
    'stawberries',
    'watermelon'
  ];

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  // ============================================================================
  // CHARGEMENT DU MODÈLE
  // ============================================================================
  
  Future<void> _loadModel() async {
    try {
      setState(() => _loading = true);
      
      // Charger le modèle TFLite
      _interpreter = await Interpreter.fromAsset('assets/$_currentModel');
      
      // Charger les labels depuis labels.txt
      try {
        final labelData = await DefaultAssetBundle.of(context)
            .loadString('assets/labels.txt');
        _labels = labelData.split('\n')
            .where((s) => s.trim().isNotEmpty)
            .map((s) => s.trim())
            .toList();
        
        debugPrint("✅ Labels chargés: ${_labels!.length} classes");
      } catch (e) {
        // Si labels.txt n'existe pas, utiliser les classes par défaut
        _labels = FRUIT_CLASSES;
        debugPrint("⚠️ labels.txt non trouvé, utilisation des labels par défaut");
      }
      
      // Vérifier les dimensions du modèle
      var inputShape = _interpreter!.getInputTensor(0).shape;
      var outputShape = _interpreter!.getOutputTensor(0).shape;
      
      debugPrint("✅ Modèle $_currentModel chargé");
      debugPrint("📊 Input shape: $inputShape");
      debugPrint("📊 Output shape: $outputShape");
      debugPrint("🍎 Classes: ${_labels!.join(', ')}");
      
      setState(() => _loading = false);
      
    } catch (e) {
      debugPrint("❌ Erreur chargement modèle: $e");
      setState(() => _loading = false);
      
      // Afficher un message d'erreur à l'utilisateur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: Impossible de charger le modèle'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================================
  // INFÉRENCE - CLASSIFICATION DE L'IMAGE
  // ============================================================================
  
  Future<void> _runInference(XFile imageFile) async {
    if (_interpreter == null || _labels == null) {
      debugPrint("❌ Modèle ou labels non chargés");
      return;
    }

    try {
      setState(() => _loading = true);
      
      // 1. Charger l'image
      final imageData = await File(imageFile.path).readAsBytes();
      img.Image? originalImage = img.decodeImage(imageData);
      
      if (originalImage == null) {
        throw Exception("Impossible de décoder l'image");
      }
      
      // 2. Redimensionner à 100x100 (comme dans votre code Python)
      img.Image resizedImage = img.copyResize(
        originalImage, 
        width: INPUT_SIZE, 
        height: INPUT_SIZE
      );

      // 3. Préparation de l'entrée
      // Format: [1, 100, 100, 3] avec normalisation 0-1
      var input = List.generate(
        1, 
        (batch) => List.generate(
          INPUT_SIZE, 
          (y) => List.generate(
            INPUT_SIZE, 
            (x) {
              final pixel = resizedImage.getPixel(x, y);
              return [
                pixel.r / 255.0,  // Canal Rouge
                pixel.g / 255.0,  // Canal Vert
                pixel.b / 255.0   // Canal Bleu
              ];
            }
          )
        )
      );

      // 4. Préparer le buffer de sortie
      // Format: [1, 10] pour 10 classes
      var output = List.filled(1, List<double>.filled(_labels!.length, 0.0))
          .map((e) => List<double>.filled(_labels!.length, 0.0))
          .toList();

      // 5. Exécuter l'inférence
      _interpreter!.run(input, output);

      // 6. Trouver la classe avec la plus haute probabilité
      int maxIdx = 0;
      double maxProb = output[0][0];
      
      for (int i = 1; i < output[0].length; i++) {
        if (output[0][i] > maxProb) {
          maxProb = output[0][i];
          maxIdx = i;
        }
      }

      // 7. Obtenir le Top 3
      List<Map<String, dynamic>> top3 = [];
      List<int> indices = List.generate(output[0].length, (i) => i);
      indices.sort((a, b) => output[0][b].compareTo(output[0][a]));
      
      for (int i = 0; i < 3 && i < indices.length; i++) {
        top3.add({
          'label': _labels![indices[i]],
          'confidence': output[0][indices[i]],
          'index': indices[i]
        });
      }

      // 8. Mettre à jour l'interface
      setState(() {
        _result = {
          'label': _labels![maxIdx],
          'confidence': maxProb,
          'index': maxIdx,
          'top3': top3,
          'allProbabilities': output[0]
        };
        _loading = false;
      });
      
      debugPrint("✅ Prédiction: ${_labels![maxIdx]} (${(maxProb * 100).toStringAsFixed(2)}%)");

    } catch (e) {
      debugPrint("❌ Erreur Inférence: $e");
      setState(() => _loading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la classification'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================================
  // INTERFACE UTILISATEUR
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🍎 Classification de Fruits'),
        backgroundColor: Colors.green[700],
        actions: [
          // Sélection du modèle (CNN vs ANN)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: DropdownButton<String>(
              value: _currentModel,
              dropdownColor: Colors.green[700],
              style: const TextStyle(color: Colors.white, fontSize: 14),
              underline: Container(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items: const [
                DropdownMenuItem(
                  value: 'CNN_best_quantized.tflite', 
                  child: Text("🔷 CNN")
                ),
                DropdownMenuItem(
                  value: 'ANN_best_quantized.tflite', 
                  child: Text("🔶 ANN")
                ),
                // OU si vous renommez vos fichiers:
                // DropdownMenuItem(
                //   value: 'smartfruit_cnn.tflite', 
                //   child: Text("🔷 CNN")
                // ),
                // DropdownMenuItem(
                //   value: 'smartfruit_ann.tflite', 
                //   child: Text("🔶 ANN")
                // ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _currentModel = val;
                    _result = null;
                    _pickedFile = null;
                  });
                  _loadModel();
                }
              },
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Badge du modèle actuel
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _currentModel.contains('CNN') || _currentModel.contains('cnn')
                    ? Colors.blue[100]
                    : Colors.orange[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _currentModel.contains('CNN') || _currentModel.contains('cnn')
                    ? '🔷 Modèle CNN Actif'
                    : '🔶 Modèle ANN Actif',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _currentModel.contains('CNN') || _currentModel.contains('cnn')
                      ? Colors.blue[900]
                      : Colors.orange[900],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Affichage de l'image
            Center(
              child: Container(
                height: 300,
                width: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: _pickedFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.image, size: 100, color: Colors.grey),
                          SizedBox(height: 10),
                          Text(
                            'Aucune image sélectionnée',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(_pickedFile!.path),
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Indicateur de chargement
            if (_loading)
              Column(
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Classification en cours...'),
                ],
              ),
            
            // Résultats
            if (_result != null && !_loading) ...[
              // Résultat principal
              Card(
                color: Colors.green[50],
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        '🎯 Résultat de la Classification',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.emoji_food_beverage, 
                                          size: 40, 
                                          color: Colors.green),
                        title: Text(
                          '${_result!['label']}'.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Confiance: ${(_result!['confidence'] * 100).toStringAsFixed(2)}%',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      // Barre de progression
                      LinearProgressIndicator(
                        value: _result!['confidence'],
                        backgroundColor: Colors.grey[300],
                        color: _result!['confidence'] > 0.7 
                            ? Colors.green 
                            : Colors.orange,
                        minHeight: 10,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _result!['confidence'] > 0.7
                            ? '✅ Prédiction fiable'
                            : '⚠️ Prédiction incertaine',
                        style: TextStyle(
                          color: _result!['confidence'] > 0.7
                              ? Colors.green[700]
                              : Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Top 3 prédictions
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📊 Top 3 Prédictions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      ...List.generate(_result!['top3'].length, (index) {
                        final prediction = _result!['top3'][index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: index == 0 
                                      ? Colors.green 
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prediction['label'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    LinearProgressIndicator(
                                      value: prediction['confidence'],
                                      backgroundColor: Colors.grey[300],
                                      color: Colors.blue,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${(prediction['confidence'] * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            
            // Boutons d'action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galerie'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Caméra'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // SÉLECTION D'IMAGE
  // ============================================================================
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image == null) return;
      
      setState(() => _pickedFile = image);
      _runInference(image);
      
    } catch (e) {
      debugPrint("❌ Erreur sélection image: $e");
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de l\'image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }
}