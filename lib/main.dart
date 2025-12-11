// lib/main.dart
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import 'signin.dart'; // doit contenir class SignInPage
import 'signup.dart'; // doit contenir class SignUpPage
import 'im.dart';     // contient class Mymenu
import 'splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyBTQCNcOGMPZ0tlL8cPed2XMO2gfMs2J2o",
        authDomain: "YOUR_AUTH_DOMAIN",
        projectId: "YOUR_PROJECT_ID",
        storageBucket: "YOUR_STORAGE_BUCKET",
        messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
        appId: "YOUR_APP_ID",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Colors.deepPurple;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Auth',
      themeMode: ThemeMode.system, // respecte le thème système (clair/sombre)

      // Thème clair
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
      ),

      // Thème sombre
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
      ),

      // On commence par la page de connexion
      initialRoute: FirebaseAuth.instance.currentUser == null ? '/signin' : '/home',

      // Déclaration des routes
      routes: {
        '/signin': (_) => const SignInPage(),
        '/signup': (_) => const SignUpPage(),

        // Page principale avec Drawer après connexion
        '/home': (_) => const HomePage(),

        // Pages appelées depuis le menu
        '/stock': (_) => const StockPage(),
        '/vocal': (_) => const VocalPage(),
        '/image': (_) => const ImageClassificationPage(),
      },

      // Route inconnue → retour à SignIn
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => const SignInPage(),
      ),
    );
  }
}

/// 🏠 Page principale après connexion, avec ton Drawer
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
      ),
      drawer: const Mymenu(), // 👉 ton menu latéral (défini dans im.dart)
      body: const Center(
        child: Text('Bienvenue dans l\'application'),
      ),
    );
  }
}

/// 📈 Page Stock (placeholder, tu peux la modifier après)
class StockPage extends StatelessWidget {
  const StockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock price prediction')),
      body: const Center(
        child: Text('Page Stock'),
      ),
    );
  }
}

/// 🎙️ Assistant Vocal connecté à un chatbot (Gemini)
class VocalPage extends StatefulWidget {
  const VocalPage({super.key});

  @override
  State<VocalPage> createState() => _VocalPageState();
}

class _VocalPageState extends State<VocalPage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = "Appuie sur le micro et parle...";
  String _assistantReply = "";

  // ⚠️ Mets ta vraie clé ici (et ne la partage jamais)
  static const String _apiKey = 'AIzaSyBTQCNcOGMPZ0tlL8cPed2XMO2gfMs2J2o';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) => print("Status: $status"),
        onError: (error) => print("Error: $error"),
      );

      if (available) {
        setState(() => _isListening = true);

        _speech.listen(
          localeId: 'fr_FR', // tu peux changer
          onResult: (result) async {
            final text = result.recognizedWords;

            setState(() {
              _recognizedText = text;
              _assistantReply = "Je réfléchis...";
            });

            final reply = await _askChatbot(text);

            setState(() {
              _assistantReply = reply;
            });
          },
        );
      } else {
        setState(() {
          _recognizedText = "Le micro n'est pas disponible.";
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  /// 🔥 Appel au chatbot (exemple avec Google Gemini API REST)
  Future<String> _askChatbot(String userMessage) async {
    if (userMessage.trim().isEmpty) {
      return "Je n'ai rien entendu 😅";
    }

    try {
      final uri = Uri.parse(
  'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$_apiKey',
);


      final body = {
        "contents": [
          {
            "parts": [
              {
                "text":
                    "Tu es un assistant vocal sympa, réponds en français de manière courte. L'utilisateur a dit : $userMessage"
              }
            ]
          }
        ]
      };

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (text is String && text.isNotEmpty) {
          return text;
        } else {
          return "Je n'ai pas compris la réponse du modèle.";
        }
      } else {
        print("Error status: ${response.statusCode}");
        print("Body: ${response.body}");
        return "Erreur de l'API (${response.statusCode}).";
      }
    } catch (e) {
      print("Exception: $e");
      return "Une erreur s'est produite : $e";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant Vocal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Texte reconnu
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _recognizedText,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Réponse de l'assistant (chatbot)
            if (_assistantReply.isNotEmpty)
              Card(
                color: Colors.deepPurple.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.smart_toy, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _assistantReply,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const Spacer(),

            // Bouton micro
            Align(
              alignment: Alignment.center,
              child: FloatingActionButton(
                onPressed: _toggleListening,
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _isListening ? "J'écoute..." : "Appuie pour parler",
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🖼️ Page Classification d'image (placeholder)
class ImageClassificationPage extends StatelessWidget {
  const ImageClassificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Classification d\'image')),
      body: const Center(
        child: Text('Page Classification d\'image'),
      ),
    );
  }
}
